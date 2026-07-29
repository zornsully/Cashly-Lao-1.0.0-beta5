import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl with RepositoryGuard implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<UserEntity?> authStateChanges() {
    return _remoteDataSource.authStateChanges().map(
      (user) => user == null ? null : UserModel.fromFirebaseUser(user),
    );
  }

  @override
  UserEntity? get currentUser {
    final user = _remoteDataSource.currentUser;
    return user == null ? null : UserModel.fromFirebaseUser(user);
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) {
    return guard(
      () => _remoteDataSource.login(email: email, password: password),
    );
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    return guard(
      () => _remoteDataSource.register(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() {
    return guard(_remoteDataSource.signInWithGoogle);
  }

  @override
  Future<Either<Failure, Unit>> logout() {
    return guardUnit(_remoteDataSource.logout);
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) {
    return guardUnit(() => _remoteDataSource.sendPasswordResetEmail(email));
  }

  @override
  Future<Either<Failure, Unit>> sendEmailVerification() {
    return guardUnit(_remoteDataSource.sendEmailVerification);
  }

  @override
  Future<Either<Failure, UserEntity>> reloadUser() {
    return guard(_remoteDataSource.reloadUser);
  }

  @override
  Future<Either<Failure, Unit>> updateDisplayName(String displayName) {
    return guardUnit(() => _remoteDataSource.updateDisplayName(displayName));
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount({String? password}) {
    return guardUnit(() => _remoteDataSource.deleteAccount(password: password));
  }
}
