import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_language.dart';
import '../../../../core/constants/app_theme_mode.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/user_preferences_entity.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../datasources/user_preferences_remote_datasource.dart';

class UserPreferencesRepositoryImpl
    with RepositoryGuard
    implements UserPreferencesRepository {
  const UserPreferencesRepositoryImpl(this._remoteDataSource);

  final UserPreferencesRemoteDataSource _remoteDataSource;

  @override
  Stream<UserPreferencesEntity> watchPreferences() {
    return _remoteDataSource.watchPreferences();
  }

  @override
  Future<Either<Failure, Unit>> updateThemeMode(AppThemeModePreference mode) {
    return guardUnit(() => _remoteDataSource.updateThemeMode(mode));
  }

  @override
  Future<Either<Failure, Unit>> updateDefaultCurrency(String currencyCode) {
    return guardUnit(
      () => _remoteDataSource.updateDefaultCurrency(currencyCode),
    );
  }

  @override
  Future<Either<Failure, Unit>> updateLanguage(AppLanguage language) {
    return guardUnit(() => _remoteDataSource.updateLanguage(language));
  }

  @override
  Future<Either<Failure, Unit>> updateAppLockEnabled(bool enabled) {
    return guardUnit(() => _remoteDataSource.updateAppLockEnabled(enabled));
  }

  @override
  Future<Either<Failure, Unit>> updateNotificationsEnabled(bool enabled) {
    return guardUnit(
      () => _remoteDataSource.updateNotificationsEnabled(enabled),
    );
  }
}
