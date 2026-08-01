import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/auth/domain/entities/user_entity.dart';
import 'package:cashly_lao/features/auth/domain/repositories/auth_repository.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_providers.dart';
import 'package:cashly_lao/features/auth/presentation/screens/profile_screen.dart';
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
    displayName: 'Alice',
    emailVerified: true,
    createdAt: DateTime(2026, 1, 1),
    providerIds: const ['password'],
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

  Future<void> pumpProfileScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the signed-in user\'s name and email', (tester) async {
    await pumpProfileScreen(tester);

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
  });

  testWidgets('signs out successfully and shows no error snackbar', (
    tester,
  ) async {
    when(() => repository.logout()).thenAnswer((_) async => const Right(unit));

    await pumpProfileScreen(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();

    verify(() => repository.logout()).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'shows a generic failure message when logout fails for an ordinary '
    'reason',
    (tester) async {
      when(
        () => repository.logout(),
      ).thenAnswer((_) async => const Left(ServerFailure('Network error.')));

      await pumpProfileScreen(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Network error.'), findsOneWidget);
    },
  );

  testWidgets('shows the pending-writes message when logout is refused because '
      'offline changes have not synced yet', (tester) async {
    when(() => repository.logout()).thenAnswer(
      (_) async => const Left(
        AuthFailure(
          'raw datasource message — must not be shown verbatim',
          code: 'logout-pending-writes',
        ),
      ),
    );

    await pumpProfileScreen(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Some changes haven't finished syncing yet. Connect to the "
        'internet and try again before signing out.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('raw datasource message — must not be shown verbatim'),
      findsNothing,
    );
  });

  group('edit display name dialog', () {
    testWidgets('pre-fills the current name and saves successfully', (
      tester,
    ) async {
      when(
        () => repository.updateDisplayName(any()),
      ).thenAnswer((_) async => const Right(unit));

      await pumpProfileScreen(tester);
      await tester.tap(find.byTooltip('Edit name'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Alice'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Alice Updated');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      verify(() => repository.updateDisplayName('Alice Updated')).called(1);
      expect(find.text('Name updated.'), findsOneWidget);
    });

    testWidgets('rejects an empty name without calling the repository', (
      tester,
    ) async {
      await pumpProfileScreen(tester);
      await tester.tap(find.byTooltip('Edit name'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required.'), findsOneWidget);
      verifyNever(() => repository.updateDisplayName(any()));
      // Dialog stays open.
      expect(find.text('Edit name'), findsWidgets);
    });

    testWidgets('shows a failure snackbar when the update fails', (
      tester,
    ) async {
      when(
        () => repository.updateDisplayName(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('Network error.')));

      await pumpProfileScreen(tester);
      await tester.tap(find.byTooltip('Edit name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Alice Updated');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Network error.'), findsOneWidget);
    });

    testWidgets('Cancel closes the dialog without saving', (tester) async {
      await pumpProfileScreen(tester);
      await tester.tap(find.byTooltip('Edit name'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Should not save');
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => repository.updateDisplayName(any()));
      expect(find.text('Edit name'), findsNothing);
    });
  });

  group('delete account dialog', () {
    testWidgets('rejects an empty password without calling the repository', (
      tester,
    ) async {
      await pumpProfileScreen(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      expect(find.text('Password is required.'), findsOneWidget);
      verifyNever(
        () => repository.deleteAccount(password: any(named: 'password')),
      );
      // Dialog stays open.
      expect(find.text('Delete account?'), findsOneWidget);
    });

    testWidgets('Cancel closes the dialog without deleting', (tester) async {
      await pumpProfileScreen(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'password123');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(
        () => repository.deleteAccount(password: any(named: 'password')),
      );
      expect(find.text('Delete account?'), findsNothing);
    });

    testWidgets('confirms with the entered password and succeeds', (
      tester,
    ) async {
      when(
        () => repository.deleteAccount(password: any(named: 'password')),
      ).thenAnswer((_) async => const Right(unit));

      await pumpProfileScreen(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'correct-password');
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      verify(
        () => repository.deleteAccount(password: 'correct-password'),
      ).called(1);
    });

    testWidgets('shows a failure snackbar when deletion fails', (tester) async {
      when(
        () => repository.deleteAccount(password: any(named: 'password')),
      ).thenAnswer((_) async => const Left(ServerFailure('Wrong password.')));

      await pumpProfileScreen(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'wrong-password');
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      expect(find.text('Wrong password.'), findsOneWidget);
    });

    testWidgets('skips the password field entirely for a Google-only account', (
      tester,
    ) async {
      final googleUser = UserEntity(
        uid: 'uid-2',
        email: 'google-user@example.com',
        displayName: 'Bob',
        emailVerified: true,
        createdAt: DateTime(2026, 1, 1),
        providerIds: const ['google.com'],
      );
      when(
        () => repository.authStateChanges(),
      ).thenAnswer((_) => Stream.value(googleUser));
      when(
        () => repository.deleteAccount(password: any(named: 'password')),
      ).thenAnswer((_) async => const Right(unit));

      await pumpProfileScreen(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNothing);

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      verify(() => repository.deleteAccount(password: null)).called(1);
    });
  });
}
