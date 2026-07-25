import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';

abstract interface class FcmTokenRemoteDataSource {
  /// Idempotent — safe to call repeatedly with the same token (e.g. on
  /// every app launch while notifications are enabled, or from
  /// `onTokenRefresh`).
  Future<void> registerToken({required String token, required String platform});

  Future<void> unregisterToken(String token);
}

class FirestoreFcmTokenRemoteDataSource implements FcmTokenRemoteDataSource {
  FirestoreFcmTokenRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  }) : _firestore = firestore, // ignore: prefer_initializing_formals
       _firebaseAuth = firebaseAuth; // ignore: prefer_initializing_formals

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  String get _uid {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw const AuthException('No signed-in user.', code: 'no-current-user');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection(FirestorePaths.users)
      .doc(_uid)
      .collection(FirestorePaths.fcmTokens);

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
  }) async {
    try {
      // Document ID is the token value itself (see firestore.rules). Reads
      // first rather than an unconditional merge `.set()`: the rules pin
      // `createdAt` immutable on update, so a repeat registration must
      // leave it untouched — only a genuinely new token doc stamps it.
      final docRef = _collection.doc(token);
      final existing = await docRef.get();
      if (existing.exists) {
        await docRef.update({
          'platform': platform,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set({
          'token': token,
          'platform': platform,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Could not register this device for notifications.',
      );
    }
  }

  @override
  Future<void> unregisterToken(String token) async {
    try {
      await _collection.doc(token).delete();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not unregister this device.');
    }
  }
}
