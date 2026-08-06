import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/budget/domain/entities/budget_entity.dart';
import 'package:cashly_lao/features/budget/domain/usecases/build_budget_progress_usecase.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = BuildBudgetProgressUseCase();

  AccountEntity account({required String id, required String currencyCode}) {
    return AccountEntity(
      id: id,
      name: 'Account $id',
      type: AccountType.cash,
      balance: 0,
      currencyCode: currencyCode,
      icon: AppIconKey.cash,
      color: AppColorKey.emerald,
      isArchived: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  CategoryEntity category({required String id, required String name}) {
    return CategoryEntity(
      id: id,
      name: name,
      type: CategoryType.expense,
      icon: AppIconKey.other,
      color: AppColorKey.grey,
      isDefault: false,
      isArchived: false,
      sortOrder: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  BudgetEntity budget({
    required String categoryId,
    required double limitAmount,
    String currencyCode = 'LAK',
  }) {
    return BudgetEntity(
      id: '${categoryId}_2026-03',
      categoryId: categoryId,
      month: DateTime(2026, 3),
      limitAmount: limitAmount,
      currencyCode: currencyCode,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  TransactionEntity expenseTxn({
    required String accountId,
    required String categoryId,
    required double amount,
  }) {
    return TransactionEntity(
      id: 'txn-${accountId}_$categoryId-$amount',
      accountId: accountId,
      categoryId: categoryId,
      type: TransactionType.expense,
      amount: amount,
      date: DateTime(2026, 3, 10),
      note: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  test('computes spent amount from expense transactions matching the '
      "budget's currency", () {
    final accounts = [account(id: 'acc-1', currencyCode: 'LAK')];
    final categories = [category(id: 'food', name: 'Food')];
    final budgets = [budget(categoryId: 'food', limitAmount: 500)];
    final transactions = [
      expenseTxn(accountId: 'acc-1', categoryId: 'food', amount: 100),
      expenseTxn(accountId: 'acc-1', categoryId: 'food', amount: 50),
    ];

    final result = useCase(
      budgets: budgets,
      month: DateTime(2026, 3),
      monthTransactions: transactions,
      accounts: accounts,
      categories: categories,
    );

    expect(result, hasLength(1));
    expect(result.single.spentAmount, 150);
    expect(result.single.remainingAmount, 350);
    expect(result.single.percentageUsed, 30);
    expect(result.single.isOverspent, isFalse);
  });

  test('detects overspending', () {
    final accounts = [account(id: 'acc-1', currencyCode: 'LAK')];
    final categories = [category(id: 'food', name: 'Food')];
    final budgets = [budget(categoryId: 'food', limitAmount: 100)];
    final transactions = [
      expenseTxn(accountId: 'acc-1', categoryId: 'food', amount: 150),
    ];

    final result = useCase(
      budgets: budgets,
      month: DateTime(2026, 3),
      monthTransactions: transactions,
      accounts: accounts,
      categories: categories,
    );

    expect(result.single.spentAmount, 150);
    expect(result.single.remainingAmount, -50);
    expect(result.single.percentageUsed, 150);
    expect(result.single.isOverspent, isTrue);
  });

  test('only counts spending in the same currency as the budget', () {
    final accounts = [
      account(id: 'lak-acc', currencyCode: 'LAK'),
      account(id: 'usd-acc', currencyCode: 'USD'),
    ];
    final categories = [category(id: 'food', name: 'Food')];
    final budgets = [
      budget(categoryId: 'food', limitAmount: 100, currencyCode: 'LAK'),
    ];
    final transactions = [
      expenseTxn(accountId: 'lak-acc', categoryId: 'food', amount: 40),
      // Same category, but a USD account — shouldn't count toward the
      // LAK budget.
      expenseTxn(accountId: 'usd-acc', categoryId: 'food', amount: 1000),
    ];

    final result = useCase(
      budgets: budgets,
      month: DateTime(2026, 3),
      monthTransactions: transactions,
      accounts: accounts,
      categories: categories,
    );

    expect(result.single.spentAmount, 40);
  });

  test('ignores income transactions entirely', () {
    final accounts = [account(id: 'acc-1', currencyCode: 'LAK')];
    final categories = [category(id: 'food', name: 'Food')];
    final budgets = [budget(categoryId: 'food', limitAmount: 100)];
    final transactions = [
      TransactionEntity(
        id: 'income-1',
        accountId: 'acc-1',
        categoryId: 'food',
        type: TransactionType.income,
        amount: 999,
        date: DateTime(2026, 3, 10),
        note: '',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ];

    final result = useCase(
      budgets: budgets,
      month: DateTime(2026, 3),
      monthTransactions: transactions,
      accounts: accounts,
      categories: categories,
    );

    expect(result.single.spentAmount, 0);
  });

  test('excludes budgets whose category no longer exists', () {
    final budgets = [budget(categoryId: 'deleted-category', limitAmount: 100)];

    final result = useCase(
      budgets: budgets,
      month: DateTime(2026, 3),
      monthTransactions: const [],
      accounts: const [],
      categories: const [],
    );

    expect(result, isEmpty);
  });

  test('reports zero spent for a budget with no matching transactions', () {
    final accounts = [account(id: 'acc-1', currencyCode: 'LAK')];
    final categories = [category(id: 'food', name: 'Food')];
    final budgets = [budget(categoryId: 'food', limitAmount: 200)];

    final result = useCase(
      budgets: budgets,
      month: DateTime(2026, 3),
      monthTransactions: const [],
      accounts: accounts,
      categories: categories,
    );

    expect(result.single.spentAmount, 0);
    expect(result.single.remainingAmount, 200);
    expect(result.single.isOverspent, isFalse);
  });

  test('ignores an expense outside the selected budget month', () {
    final accounts = [account(id: 'acc-1', currencyCode: 'LAK')];
    final categories = [category(id: 'food', name: 'Food')];
    final budgets = [budget(categoryId: 'food', limitAmount: 200)];
    final transactions = [
      expenseTxn(accountId: 'acc-1', categoryId: 'food', amount: 50),
      TransactionEntity(
        id: 'april-expense',
        accountId: 'acc-1',
        categoryId: 'food',
        type: TransactionType.expense,
        amount: 100,
        date: DateTime(2026, 4, 1),
        note: '',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ];

    final result = useCase(
      budgets: budgets,
      month: DateTime(2026, 3),
      monthTransactions: transactions,
      accounts: accounts,
      categories: categories,
    );

    expect(result.single.spentAmount, 50);
  });

  test('excludes an invalid zero-limit budget before calculating progress', () {
    final result = useCase(
      budgets: [budget(categoryId: 'food', limitAmount: 0)],
      month: DateTime(2026, 3),
      monthTransactions: const [],
      accounts: [account(id: 'acc-1', currencyCode: 'LAK')],
      categories: [category(id: 'food', name: 'Food')],
    );

    expect(result, isEmpty);
  });
}
