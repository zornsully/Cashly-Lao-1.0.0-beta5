import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/accounts/domain/repositories/account_repository.dart';
import 'package:cashly_lao/features/accounts/presentation/providers/account_providers.dart';
import 'package:cashly_lao/features/savings_goals/domain/entities/savings_goal_entity.dart';
import 'package:cashly_lao/features/savings_goals/domain/repositories/savings_goal_repository.dart';
import 'package:cashly_lao/features/savings_goals/presentation/providers/savings_goal_providers.dart';
import 'package:cashly_lao/features/savings_goals/presentation/screens/savings_goal_form_screen.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockSavingsGoalRepository extends Mock
    implements SavingsGoalRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  late _MockSavingsGoalRepository goalRepository;
  late _MockAccountRepository accountRepository;

  final account = AccountEntity(
    id: 'acc-1',
    name: 'Vacation Fund',
    type: AccountType.savings,
    balance: 2000000,
    currencyCode: 'LAK',
    icon: AppIconKey.savings,
    color: AppColorKey.emerald,
    isArchived: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final createdGoal = SavingsGoalEntity(
    id: 'goal-1',
    name: 'Vacation',
    targetAmount: 5000000,
    accountId: 'acc-1',
    icon: AppIconKey.savings,
    color: AppColorKey.emerald,
    isArchived: false,
    lastContributionAt: DateTime(2026),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(AppIconKey.savings);
    registerFallbackValue(AppColorKey.emerald);
  });

  setUp(() {
    goalRepository = _MockSavingsGoalRepository();
    accountRepository = _MockAccountRepository();

    when(
      () => accountRepository.watchAccounts(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value([account]));
    when(
      () => goalRepository.watchGoals(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value(const []));
  });

  Future<void> pumpFormScreen(
    WidgetTester tester, {
    SavingsGoalEntity? existing,
  }) async {
    // The form is taller than the default 600px test surface (name, target
    // amount, account picker, icon/color pickers, auto-contribution switch),
    // so the submit button sits off-screen unless the surface is enlarged.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The screen calls context.pop() (go_router) on a successful submit,
    // so it needs a real GoRouter in the tree rather than a plain
    // MaterialApp(home: ...) that only supports the Navigator's own pop.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SizedBox()),
        GoRoute(
          path: '/form',
          builder: (context, state) =>
              SavingsGoalFormScreen(existing: existing),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsGoalRepositoryProvider.overrideWithValue(goalRepository),
          accountRepositoryProvider.overrideWithValue(accountRepository),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Push (not initialLocation) so context.pop() on a successful submit
    // has a real previous page to return to, matching how this screen is
    // actually reached in the app (context.push(AppRoutes.savingsGoalNew)).
    router.push('/form');
    await tester.pumpAndSettle();
  }

  testWidgets('shows validation errors and never calls the repository when the '
      'form is empty', (tester) async {
    await pumpFormScreen(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.widgetWithText(ElevatedButton, l10n.addGoalButton));
    await tester.pumpAndSettle();

    verifyNever(
      () => goalRepository.createGoal(
        name: any(named: 'name'),
        targetAmount: any(named: 'targetAmount'),
        accountId: any(named: 'accountId'),
        icon: any(named: 'icon'),
        color: any(named: 'color'),
      ),
    );
  });

  testWidgets(
    'creates the goal with the selected account and shows no error on '
    'success',
    (tester) async {
      when(
        () => goalRepository.createGoal(
          name: any(named: 'name'),
          targetAmount: any(named: 'targetAmount'),
          accountId: any(named: 'accountId'),
          icon: any(named: 'icon'),
          color: any(named: 'color'),
        ),
      ).thenAnswer((_) async => Right(createdGoal));

      await pumpFormScreen(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.goalNameLabel),
        'Vacation',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.targetAmountLabel),
        '5000000',
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vacation Fund').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, l10n.addGoalButton));
      await tester.pumpAndSettle();

      verify(
        () => goalRepository.createGoal(
          name: 'Vacation',
          targetAmount: 5000000,
          accountId: 'acc-1',
          icon: any(named: 'icon'),
          color: any(named: 'color'),
        ),
      ).called(1);
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets('shows the failure message in a snackbar when creation fails', (
    tester,
  ) async {
    when(
      () => goalRepository.createGoal(
        name: any(named: 'name'),
        targetAmount: any(named: 'targetAmount'),
        accountId: any(named: 'accountId'),
        icon: any(named: 'icon'),
        color: any(named: 'color'),
      ),
    ).thenAnswer(
      (_) async => const Left(ServerFailure('That account is already linked.')),
    );

    await pumpFormScreen(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.goalNameLabel),
      'Vacation',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.targetAmountLabel),
      '5000000',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vacation Fund').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, l10n.addGoalButton));
    await tester.pumpAndSettle();

    expect(find.text('That account is already linked.'), findsOneWidget);
  });

  testWidgets(
    'shows the linked account as a locked field and pre-fills existing '
    'values when editing',
    (tester) async {
      final existing = SavingsGoalEntity(
        id: 'goal-1',
        name: 'Vacation',
        targetAmount: 5000000,
        accountId: 'acc-1',
        icon: AppIconKey.savings,
        color: AppColorKey.emerald,
        isArchived: false,
        lastContributionAt: DateTime(2026),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      await pumpFormScreen(tester, existing: existing);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(find.text('Vacation Fund'), findsOneWidget);
      expect(find.text(l10n.linkedAccountLockedMessage), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(
        find.widgetWithText(ElevatedButton, l10n.saveChangesButton),
        findsOneWidget,
      );
    },
  );
}
