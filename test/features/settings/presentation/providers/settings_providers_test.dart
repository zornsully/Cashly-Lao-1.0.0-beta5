import 'dart:async';

import 'package:cashly_lao/core/constants/app_language.dart';
import 'package:cashly_lao/core/constants/app_theme_mode.dart';
import 'package:cashly_lao/features/auth/domain/entities/user_entity.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_providers.dart';
import 'package:cashly_lao/features/settings/domain/entities/user_preferences_entity.dart';
import 'package:cashly_lao/features/settings/domain/repositories/user_preferences_repository.dart';
import 'package:cashly_lao/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

void main() {
  late _MockUserPreferencesRepository repository;
  late StreamController<UserEntity?> authController;
  late ProviderContainer container;

  const preferences = UserPreferencesEntity(
    themeMode: AppThemeModePreference.system,
    defaultCurrencyCode: 'LAK',
    language: AppLanguage.english,
    appLockEnabled: false,
    notificationsEnabled: false,
  );

  final user = UserEntity(
    uid: 'uid-1',
    email: 'user@example.com',
    emailVerified: true,
    createdAt: DateTime(2026),
  );

  setUp(() {
    repository = _MockUserPreferencesRepository();
    authController = StreamController<UserEntity?>.broadcast();
    container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => authController.stream),
        userPreferencesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(authController.close);
  });

  // Regression test: userPreferencesProvider used to build once (typically
  // while the app was still cold-starting, before auth resolved), throw
  // "no signed-in user", and cache that error forever — Settings would show
  // that error permanently even after a real, successful sign-in, because
  // nothing ever told the provider to re-subscribe.
  test('never touches the repository while signed out, and never lands in an '
      'error state', () async {
    container.listen(userPreferencesProvider, (_, _) {});
    authController.add(null);
    await Future<void>.delayed(Duration.zero);

    verifyNever(() => repository.watchPreferences());
    expect(container.read(userPreferencesProvider).hasError, isFalse);
  });

  test('subscribes to preferences once a user signs in, even though the '
      'provider first built before any user existed', () async {
    when(
      () => repository.watchPreferences(),
    ).thenAnswer((_) => Stream.value(preferences));

    container.listen(userPreferencesProvider, (_, _) {});
    // Nobody signed in yet — mirrors the app cold-starting before the
    // auth stream has resolved.
    authController.add(null);
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => repository.watchPreferences());

    // The user signs in afterward. Two hops of async propagation here —
    // authController's event, then the nested watchPreferences() stream
    // it triggers — so flush the microtask queue twice.
    authController.add(user);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(userPreferencesProvider).value, preferences);
    verify(() => repository.watchPreferences()).called(1);
  });
}
