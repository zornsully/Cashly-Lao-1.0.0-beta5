import 'package:equatable/equatable.dart';

/// The authenticated user, independent of how it was fetched (Firebase Auth,
/// Firestore, or a test double). Everything above the data layer — usecases,
/// controllers, UI — depends only on this, never on `firebase_auth`'s `User`.
class UserEntity extends Equatable {
  const UserEntity({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.createdAt,
    this.displayName,
    this.photoUrl,
    this.providerIds = const [],
  });

  final String uid;
  final String email;
  final bool emailVerified;
  final DateTime createdAt;
  final String? displayName;
  final String? photoUrl;

  /// Firebase Auth provider IDs linked to this account (e.g. `'password'`,
  /// `'google.com'`). Defaults to empty for callers (mostly tests) that
  /// don't care about provider-specific behavior.
  final List<String> providerIds;

  /// Whether this account can re-authenticate with a password — false for
  /// an account that only ever signed in via Google. Account deletion
  /// (which Firebase requires a "recent login" for) needs to know this to
  /// pick the right re-authentication flow.
  bool get hasPasswordProvider => providerIds.contains('password');

  UserEntity copyWith({
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
  }) {
    return UserEntity(
      uid: uid,
      email: email,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      providerIds: providerIds,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    emailVerified,
    createdAt,
    displayName,
    photoUrl,
    providerIds,
  ];
}
