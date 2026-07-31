import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/auth/domain/entities/user_entity.dart';
import 'package:cashly_lao/features/auth/domain/repositories/auth_repository.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_providers.dart';
import 'package:cashly_lao/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  final user = UserEntity(
    uid: 'uid-1',
    email: 'user@example.com',
    emailVerified: false,
    createdAt: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(user);
  });

  setUp(() {
    repository = _MockAuthRepository();
    when(
      () => repository.authStateChanges(),
    ).thenAnswer((_) => Stream.value(user));
  });

  Future<void> pumpVerifyEmailScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VerifyEmailScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the signed-in user\'s email in the subtitle', (
    tester,
  ) async {
    await pumpVerifyEmailScreen(tester);

    expect(find.textContaining('user@example.com'), findsOneWidget);
  });

  testWidgets(
    'shows a success message and starts the cooldown when resend succeeds',
    (tester) async {
      when(
        () => repository.sendEmailVerification(),
      ).thenAnswer((_) async => const Right(unit));

      await pumpVerifyEmailScreen(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Resend email'));
      await tester.pumpAndSettle();

      expect(find.text('Verification email sent.'), findsOneWidget);
    },
  );

  testWidgets('shows the failure message when resend fails', (tester) async {
    when(
      () => repository.sendEmailVerification(),
    ).thenAnswer((_) async => const Left(ServerFailure('Network error.')));

    await pumpVerifyEmailScreen(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Resend email'));
    await tester.pumpAndSettle();

    expect(find.text('Network error.'), findsOneWidget);
  });

  testWidgets('signs out successfully and shows no error snackbar', (
    tester,
  ) async {
    when(() => repository.logout()).thenAnswer((_) async => const Right(unit));

    await pumpVerifyEmailScreen(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();

    verify(() => repository.logout()).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'shows the pending-writes message when sign-out is refused because '
    'offline changes have not synced yet — previously this failed silently',
    (tester) async {
      when(() => repository.logout()).thenAnswer(
        (_) async => const Left(
          AuthFailure('raw datasource message', code: 'logout-pending-writes'),
        ),
      );

      await pumpVerifyEmailScreen(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Some changes haven't finished syncing yet. Connect to the "
          'internet and try again before signing out.',
        ),
        findsOneWidget,
      );
    },
  );
}
