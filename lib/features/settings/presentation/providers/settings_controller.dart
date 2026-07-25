import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_language.dart';
import '../../../../core/constants/app_theme_mode.dart';
import '../../../../core/error/failure.dart';
import 'settings_providers.dart';

/// Drives the loading/error state for preference *mutations*. The
/// preferences themselves come from [userPreferencesProvider], which
/// updates on its own as Firestore changes.
class SettingsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Failure? get failure => switch (state) {
    AsyncError(:final error) when error is Failure => error,
    _ => null,
  };

  Future<bool> updateThemeMode(AppThemeModePreference mode) {
    return _run(() => ref.read(updateThemeModeUseCaseProvider).call(mode));
  }

  Future<bool> updateDefaultCurrency(String currencyCode) {
    return _run(
      () => ref.read(updateDefaultCurrencyUseCaseProvider).call(currencyCode),
    );
  }

  Future<bool> updateLanguage(AppLanguage language) {
    return _run(() => ref.read(updateLanguageUseCaseProvider).call(language));
  }

  Future<bool> updateAppLockEnabled(bool enabled) {
    return _run(
      () => ref.read(updateAppLockEnabledUseCaseProvider).call(enabled),
    );
  }

  Future<bool> updateNotificationsEnabled(bool enabled) {
    return _run(
      () => ref.read(updateNotificationsEnabledUseCaseProvider).call(enabled),
    );
  }

  Future<bool> _run<R>(Future<Either<Failure, R>> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    return result.match(
      (failure) {
        state = AsyncError<void>(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider.autoDispose<SettingsController, void>(
      SettingsController.new,
    );
