import '../../../accounts/domain/entities/account_entity.dart';
import '../../../budget/domain/entities/budget_entity.dart';
import '../../../budget/domain/usecases/build_budget_progress_usecase.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../dashboard/domain/usecases/compute_category_spending_usecase.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../entities/monthly_report.dart';

/// Pure aggregation logic for a single month's report — no repository
/// dependency, same reasoning as Dashboard's and Budget's usecases: there's
/// no new data source here, just arithmetic combining data Accounts,
/// Categories, Transactions, and Budgets already stream. Composes their
/// existing pure usecases rather than re-deriving the same computations.
class BuildMonthlyReportUseCase {
  const BuildMonthlyReportUseCase();

  static const _computeCategorySpending = ComputeCategorySpendingUseCase();
  static const _buildBudgetProgress = BuildBudgetProgressUseCase();

  MonthlyReport call({
    required DateTime month,
    required List<AccountEntity> accounts,
    required List<TransactionEntity> monthTransactions,
    required List<CategoryEntity> categories,
    required List<BudgetEntity> budgets,
  }) {
    final accountsById = {for (final account in accounts) account.id: account};

    final totalIncomeByCurrency = <String, double>{};
    for (final transaction in monthTransactions) {
      if (transaction.type != TransactionType.income) continue;
      final account = accountsById[transaction.accountId];
      if (account == null) continue;
      totalIncomeByCurrency.update(
        account.currencyCode,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final categorySpending = _computeCategorySpending(
      transactions: monthTransactions,
      accounts: accounts,
      categories: categories,
    );

    final budgetProgress = _buildBudgetProgress(
      budgets: budgets,
      monthTransactions: monthTransactions,
      accounts: accounts,
      categories: categories,
    );

    return MonthlyReport(
      month: DateTime(month.year, month.month),
      totalIncomeByCurrency: totalIncomeByCurrency,
      totalExpenseByCurrency: categorySpending.totalExpenseByCurrency,
      spendingByCategory: categorySpending.spendingByCategory,
      budgetProgress: budgetProgress,
    );
  }
}
