import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/user_entity.dart';

/// Maps between Firebase's `User` type and Cashly's [UserEntity]. This is
/// the only place in the codebase that should import `firebase_auth`'s
/// `User` type outside of the datasource itself.
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.emailVerified,
    required super.createdAt,
    super.displayName,
    super.photoUrl,
    super.providerIds,
  });

  factory UserModel.fromFirebaseUser(fb.User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      displayName: user.displayName,
      photoUrl: user.photoURL,
      providerIds: [for (final info in user.providerData) info.providerId],
    );
  }

  /// Seed document written to `users/{uid}` the moment an account is
  /// created, so later features (settings, premium, cloud sync) have a
  /// profile record to attach fields to.
  Map<String, Object?> toFirestoreSeed() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
