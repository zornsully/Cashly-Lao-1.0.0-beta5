import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';

/// Contract the data layer must fulfil. Usecases and controllers depend on
/// this abstraction only, never on `AuthRepositoryImpl` directly, so the
/// implementation (Firebase today) can be swapped or faked in tests.
abstract interface class AuthRepository {
  /// Emits the current user (or `null` when signed out) every time
  /// Firebase's auth state changes.
  Stream<UserEntity?> authStateChanges();

  /// Synchronous snapshot of the signed-in user, if any. Used by the
  /// router's redirect logic, which cannot await a stream.
  UserEntity? get currentUser;

  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String displayName,
  });

  /// Signs in (or, on first use, registers) via the platform's native
  /// Google account picker.
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  Future<Either<Failure, Unit>> logout();

  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);

  Future<Either<Failure, Unit>> sendEmailVerification();

  /// Refreshes the cached Firebase user (e.g. after the user taps
  /// "I've verified my email") and returns the up-to-date entity.
  Future<Either<Failure, UserEntity>> reloadUser();

  Future<Either<Failure, Unit>> updateDisplayName(String displayName);

  /// Permanently deletes the signed-in user's account and all of their
  /// data. Firebase requires re-authentication first: pass [password] for
  /// an account with a password provider, or omit it for a Google-only
  /// account, which re-authenticates via a fresh Google sign-in instead.
  Future<Either<Failure, Unit>> deleteAccount({String? password});
}
