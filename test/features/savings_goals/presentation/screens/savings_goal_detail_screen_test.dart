import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/accounts/domain/repositories/account_repository.dart';
import 'package:cashly_lao/features/accounts/presentation/providers/account_providers.dart';
import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/categories/domain/repositories/category_repository.dart';
import 'package:cashly_lao/features/categories/presentation/providers/category_providers.dart';
import 'package:cashly_lao/features/savings_goals/domain/entities/savings_goal_entity.dart';
import 'package:cashly_lao/features/savings_goals/domain/repositories/savings_goal_repository.dart';
import 'package:cashly_lao/features/savings_goals/presentation/providers/savings_goal_providers.dart';
import 'package:cashly_lao/features/savings_goals/presentation/screens/savings_goal_detail_screen.dart';
import 'package:cashly_lao/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:cashly_lao/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockSavingsGoalRepository extends Mock
    implements SavingsGoalRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

void main() {
  late _MockSavingsGoalRepository goalRepository;
  late _MockAccountRepository accountRepository;
  late _MockCategoryRepository categoryRepository;
  late _MockTransactionRepository transactionRepository;

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

  setUp(() {
    goalRepository = _MockSavingsGoalRepository();
    accountRepository = _MockAccountRepository();
    categoryRepository = _MockCategoryRepository();
    transactionRepository = _MockTransactionRepository();

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
    when(
      () => categoryRepository.watchCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => transactionRepository.watchTransactionsInRange(
        start: any(named: 'start'),
        endExclusive: any(named: 'endExclusive'),
      ),
    ).thenAnswer((_) => Stream.value(const []));
  });

  Future<void> pumpDetailScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsGoalRepositoryProvider.overrideWithValue(goalRepository),
          accountRepositoryProvider.overrideWithValue(accountRepository),
          categoryRepositoryProvider.overrideWithValue(categoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SavingsGoalDetailScreen(goalId: 'goal-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the goal name and progress once data loads', (
    tester,
  ) async {
    await pumpDetailScreen(tester);

    expect(find.text('Vacation'), findsOneWidget);
    expect(find.textContaining('2,000,000'), findsWidgets);
  });

  testWidgets(
    'shows a not-found error view when the goal id does not match any goal',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savingsGoalRepositoryProvider.overrideWithValue(goalRepository),
            accountRepositoryProvider.overrideWithValue(accountRepository),
            categoryRepositoryProvider.overrideWithValue(categoryRepository),
            transactionRepositoryProvider.overrideWithValue(
              transactionRepository,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SavingsGoalDetailScreen(goalId: 'missing-goal'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.goalNotFoundMessage), findsOneWidget);
    },
  );

  testWidgets(
    'shows an error message and does not close the screen when deletion '
    'fails',
    (tester) async {
      when(
        () => goalRepository.deleteGoal(goal.id),
      ).thenAnswer((_) async => const Left(ServerFailure('Network error.')));

      await pumpDetailScreen(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, l10n.delete));
      await tester.pumpAndSettle();

      expect(find.text('Network error.'), findsOneWidget);
      expect(find.text('Vacation'), findsOneWidget);
    },
  );

  testWidgets('shows an error message when archiving fails', (tester) async {
    when(
      () => goalRepository.archiveGoal(goal.id),
    ).thenAnswer((_) async => const Left(ServerFailure('Archive failed.')));

    await pumpDetailScreen(tester);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l10n.archiveMenuItem));
    await tester.pumpAndSettle();

    expect(find.text('Archive failed.'), findsOneWidget);
  });
}
