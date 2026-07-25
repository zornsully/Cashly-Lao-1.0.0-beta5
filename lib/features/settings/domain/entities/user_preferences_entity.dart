import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_language.dart';
import '../../../../core/constants/app_theme_mode.dart';

/// A user's app-wide preferences — appearance, the default currency new
/// Accounts/Budgets are created in, and display language. Stored on the
/// same `users/{uid}` profile document Auth already writes.
class UserPreferencesEntity extends Equatable {
  const UserPreferencesEntity({
    required this.themeMode,
    required this.defaultCurrencyCode,
    required this.language,
    required this.appLockEnabled,
    required this.notificationsEnabled,
  });

  final AppThemeModePreference themeMode;

  /// Pre-selects the currency dropdown when creating a new Account or
  /// Budget. Doesn't change any existing account/budget's own currency.
  final String defaultCurrencyCode;

  final AppLanguage language;

  /// Whether the app requires biometric/device-credential authentication
  /// (via `local_auth`) before showing any authenticated screen — see
  /// `isUnlockedProvider` and `app_router.dart`'s redirect gate.
  final bool appLockEnabled;

  /// Whether budget-exceeded / negative-balance alerts are shown as local
  /// device notifications — see `local_notifications_providers.dart`. Off
  /// by default, same as [appLockEnabled]: both are opt-in device
  /// capabilities the app shouldn't assume without asking.
  final bool notificationsEnabled;

  @override
  List<Object?> get props => [
    themeMode,
    defaultCurrencyCode,
    language,
    appLockEnabled,
    notificationsEnabled,
  ];
}
