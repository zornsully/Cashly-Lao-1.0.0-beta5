import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/auth/domain/entities/user_entity.dart';
import 'package:cashly_lao/features/auth/domain/repositories/auth_repository.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_providers.dart';
import 'package:cashly_lao/features/auth/presentation/screens/register_screen.dart';
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

  Future<void> pumpRegisterScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RegisterScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  final user = UserEntity(
    uid: 'uid-1',
    email: 'new@example.com',
    displayName: 'New User',
    emailVerified: false,
    createdAt: DateTime(2026),
  );

  testWidgets('shows validation errors and never calls the repository when the '
      'form is empty', (tester) async {
    await pumpRegisterScreen(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pumpAndSettle();

    verifyNever(
      () => repository.register(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    );
  });

  testWidgets(
    'rejects a confirm-password mismatch without calling the repository',
    (tester) async {
      await pumpRegisterScreen(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'New User');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'new@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'Str0ngPass');
      await tester.enterText(find.byType(TextFormField).at(3), 'DifferentPass');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pumpAndSettle();

      verifyNever(
        () => repository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      );
    },
  );

  testWidgets('submits matching credentials and shows no error on success', (
    tester,
  ) async {
    when(
      () => repository.register(
        email: 'new@example.com',
        password: 'Str0ngPass',
        displayName: 'New User',
      ),
    ).thenAnswer((_) async => Right(user));

    await pumpRegisterScreen(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'New User');
    await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Str0ngPass');
    await tester.enterText(find.byType(TextFormField).at(3), 'Str0ngPass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pumpAndSettle();

    verify(
      () => repository.register(
        email: 'new@example.com',
        password: 'Str0ngPass',
        displayName: 'New User',
      ),
    ).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('shows the failure message in a snackbar when registration '
      'fails', (tester) async {
    when(
      () => repository.register(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer(
      (_) async =>
          const Left(AuthFailure('An account already exists with this email.')),
    );

    await pumpRegisterScreen(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'New User');
    await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Str0ngPass');
    await tester.enterText(find.byType(TextFormField).at(3), 'Str0ngPass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(
      find.text('An account already exists with this email.'),
      findsOneWidget,
    );
  });
}
