import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Talks to Firebase Authentication and Firestore directly. Throws
/// [AuthException]/[ServerException] on failure — never a raw Firebase
/// exception — so [AuthRepositoryImpl] is the only place that needs to know
/// Firebase exists.
abstract interface class AuthRemoteDataSource {
  Stream<fb.User?> authStateChanges();

  fb.User? get currentUser;

  Future<UserModel> login({required String email, required String password});

  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  });

  /// Signs in (or, on first use, registers) with the platform's native
  /// Google account picker, then exchanges the resulting Google credential
  /// for a Firebase session — same session shape as email/password sign-in.
  Future<UserModel> signInWithGoogle();

  Future<void> logout();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();

  Future<UserModel> reloadUser();

  Future<void> updateDisplayName(String displayName);

  /// Permanently deletes the signed-in user's profile, every subcollection
  /// under it, and the Firebase Auth account itself. Firebase requires a
  /// "recent" login for account deletion, so this re-authenticates first:
  /// with [password] for an account that has a password provider, or via a
  /// fresh Google sign-in for a Google-only account (in which case
  /// [password] is ignored and may be omitted).
  Future<void> deleteAccount({String? password});
}

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource({
    required fb.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth, // ignore: prefer_initializing_formals
       _firestore = firestore, // ignore: prefer_initializing_formals
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  // google_sign_in's Android implementation is *supposed* to fall back to
  // reading this from the native `default_web_client_id` string resource
  // (generated from google-services.json's own client_type-3 entry) when
  // `serverClientId` isn't passed explicitly — confirmed on a real device
  // that fallback doesn't happen here, throwing `clientConfigurationError:
  // "serverClientId must be provided on Android"` instead. Passing it
  // explicitly takes precedence over that lookup either way, so this is
  // also just the more reliable path regardless of why the fallback
  // failed. Not a secret — this is the "Web application" OAuth client ID
  // from `android/app/google-services.json` (`client_type: 3`), the same
  // kind of public identifier as iOS's `REVERSED_CLIENT_ID`.
  static const _googleServerClientId =
      '406428434702-hmq4kb427bsvhcehc4452mr4oct42il3.apps.googleusercontent.com';

  // `GoogleSignIn.initialize()` must be awaited exactly once before any
  // other call on the instance — memoized so every caller can safely await
  // this regardless of who gets there first, without initializing twice.
  Future<void>? _googleSignInInit;
  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInit ??= _googleSignIn.initialize(
      serverClientId: _googleServerClientId,
    );
  }

  @override
  // `userChanges()` (not `authStateChanges()`) is required here: it's the
  // only stream that also emits after `reload()`/`updateDisplayName()`, so
  // the email-verification and display-name-edit screens update reactively
  // instead of needing a manual sign-out/in to pick up the change.
  Stream<fb.User?> authStateChanges() => _firebaseAuth.userChanges();

  @override
  fb.User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Sign-in did not return a user.');
      }
      final model = UserModel.fromFirebaseUser(user);

      // Repairs the case where `users/{uid}` was never seeded (e.g. a
      // dropped write during a past registration) — without this, every
      // Settings/profile write stays rejected forever, since Firestore
      // rules correctly treat a partial merge against a non-existent doc
      // as a `create` missing required fields. See the same repair in
      // `signInWithGoogle` below.
      await _repairProfileDocIfMissing(model);

      return model;
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Registration did not return a user.');
      }

      await user.updateDisplayName(displayName);
      await user.sendEmailVerification();
      await user.reload();

      final refreshedUser = _firebaseAuth.currentUser ?? user;
      final model = UserModel.fromFirebaseUser(refreshedUser);

      // Best-effort: the auth account already exists and the user is
      // signed in, which is what "registration succeeded" means to the
      // caller. A dropped profile-doc write shouldn't surface as a
      // registration failure — `updateDisplayName` recreates this doc
      // (via merge) the next time the user edits their profile.
      try {
        await _firestore
            .collection(FirestorePaths.users)
            .doc(model.uid)
            .set(model.toFirestoreSeed());
      } on FirebaseException {
        // Swallowed intentionally — see comment above.
      }

      return model;
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    if (kIsWeb) return _signInWithGooglePopup();
    if (!_googleSignIn.supportsAuthenticate()) {
      throw const AuthException(
        'Google Sign-In is not supported on this platform.',
        code: 'google-sign-in-unsupported',
      );
    }
    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException(
          'Sign-in was cancelled.',
          code: 'google-sign-in-cancelled',
        );
      }
      // Never surface `e.description` directly — it's a raw platform
      // string (e.g. "serverClientId must be provided on Android"),
      // meaningful to a developer but not a user.
      throw const AuthException(
        'Google sign-in failed. Please try again.',
        code: 'google-sign-in-failed',
      );
    }

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw const AuthException(
        'Google did not return an ID token.',
        code: 'google-sign-in-failed',
      );
    }
    // The access token is optional for Firebase (the ID token alone is
    // enough to identify the user) but including it when available avoids
    // a separate authorization round-trip.
    final authorization = await googleUser.authorizationClient
        .authorizationForScopes(const ['email']);

    try {
      final credential = fb.GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('Sign-in did not return a user.');
      }
      final model = UserModel.fromFirebaseUser(user);

      // Seeds the profile doc on a first-ever Google sign-in, or repairs
      // it if missing — see `_repairProfileDocIfMissing`. Deliberately
      // *not* an unconditional merge write: that would re-set `createdAt`
      // to "now" on every single returning sign-in, since a merge write
      // still overwrites the fields it specifies.
      await _repairProfileDocIfMissing(model);

      return model;
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<UserModel> _signInWithGooglePopup() async {
    try {
      final userCredential = await _firebaseAuth.signInWithPopup(
        fb.GoogleAuthProvider(),
      );
      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('Sign-in did not return a user.');
      }
      final model = UserModel.fromFirebaseUser(user);
      await _repairProfileDocIfMissing(model);
      return model;
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } on FirebaseException catch (e) {
      throw _mapGooglePopupFirebaseException(e);
    }
  }

  @override
  Future<void> logout() => _firebaseAuth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user.', code: 'no-current-user');
    }
    try {
      await user.sendEmailVerification();
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<UserModel> reloadUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user.', code: 'no-current-user');
    }
    try {
      await user.reload();
      final refreshed = _firebaseAuth.currentUser ?? user;
      return UserModel.fromFirebaseUser(refreshed);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user.', code: 'no-current-user');
    }
    try {
      await user.updateDisplayName(displayName);
      await user.reload();
      await _firestore.collection(FirestorePaths.users).doc(user.uid).set({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not update your profile.');
    }
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user.', code: 'no-current-user');
    }
    final hasPasswordProvider = user.providerData.any(
      (info) =>
          info.providerId == fb.EmailAuthProvider.EMAIL_PASSWORD_SIGN_IN_METHOD,
    );

    try {
      if (hasPasswordProvider) {
        final email = user.email;
        if (email == null || password == null) {
          throw const AuthException(
            'This account has no email on file.',
            code: 'no-current-user',
          );
        }
        await user.reauthenticateWithCredential(
          fb.EmailAuthProvider.credential(email: email, password: password),
        );
      } else {
        if (kIsWeb) {
          await user.reauthenticateWithPopup(fb.GoogleAuthProvider());
        } else {
          // Google-only account: no password to check, so re-prove identity
          // with a fresh interactive Google sign-in instead.
          await _ensureGoogleSignInInitialized();
          final GoogleSignInAccount googleUser;
          try {
            googleUser = await _googleSignIn.authenticate();
          } on GoogleSignInException catch (e) {
            throw AuthException(
              e.code == GoogleSignInExceptionCode.canceled
                  ? 'Sign-in was cancelled.'
                  : 'Google sign-in failed. Please try again.',
              code: e.code == GoogleSignInExceptionCode.canceled
                  ? 'google-sign-in-cancelled'
                  : 'google-sign-in-failed',
            );
          }
          final idToken = googleUser.authentication.idToken;
          if (idToken == null) {
            throw const AuthException(
              'Google did not return an ID token.',
              code: 'google-sign-in-failed',
            );
          }
          final authorization = await googleUser.authorizationClient
              .authorizationForScopes(const ['email']);
          await user.reauthenticateWithCredential(
            fb.GoogleAuthProvider.credential(
              idToken: idToken,
              accessToken: authorization?.accessToken,
            ),
          );
        }
      }

      final userDoc = _firestore.collection(FirestorePaths.users).doc(user.uid);

      // Deleted first, and as its own commit — separate from the
      // subcollection deletes below — because Firestore security rules
      // evaluate `exists()` against the database state as of just before
      // the current write, not against other writes in the same batch.
      // Only once this commit has landed does the categories rule's
      // "default categories become deletable once the profile doc is
      // gone" exception take effect for the next step.
      await userDoc.delete();

      for (final collectionName in const [
        FirestorePaths.accounts,
        FirestorePaths.categories,
        FirestorePaths.transactions,
        FirestorePaths.budgets,
        FirestorePaths.fcmTokens,
      ]) {
        await _deleteAllInChunks(userDoc.collection(collectionName));
      }

      // Deleted last: if any step above fails, the user is still signed
      // in and can simply retry — every step here is a no-op when re-run
      // against documents that are already gone.
      await user.delete();
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not delete your account.');
    }
  }

  /// Seeds `users/{uid}` only if it doesn't already exist — called after
  /// every successful sign-in (not just registration) so a dropped write
  /// from a past registration can self-heal the next time that user signs
  /// in, instead of being stuck forever (every other write to this doc is
  /// a partial `merge`, which Firestore rules correctly reject as an
  /// invalid `create` once the doc is truly missing). Checking existence
  /// first — rather than an unconditional merge write — also means an
  /// existing doc's `createdAt` is never re-stamped to "now" on a routine
  /// login.
  Future<void> _repairProfileDocIfMissing(UserModel model) async {
    final docRef = _firestore.collection(FirestorePaths.users).doc(model.uid);
    try {
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        await docRef.set(model.toFirestoreSeed());
      }
    } on FirebaseException {
      // Best-effort, same as the seed write in register() — a dropped
      // write here just means the same repair is attempted again next
      // sign-in.
    }
  }

  /// Firestore batches top out at 500 operations; 450 leaves headroom.
  Future<void> _deleteAllInChunks(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    const chunkSize = 450;
    final snapshot = await collection.get();
    for (var i = 0; i < snapshot.docs.length; i += chunkSize) {
      final batch = _firestore.batch();
      for (final doc in snapshot.docs.skip(i).take(chunkSize)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  AuthException _mapAuthException(fb.FirebaseAuthException e) {
    final message = switch (e.code) {
      'invalid-email' => 'That email address looks invalid.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'invalid-credential' => 'Incorrect email or password.',
      'email-already-in-use' => 'An account already exists with this email.',
      'weak-password' => 'Please choose a stronger password.',
      'operation-not-allowed' => 'This sign-in method is not enabled yet.',
      'invalid-api-key' || 'api-key-not-valid' =>
        'The app sign-in configuration needs an update. Please try again shortly.',
      'unauthorized-domain' =>
        'This website is not authorized for Google Sign-In yet.',
      'popup-blocked' =>
        'Your browser blocked the Google sign-in window. Allow pop-ups for Cashly Lao and try again.',
      'popup-closed-by-user' => 'Google sign-in was closed before it finished.',
      'cancelled-popup-request' =>
        'Another Google sign-in window is already open. Please finish or close it first.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' => 'No internet connection. Please try again.',
      'requires-recent-login' =>
        'Please sign in again to complete this action.',
      _ => 'Authentication failed. Please try again.',
    };
    return AuthException(message, code: e.code);
  }

  AuthException _mapGooglePopupFirebaseException(FirebaseException e) {
    final message = switch (e.code) {
      'invalid-api-key' || 'api-key-not-valid' || 'app-registration-failed' =>
        'The app sign-in configuration needs an update. Please try again shortly.',
      'web-storage-unsupported' =>
        'Your browser is blocking the storage needed for sign-in. Allow site data for Cashly Lao and try again.',
      'operation-not-supported-in-this-environment' =>
        'Google sign-in is not supported in this browser. Please use a standard browser and try again.',
      _ => 'Google sign-in could not start. Please try again.',
    };
    return AuthException(message, code: e.code);
  }
}
