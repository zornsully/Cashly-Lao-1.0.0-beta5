import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/dashboard/domain/usecases/build_dashboard_summary_usecase.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = BuildDashboardSummaryUseCase();

  AccountEntity account({
    required String id,
    required double balance,
    required String currencyCode,
  }) {
    return AccountEntity(
      id: id,
      name: 'Account $id',
      type: AccountType.cash,
      balance: balance,
      currencyCode: currencyCode,
      icon: AppIconKey.cash,
      color: AppColorKey.emerald,
      isArchived: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  CategoryEntity category({
    required String id,
    required String name,
    CategoryType type = CategoryType.expense,
  }) {
    return CategoryEntity(
      id: id,
      name: name,
      type: type,
      icon: AppIconKey.other,
      color: AppColorKey.grey,
      isDefault: false,
      isArchived: false,
      sortOrder: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  TransactionEntity transaction({
    required String id,
    required String accountId,
    required String categoryId,
    required TransactionType type,
    required double amount,
    DateTime? date,
  }) {
    return TransactionEntity(
      id: id,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      date: date ?? DateTime(2026, 3, 10),
      note: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  test('returns empty aggregates for empty inputs', () {
    final summary = useCase(
      accounts: const [],
      monthTransactions: const [],
      categories: const [],
    );

    expect(summary.totalBalanceByCurrency, isEmpty);
    expect(summary.totalIncomeByCurrency, isEmpty);
    expect(summary.totalExpenseByCurrency, isEmpty);
    expect(summary.recentTransactions, isEmpty);
    expect(summary.spendingByCategory, isEmpty);
    expect(summary.hasAnyAccounts, isFalse);
    expect(summary.hasAnyTransactionsThisMonth, isFalse);
  });

  test('sums account balances grouped by currency, not conflated', () {
    final accounts = [
      account(id: 'a1', balance: 100, currencyCode: 'LAK'),
      account(id: 'a2', balance: 250, currencyCode: 'LAK'),
      account(id: 'a3', balance: 50, currencyCode: 'USD'),
    ];

    final summary = useCase(
      accounts: accounts,
      monthTransactions: const [],
      categories: const [],
    );

    expect(summary.totalBalanceByCurrency, {'LAK': 350, 'USD': 50});
  });

  test(
    'sums income and expense per currency using the account\'s currency',
    () {
      final accounts = [
        account(id: 'lak-acc', balance: 0, currencyCode: 'LAK'),
        account(id: 'usd-acc', balance: 0, currencyCode: 'USD'),
      ];
      final categories = [category(id: 'food', name: 'Food')];
      final transactions = [
        transaction(
          id: 't1',
          accountId: 'lak-acc',
          categoryId: 'food',
          type: TransactionType.income,
          amount: 1000,
        ),
        transaction(
          id: 't2',
          accountId: 'lak-acc',
          categoryId: 'food',
          type: TransactionType.expense,
          amount: 200,
        ),
        transaction(
          id: 't3',
          accountId: 'usd-acc',
          categoryId: 'food',
          type: TransactionType.expense,
          amount: 30,
        ),
      ];

      final summary = useCase(
        accounts: accounts,
        monthTransactions: transactions,
        categories: categories,
      );

      expect(summary.totalIncomeByCurrency, {'LAK': 1000});
      expect(summary.totalExpenseByCurrency, {'LAK': 200, 'USD': 30});
    },
  );

  test(
    'excludes transactions whose account no longer exists from currency totals '
    'but keeps them in recentTransactions',
    () {
      final accounts = [account(id: 'acc-1', balance: 0, currencyCode: 'LAK')];
      final orphaned = transaction(
        id: 'orphan',
        accountId: 'deleted-account',
        categoryId: 'food',
        type: TransactionType.expense,
        amount: 999,
      );
      final normal = transaction(
        id: 't1',
        accountId: 'acc-1',
        categoryId: 'food',
        type: TransactionType.expense,
        amount: 50,
      );

      final summary = useCase(
        accounts: accounts,
        monthTransactions: [orphaned, normal],
        categories: [category(id: 'food', name: 'Food')],
      );

      expect(summary.totalExpenseByCurrency, {'LAK': 50});
      expect(summary.recentTransactions, containsAll([orphaned, normal]));
    },
  );

  test('limits recentTransactions to 5, preserving input order', () {
    final accounts = [account(id: 'acc-1', balance: 0, currencyCode: 'LAK')];
    final transactions = [
      for (var i = 0; i < 8; i++)
        transaction(
          id: 'txn-$i',
          accountId: 'acc-1',
          categoryId: 'food',
          type: TransactionType.expense,
          amount: 10,
          date: DateTime(2026, 3, 30 - i),
        ),
    ];

    final summary = useCase(
      accounts: accounts,
      monthTransactions: transactions,
      categories: [category(id: 'food', name: 'Food')],
    );

    expect(summary.recentTransactions, hasLength(5));
    expect(summary.recentTransactions.map((t) => t.id), [
      'txn-0',
      'txn-1',
      'txn-2',
      'txn-3',
      'txn-4',
    ]);
  });

  test('groups spending by category per currency with correct percentages, '
      'sorted by amount descending', () {
    final accounts = [account(id: 'acc-1', balance: 0, currencyCode: 'LAK')];
    final categories = [
      category(id: 'food', name: 'Food'),
      category(id: 'transport', name: 'Transport'),
    ];
    final transactions = [
      transaction(
        id: 't1',
        accountId: 'acc-1',
        categoryId: 'food',
        type: TransactionType.expense,
        amount: 300,
      ),
      transaction(
        id: 't2',
        accountId: 'acc-1',
        categoryId: 'transport',
        type: TransactionType.expense,
        amount: 100,
      ),
      // A second Food transaction, so amounts accumulate per category.
      transaction(
        id: 't3',
        accountId: 'acc-1',
        categoryId: 'food',
        type: TransactionType.expense,
        amount: 100,
      ),
    ];

    final summary = useCase(
      accounts: accounts,
      monthTransactions: transactions,
      categories: categories,
    );

    final lakSpending = summary.spendingByCategory['LAK']!;
    expect(lakSpending, hasLength(2));
    expect(lakSpending[0].category.id, 'food');
    expect(lakSpending[0].amount, 400);
    expect(lakSpending[0].percentageOfExpense, 80);
    expect(lakSpending[1].category.id, 'transport');
    expect(lakSpending[1].amount, 100);
    expect(lakSpending[1].percentageOfExpense, 20);
  });

  test('excludes expense entries whose category no longer exists', () {
    final accounts = [account(id: 'acc-1', balance: 0, currencyCode: 'LAK')];
    final transactions = [
      transaction(
        id: 't1',
        accountId: 'acc-1',
        categoryId: 'deleted-category',
        type: TransactionType.expense,
        amount: 50,
      ),
    ];

    final summary = useCase(
      accounts: accounts,
      monthTransactions: transactions,
      categories: const [],
    );

    // Still counted in the currency total...
    expect(summary.totalExpenseByCurrency, {'LAK': 50});
    // ...but not attributable to any category bucket.
    expect(summary.spendingByCategory['LAK'], isEmpty);
  });

  test('does not divide by zero when a currency has no expense', () {
    final accounts = [account(id: 'acc-1', balance: 0, currencyCode: 'LAK')];
    final transactions = [
      transaction(
        id: 't1',
        accountId: 'acc-1',
        categoryId: 'food',
        type: TransactionType.income,
        amount: 500,
      ),
    ];

    final summary = useCase(
      accounts: accounts,
      monthTransactions: transactions,
      categories: [category(id: 'food', name: 'Food')],
    );

    expect(summary.spendingByCategory['LAK'], isNull);
  });
}
