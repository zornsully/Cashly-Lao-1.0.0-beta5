import 'dart:async';

// ignore_for_file: prefer_initializing_formals
// Every constructor parameter here maps 1:1 to a same-named private field,
// so `this.field` initializing-formal syntax would work for the names that
// happen to be short — but `dart format` is free to wrap a long assignment
// (`_waitForPendingWrites = waitForPendingWrites`) onto a second line,
// which moves a same-line `// ignore:` comment away from the diagnostic it
// was suppressing. A file-level ignore is the reliable fix rather than
// four fragile per-line ones.
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

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();

  Future<UserModel> reloadUser();

  /// Signs the current user out.
  ///
  /// Firestore's local persistence cache is not scoped per-user — it
  /// survives a sign-out by default, so a second person signing into the
  /// same device/browser profile could otherwise read the previous user's
  /// cached financial documents before their own data ever loads. To
  /// prevent that:
  ///
  /// 1. Waits (bounded — [FirebaseAuthRemoteDataSource._pendingWritesSyncTimeout])
  ///    for any offline writes to finish reaching the server. If they can't
  ///    be confirmed synced in time (e.g. genuinely offline with queued
  ///    writes), this throws [AuthException] with
  ///    `code: 'logout-pending-writes'` and does **not** sign out — an
  ///    unsynchronized write is never discarded.
  /// 2. Signs out of Firebase Auth.
  /// 3. Best-effort clears the local Firestore cache so the next user on
  ///    this device starts from an empty cache. This step never blocks or
  ///    fails the sign-out itself — see the implementation's doc comment
  ///    for the exact Firebase SDK behavior this relies on and why it's
  ///    still marked best-effort.
  Future<void> logout();

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
    // Both overridable purely for testability: `fake_cloud_firestore`
    // (used throughout this codebase's datasource tests) doesn't implement
    // `waitForPendingWrites()`/`terminate()`, since neither has a meaningful
    // fake-in-memory behavior to simulate. Production code always uses the
    // real Firestore instance's own implementations (the `??` defaults
    // below); tests inject a controllable fake instead.
    Future<void> Function()? waitForPendingWrites,
    Future<void> Function()? clearLocalCache,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _waitForPendingWrites = waitForPendingWrites,
       _clearLocalCache = clearLocalCache;

  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final Future<void> Function()? _waitForPendingWrites;
  final Future<void> Function()? _clearLocalCache;

  /// How long [logout] will wait for queued offline writes to reach the
  /// server before refusing to sign out. Bounded so a genuinely offline
  /// device doesn't hang the sign-out button forever — `waitForPendingWrites`
  /// only resolves once every currently-queued write is acknowledged by the
  /// server, so with zero connectivity it would otherwise never complete.
  static const _pendingWritesSyncTimeout = Duration(seconds: 8);

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
    debugPrint('[AUTH-03] before signInWithEmailAndPassword');
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      debugPrint(
        '[AUTH-04] signInWithEmailAndPassword returned, uid=${user?.uid}',
      );
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
      debugPrint('[AUTH-05] before Firestore profile repair');
      await _repairProfileDocIfMissing(model);
      debugPrint('[AUTH-06] profile repair complete, returning success');

      return model;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint(
        '[AUTH-04] signInWithEmailAndPassword threw FirebaseAuthException '
        'code=${e.code}',
      );
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

  /// Web sign-in uses Firebase's popup flow so a completed credential is
  /// returned to the auth controller. A bounded wait prevents an embedded
  /// browser or blocked popup from leaving Login permanently disabled.
  Future<UserModel> _signInWithGooglePopup() async {
    debugPrint('[AUTH-03] before signInWithPopup');
    try {
      final userCredential = await _firebaseAuth
          .signInWithPopup(fb.GoogleAuthProvider())
          .timeout(const Duration(seconds: 60));
      final user = userCredential.user;
      debugPrint('[AUTH-04] signInWithPopup returned, uid=${user?.uid}');
      if (user == null) {
        throw const AuthException('Google sign-in did not return a user.');
      }
      final model = UserModel.fromFirebaseUser(user);
      debugPrint('[AUTH-05] before Firestore profile repair');
      await _repairProfileDocIfMissing(model);
      debugPrint('[AUTH-06] profile repair complete, returning success');
      return model;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint(
        '[AUTH-04] signInWithPopup threw FirebaseAuthException '
        'code=${e.code}',
      );
      throw _mapAuthException(e);
    } on TimeoutException {
      // If this fires, signInWithPopup's own JS promise never settled --
      // most commonly because the browser blocked the popup-to-opener
      // communication signInWithPopup relies on to detect completion (see
      // Cross-Origin-Opener-Policy on the hosting response; missing
      // `same-origin-allow-popups` reproduces exactly this: popup opens,
      // account picker works, popup closes, but this Future never resolves
      // or rejects). AuthController.signInWithGoogle's own timeout is
      // intentionally longer than this one so this specific, actionable
      // message reaches the user instead of a generic one.
      debugPrint(
        '[AUTH-04] signInWithPopup did not settle within 60s -- likely a '
        'COOP/popup-communication problem, not a slow network call',
      );
      throw const AuthException(
        'Google sign-in timed out. Allow pop-ups for Cashly Lao and try again.',
        code: 'popup-timeout',
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '[AUTH-04] signInWithPopup threw FirebaseException code=${e.code}',
      );
      throw _mapGooglePopupFirebaseException(e);
    }
  }

  @override
  Future<void> logout() async {
    final waitForWrites =
        _waitForPendingWrites ?? _firestore.waitForPendingWrites;
    try {
      await waitForWrites().timeout(_pendingWritesSyncTimeout);
    } catch (_) {
      // Covers both a real timeout (still offline with queued writes) and
      // any other error from `waitForPendingWrites()` — either way, sync
      // status couldn't be confirmed, so this fails closed rather than
      // risking a discarded offline mutation.
      throw const AuthException(
        "Some changes haven't finished syncing yet. Connect to the "
        'internet and try again before signing out.',
        code: 'logout-pending-writes',
      );
    }

    await _firebaseAuth.signOut();
    await _clearLocalCacheBestEffort();
  }

  /// Clears Firestore's local persistence cache so a second person signing
  /// into this device/browser profile doesn't see the previous user's
  /// cached financial documents before their own data loads — Firestore's
  /// disk cache is not scoped per-user and otherwise survives sign-out.
  ///
  /// Relies on `terminate()` + `clearPersistence()`: per the `cloud_firestore`
  /// plugin's documented behavior, `terminate()` safely detaches every
  /// active listener (they simply stop emitting, they don't throw), and
  /// `FirebaseFirestore.instance` lazily re-creates a fresh, usable instance
  /// the next time anything accesses it — which is what lets the *next*
  /// signed-in user's screens re-subscribe normally. This sequence has not
  /// been exercised on a real device/browser through a full logout →
  /// different-login cycle; verify that before relying on it in production.
  ///
  /// Deliberately best-effort and never rethrows: the user is already
  /// signed out of Firebase Auth by the time this runs, so a failure here
  /// (e.g. a listener that doesn't detach as documented) must not appear
  /// to the user as a failed sign-out.
  Future<void> _clearLocalCacheBestEffort() async {
    final clear = _clearLocalCache ?? _defaultClearLocalCache;
    try {
      await clear();
    } catch (_) {
      // Best-effort — see method doc comment.
    }
  }

  Future<void> _defaultClearLocalCache() async {
    await _firestore.terminate();
    await _firestore.clearPersistence();
  }

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
        FirestorePaths.savingsGoals,
        FirestorePaths.smartMoneyScores,
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

    // Same shared-device reasoning as `logout`'s cache clear: the deleted
    // user's data is already gone server-side, but it can still linger in
    // Firestore's local disk cache for whoever signs in next. No pending-
    // writes wait needed here — every write above this point already
    // completed (or the method would have thrown), so there's nothing left
    // to lose by clearing immediately.
    await _clearLocalCacheBestEffort();
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
      'popup-timeout' =>
        'Google sign-in timed out. Allow pop-ups for Cashly Lao and try again.',
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
