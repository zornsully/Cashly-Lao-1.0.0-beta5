import 'package:cashly_lao/core/constants/app_language.dart';
import 'package:cashly_lao/core/constants/app_theme_mode.dart';
import 'package:cashly_lao/features/auth/domain/entities/user_entity.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_providers.dart';
import 'package:cashly_lao/features/settings/domain/entities/user_preferences_entity.dart';
import 'package:cashly_lao/features/settings/domain/repositories/user_preferences_repository.dart';
import 'package:cashly_lao/features/settings/presentation/providers/settings_providers.dart';
import 'package:cashly_lao/features/settings/presentation/screens/settings_screen.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

void main() {
  testWidgets(
    'renders the signed-in user\'s saved preferences, not an error state',
    (tester) async {
      final repository = _MockUserPreferencesRepository();
      final user = UserEntity(
        uid: 'uid-1',
        email: 'user@example.com',
        emailVerified: true,
        createdAt: DateTime(2026),
      );
      const preferences = UserPreferencesEntity(
        themeMode: AppThemeModePreference.dark,
        defaultCurrencyCode: 'LAK',
        language: AppLanguage.english,
        appLockEnabled: false,
        notificationsEnabled: false,
      );

      when(
        () => repository.watchPreferences(),
      ).thenAnswer((_) => Stream.value(preferences));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(user),
            ),
            userPreferencesRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.appearanceSectionTitle), findsOneWidget);
      expect(find.text(l10n.themeDarkLabel), findsOneWidget);
      expect(find.textContaining('AuthException'), findsNothing);
    },
  );
}
