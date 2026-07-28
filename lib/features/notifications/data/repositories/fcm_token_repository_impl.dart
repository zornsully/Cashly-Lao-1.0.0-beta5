import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/repositories/fcm_token_repository.dart';
import '../datasources/fcm_token_remote_datasource.dart';

class FcmTokenRepositoryImpl
    with RepositoryGuard
    implements FcmTokenRepository {
  const FcmTokenRepositoryImpl(this._remoteDataSource);

  final FcmTokenRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, Unit>> registerToken({
    required String token,
    required String platform,
  }) {
    return guardUnit(
      () => _remoteDataSource.registerToken(token: token, platform: platform),
    );
  }

  @override
  Future<Either<Failure, Unit>> unregisterToken(String token) {
    return guardUnit(() => _remoteDataSource.unregisterToken(token));
  }
}
