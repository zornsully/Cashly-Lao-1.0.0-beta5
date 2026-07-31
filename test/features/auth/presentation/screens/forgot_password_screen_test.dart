import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/auth/domain/entities/user_entity.dart';
import 'package:cashly_lao/features/auth/domain/repositories/auth_repository.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_providers.dart';
import 'package:cashly_lao/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(
      UserEntity(
        uid: 'fallback',
        email: 'fallback@example.com',
        emailVerified: true,
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    repository = _MockAuthRepository();
  });

  Future<void> pumpForgotPasswordScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ForgotPasswordScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'shows a validation error and never calls the repository when the '
    'email field is empty',
    (tester) async {
      await pumpForgotPasswordScreen(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset link'));
      await tester.pumpAndSettle();

      verifyNever(() => repository.sendPasswordResetEmail(any()));
    },
  );

  testWidgets('shows the check-your-email confirmation screen on success', (
    tester,
  ) async {
    when(
      () => repository.sendPasswordResetEmail('user@example.com'),
    ).thenAnswer((_) async => const Right(unit));

    await pumpForgotPasswordScreen(tester);
    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset link'));
    await tester.pumpAndSettle();

    expect(find.text('Check your email'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Back to sign in'),
      findsOneWidget,
    );
  });

  testWidgets('shows the failure message in a snackbar and stays on the form '
      'when sending the reset email fails', (tester) async {
    when(() => repository.sendPasswordResetEmail(any())).thenAnswer(
      (_) async => const Left(AuthFailure('No account found with this email.')),
    );

    await pumpForgotPasswordScreen(tester);
    await tester.enterText(find.byType(TextFormField), 'missing@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset link'));
    await tester.pumpAndSettle();

    expect(find.text('No account found with this email.'), findsOneWidget);
    expect(find.text('Check your email'), findsNothing);
  });
}
