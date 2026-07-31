import 'package:cashly_lao/core/providers/app_lock_state_provider.dart';
import 'package:cashly_lao/core/providers/local_auth_providers.dart';
import 'package:cashly_lao/features/settings/presentation/screens/lock_screen.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late _MockLocalAuthentication localAuth;
  late ProviderContainer container;

  setUp(() {
    localAuth = _MockLocalAuthentication();
  });

  Future<void> pumpLockScreen(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [localAuthenticationProvider.overrideWithValue(localAuth)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LockScreen(),
        ),
      ),
    );
  }

  testWidgets(
    'auto-prompts for authentication on first appearance and unlocks the '
    'session on success',
    (tester) async {
      when(
        () => localAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: any(named: 'biometricOnly'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
        ),
      ).thenAnswer((_) async => true);

      await pumpLockScreen(tester);
      await tester.pumpAndSettle();

      verify(
        () => localAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: any(named: 'biometricOnly'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
        ),
      ).called(1);
      expect(container.read(isUnlockedProvider), isTrue);
      expect(
        find.text('Authentication failed. Please try again.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'shows a failure message and stays locked when the user fails the '
    'authentication challenge',
    (tester) async {
      when(
        () => localAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: any(named: 'biometricOnly'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
        ),
      ).thenAnswer((_) async => false);

      await pumpLockScreen(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Authentication failed. Please try again.'),
        findsOneWidget,
      );
      expect(container.read(isUnlockedProvider), isFalse);
    },
  );

  testWidgets(
    'shows an unavailable message and stays locked when local_auth throws',
    (tester) async {
      when(
        () => localAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: any(named: 'biometricOnly'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
        ),
      ).thenThrow(
        const LocalAuthException(code: LocalAuthExceptionCode.uiUnavailable),
      );

      await pumpLockScreen(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Authentication isn't available right now. Please try again.",
        ),
        findsOneWidget,
      );
      expect(container.read(isUnlockedProvider), isFalse);
    },
  );

  testWidgets(
    'retrying via the Unlock button re-runs authentication and can unlock',
    (tester) async {
      var callCount = 0;
      when(
        () => localAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: any(named: 'biometricOnly'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
        ),
      ).thenAnswer((_) async {
        callCount += 1;
        return callCount > 1;
      });

      await pumpLockScreen(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Authentication failed. Please try again.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Unlock'));
      await tester.pumpAndSettle();

      expect(container.read(isUnlockedProvider), isTrue);
    },
  );
}
