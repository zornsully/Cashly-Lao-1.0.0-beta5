import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_language.dart';
import '../../../../core/constants/app_theme_mode.dart';
import '../../domain/entities/user_preferences_entity.dart';

class UserPreferencesModel extends UserPreferencesEntity {
  const UserPreferencesModel({
    required super.themeMode,
    required super.defaultCurrencyCode,
    required super.language,
    required super.appLockEnabled,
    required super.notificationsEnabled,
  });

  /// Builds preferences from the `users/{uid}` document, defaulting every
  /// field a user hasn't set yet (including the document not existing at
  /// all, e.g. the best-effort seed write from registration having been
  /// dropped) to the app's out-of-the-box behavior: system theme, LAK,
  /// English.
  factory UserPreferencesModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final themeModeName = data?['themeMode'] as String?;
    final currencyCode = data?['defaultCurrencyCode'] as String?;
    final languageName = data?['language'] as String?;
    final appLockEnabled = data?['appLockEnabled'] as bool?;
    final notificationsEnabled = data?['notificationsEnabled'] as bool?;

    return UserPreferencesModel(
      themeMode: themeModeName != null
          ? AppThemeModePreference.values.byName(themeModeName)
          : AppThemeModePreference.system,
      defaultCurrencyCode: currencyCode ?? SupportedCurrencies.fallback.code,
      language: languageName != null
          ? AppLanguage.values.byName(languageName)
          : AppLanguage.english,
      appLockEnabled: appLockEnabled ?? false,
      notificationsEnabled: notificationsEnabled ?? false,
    );
  }
}
