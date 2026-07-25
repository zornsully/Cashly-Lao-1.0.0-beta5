import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/budget/domain/entities/budget_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/reports/domain/usecases/build_monthly_report_usecase.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = BuildMonthlyReportUseCase();

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

  TransactionEntity transaction({
    required String id,
    required String accountId,
    required String categoryId,
    required TransactionType type,
    required double amount,
  }) {
    return TransactionEntity(
      id: id,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      date: DateTime(2026, 3, 10),
      note: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  BudgetEntity budget({
    required String categoryId,
    required double limitAmount,
  }) {
    return BudgetEntity(
      id: '${categoryId}_2026-03',
      categoryId: categoryId,
      month: DateTime(2026, 3),
      limitAmount: limitAmount,
      currencyCode: 'LAK',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  test('combines income, expense, category spending, and budget progress', () {
    final accounts = [account(id: 'acc-1', currencyCode: 'LAK')];
    final categories = [category(id: 'food', name: 'Food')];
    final budgets = [budget(categoryId: 'food', limitAmount: 300)];
    final transactions = [
      transaction(
        id: 't1',
        accountId: 'acc-1',
        categoryId: 'food',
        type: TransactionType.income,
        amount: 1000,
      ),
      transaction(
        id: 't2',
        accountId: 'acc-1',
        categoryId: 'food',
        type: TransactionType.expense,
        amount: 200,
      ),
    ];

    final report = useCase(
      month: DateTime(2026, 3),
      accounts: accounts,
      monthTransactions: transactions,
      categories: categories,
      budgets: budgets,
    );

    expect(report.month, DateTime(2026, 3));
    expect(report.totalIncomeByCurrency, {'LAK': 1000});
    expect(report.totalExpenseByCurrency, {'LAK': 200});
    expect(report.netByCurrency, {'LAK': 800});
    expect(report.spendingByCategory['LAK'], hasLength(1));
    expect(report.spendingByCategory['LAK']!.single.category.id, 'food');
    expect(report.budgetProgress, hasLength(1));
    expect(report.budgetProgress.single.spentAmount, 200);
    expect(report.hasAnyActivity, isTrue);
  });

  test('normalizes month to the first of the month', () {
    final report = useCase(
      month: DateTime(2026, 3, 15),
      accounts: const [],
      monthTransactions: const [],
      categories: const [],
      budgets: const [],
    );

    expect(report.month, DateTime(2026, 3));
    expect(report.hasAnyActivity, isFalse);
  });

  test('excludes income from transactions whose account no longer exists', () {
    final transactions = [
      transaction(
        id: 'orphan-income',
        accountId: 'deleted-account',
        categoryId: 'food',
        type: TransactionType.income,
        amount: 500,
      ),
    ];

    final report = useCase(
      month: DateTime(2026, 3),
      accounts: const [],
      monthTransactions: transactions,
      categories: const [],
      budgets: const [],
    );

    expect(report.totalIncomeByCurrency, isEmpty);
  });
}
