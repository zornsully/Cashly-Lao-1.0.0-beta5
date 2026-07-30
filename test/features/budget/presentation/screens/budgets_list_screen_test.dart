import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_currency.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/utils/currency_formatter.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/accounts/domain/repositories/account_repository.dart';
import 'package:cashly_lao/features/accounts/presentation/providers/account_providers.dart';
import 'package:cashly_lao/features/budget/domain/entities/budget_entity.dart';
import 'package:cashly_lao/features/budget/domain/repositories/budget_repository.dart';
import 'package:cashly_lao/features/budget/presentation/providers/budget_providers.dart';
import 'package:cashly_lao/features/budget/presentation/screens/budgets_list_screen.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/categories/domain/repositories/category_repository.dart';
import 'package:cashly_lao/features/categories/presentation/providers/category_providers.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:cashly_lao/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:cashly_lao/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockBudgetRepository extends Mock implements BudgetRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

void main() {
  final now = DateTime.now();

  final category = CategoryEntity(
    id: 'cat-1',
    name: 'Groceries',
    type: CategoryType.expense,
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isDefault: false,
    isArchived: false,
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
  );

  testWidgets(
    'shows a "no budget set" row for an expense category with no budget '
    'this month',
    (tester) async {
      final categoryRepository = _MockCategoryRepository();
      final budgetRepository = _MockBudgetRepository();
      final accountRepository = _MockAccountRepository();
      final transactionRepository = _MockTransactionRepository();

      when(
        () => categoryRepository.watchCategories(
          type: any(named: 'type'),
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer((_) => Stream.value([category]));
      when(
        () => budgetRepository.watchBudgetsForMonth(any()),
      ).thenAnswer((_) => Stream.value(const <BudgetEntity>[]));
      when(
        () => accountRepository.watchAccounts(
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => transactionRepository.watchTransactionsForMonth(any()),
      ).thenAnswer((_) => Stream.value(const []));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryRepositoryProvider.overrideWithValue(categoryRepository),
            budgetRepositoryProvider.overrideWithValue(budgetRepository),
            accountRepositoryProvider.overrideWithValue(accountRepository),
            transactionRepositoryProvider.overrideWithValue(
              transactionRepository,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BudgetsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text(l10n.noBudgetSetLabel), findsOneWidget);
      expect(find.text(l10n.setBudgetButton), findsOneWidget);
    },
  );

  testWidgets('shows the month summary and an approaching-limit budget row', (
    tester,
  ) async {
    final categoryRepository = _MockCategoryRepository();
    final budgetRepository = _MockBudgetRepository();
    final accountRepository = _MockAccountRepository();
    final transactionRepository = _MockTransactionRepository();

    final month = DateTime(now.year, now.month);
    final account = AccountEntity(
      id: 'acc-1',
      name: 'Cash',
      type: AccountType.cash,
      balance: 0,
      currencyCode: 'LAK',
      icon: AppIconKey.cash,
      color: AppColorKey.emerald,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
    final budget = BudgetEntity(
      id: '${category.id}_2026-03',
      categoryId: category.id,
      month: month,
      limitAmount: 1000,
      currencyCode: 'LAK',
      createdAt: now,
      updatedAt: now,
    );
    final transaction = TransactionEntity(
      id: 'txn-1',
      accountId: account.id,
      categoryId: category.id,
      type: TransactionType.expense,
      amount: 850,
      date: month,
      note: '',
      createdAt: now,
      updatedAt: now,
    );

    when(
      () => categoryRepository.watchCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value([category]));
    when(
      () => budgetRepository.watchBudgetsForMonth(any()),
    ).thenAnswer((_) => Stream.value([budget]));
    when(
      () => accountRepository.watchAccounts(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value([account]));
    when(
      () => transactionRepository.watchTransactionsForMonth(any()),
    ).thenAnswer((_) => Stream.value([transaction]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(categoryRepository),
          budgetRepositoryProvider.overrideWithValue(budgetRepository),
          accountRepositoryProvider.overrideWithValue(accountRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BudgetsListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final lak = SupportedCurrencies.byCode('LAK');

    // Month summary header: budgeted 1000, spent 850, remaining 150.
    expect(find.text(l10n.budgetedTotalLabel), findsOneWidget);
    expect(find.text(l10n.spentTotalLabel), findsOneWidget);
    expect(find.text(l10n.remainingTotalLabel), findsOneWidget);
    expect(find.text(CurrencyFormatter.format(1000, lak)), findsOneWidget);
    expect(find.text(CurrencyFormatter.format(150, lak)), findsWidgets);

    // The tile itself: 85% used, not yet overspent.
    expect(
      find.text(
        '${l10n.budgetPercentUsedLabel('85')} · '
        '${l10n.remainingAmountMessage(CurrencyFormatter.format(150, lak))}',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
