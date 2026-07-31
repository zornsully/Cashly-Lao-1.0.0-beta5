import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/accounts/domain/repositories/account_repository.dart';
import 'package:cashly_lao/features/accounts/presentation/providers/account_providers.dart';
import 'package:cashly_lao/features/savings_goals/domain/entities/savings_goal_entity.dart';
import 'package:cashly_lao/features/savings_goals/domain/repositories/savings_goal_repository.dart';
import 'package:cashly_lao/features/savings_goals/presentation/providers/savings_goal_providers.dart';
import 'package:cashly_lao/features/savings_goals/presentation/screens/savings_goals_list_screen.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSavingsGoalRepository extends Mock
    implements SavingsGoalRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  testWidgets('shows an empty state when there are no savings goals yet', (
    tester,
  ) async {
    final goalRepository = _MockSavingsGoalRepository();
    final accountRepository = _MockAccountRepository();

    when(
      () => goalRepository.watchGoals(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => accountRepository.watchAccounts(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value(const []));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsGoalRepositoryProvider.overrideWithValue(goalRepository),
          accountRepositoryProvider.overrideWithValue(accountRepository),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SavingsGoalsListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.noSavingsGoalsYetTitle), findsOneWidget);
    expect(find.text(l10n.addGoalButton), findsWidgets);
  });

  testWidgets('shows a goal card with its progress', (tester) async {
    final goalRepository = _MockSavingsGoalRepository();
    final accountRepository = _MockAccountRepository();

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
    final goal = SavingsGoalEntity(
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

    when(
      () => goalRepository.watchGoals(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value([goal]));
    when(
      () => accountRepository.watchAccounts(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value([account]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsGoalRepositoryProvider.overrideWithValue(goalRepository),
          accountRepositoryProvider.overrideWithValue(accountRepository),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SavingsGoalsListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vacation'), findsOneWidget);
  });

  testWidgets('renders multiple goals in a grid on a wide layout', (
    tester,
  ) async {
    final goalRepository = _MockSavingsGoalRepository();
    final accountRepository = _MockAccountRepository();

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
    final goals = [
      SavingsGoalEntity(
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
      ),
      SavingsGoalEntity(
        id: 'goal-2',
        name: 'New Laptop',
        targetAmount: 8000000,
        accountId: 'acc-1',
        icon: AppIconKey.savings,
        color: AppColorKey.emerald,
        isArchived: false,
        lastContributionAt: DateTime(2026),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ];

    when(
      () => goalRepository.watchGoals(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value(goals));
    when(
      () => accountRepository.watchAccounts(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value([account]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsGoalRepositoryProvider.overrideWithValue(goalRepository),
          accountRepositoryProvider.overrideWithValue(accountRepository),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SavingsGoalsListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default test surface is 800px wide, capped to 720px by
    // ResponsiveCenter — comfortably over the 360px-per-column threshold,
    // so this already exercises the GridView path (not the single-column
    // ListView), the same way the single-goal test above does.
    expect(find.text('Vacation'), findsOneWidget);
    expect(find.text('New Laptop'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });
}
