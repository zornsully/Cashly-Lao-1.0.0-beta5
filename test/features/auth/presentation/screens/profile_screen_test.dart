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
}
