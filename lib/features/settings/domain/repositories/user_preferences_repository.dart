import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_language.dart';
import '../../../../core/constants/app_theme_mode.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_preferences_entity.dart';

abstract interface class UserPreferencesRepository {
  /// Emits the signed-in user's preferences, updating in real time.
  /// Defaults (system theme, LAK, English) are filled in by the data
  /// layer for a user who has never changed a setting yet.
  Stream<UserPreferencesEntity> watchPreferences();

  Future<Either<Failure, Unit>> updateThemeMode(AppThemeModePreference mode);

  Future<Either<Failure, Unit>> updateDefaultCurrency(String currencyCode);

  Future<Either<Failure, Unit>> updateLanguage(AppLanguage language);

  Future<Either<Failure, Unit>> updateAppLockEnabled(bool enabled);

  Future<Either<Failure, Unit>> updateNotificationsEnabled(bool enabled);
}
