import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/auth/domain/entities/user_entity.dart';
import 'package:cashly_lao/features/auth/domain/repositories/auth_repository.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_providers.dart';
import 'package:cashly_lao/features/auth/presentation/screens/login_screen.dart';
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

  Future<void> pumpLoginScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );
    // AuthController's AsyncNotifier.build() is itself async, so the very
    // first frame still has isLoading == true (PrimaryButton renders a
    // spinner, not its label) until that build future resolves.
    await tester.pump();
  }

  final user = UserEntity(
    uid: 'uid-1',
    email: 'user@example.com',
    emailVerified: true,
    createdAt: DateTime(2026),
  );

  testWidgets(
    'shows validation errors and never calls the repository when the form '
    'is empty',
    (tester) async {
      await pumpLoginScreen(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
      verifyNever(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    },
  );

  testWidgets('submits the entered credentials and shows no error on success', (
    tester,
  ) async {
    when(
      () => repository.login(email: 'user@example.com', password: 'Str0ngPass'),
    ).thenAnswer((_) async => Right(user));

    await pumpLoginScreen(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Str0ngPass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();

    verify(
      () => repository.login(email: 'user@example.com', password: 'Str0ngPass'),
    ).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('shows the failure message in a snackbar when login fails', (
    tester,
  ) async {
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const Left(AuthFailure('Incorrect email or password.')),
    );

    await pumpLoginScreen(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'WrongPass1');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });
}
