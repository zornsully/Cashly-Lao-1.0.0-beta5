import '../../../accounts/domain/entities/account_entity.dart';
import '../../../budget/domain/entities/budget_entity.dart';
import '../../../budget/domain/usecases/build_budget_progress_usecase.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../dashboard/domain/usecases/compute_category_spending_usecase.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../entities/monthly_report.dart';
import 'build_account_breakdown_usecase.dart';

/// Pure aggregation logic for a reporting period — no repository
/// dependency, same reasoning as Dashboard's and Budget's usecases: there's
/// no new data source here, just arithmetic combining data Accounts,
/// Categories, Transactions, and Budgets already stream. Composes their
/// existing pure usecases rather than re-deriving the same computations.
class BuildMonthlyReportUseCase {
  const BuildMonthlyReportUseCase();

  static const _computeCategorySpending = ComputeCategorySpendingUseCase();
  static const _buildAccountBreakdown = BuildAccountBreakdownUseCase();
  static const _buildBudgetProgress = BuildBudgetProgressUseCase();

  /// [month] is always the calendar-month anchor Reports is browsing.
  /// [transactions] is whatever the caller has already resolved (a plain
  /// month, or a `ReportFilter` custom range/account/category/type
  /// narrowing) and drives every figure except [MonthlyReport.budgetProgress].
  /// [monthTransactionsForBudgets] is always [month]'s *complete*,
  /// unfiltered transaction list — a budget's actual spend must never be
  /// deflated just because the report view happens to be filtered to one
  /// account or category; see `MonthlyReport`'s own doc comment.
  MonthlyReport call({
    required DateTime month,
    required List<AccountEntity> accounts,
    required List<TransactionEntity> transactions,
    required List<TransactionEntity> monthTransactionsForBudgets,
    required List<CategoryEntity> categories,
    required List<BudgetEntity> budgets,
  }) {
    final accountsById = {for (final account in accounts) account.id: account};

    final totalIncomeByCurrency = <String, double>{};
    for (final transaction in transactions) {
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
      transactions: transactions,
      accounts: accounts,
      categories: categories,
    );

    final accountBreakdown = _buildAccountBreakdown(
      transactions: transactions,
      accounts: accounts,
    );

    final budgetProgress = _buildBudgetProgress(
      budgets: budgets,
      month: month,
      monthTransactions: monthTransactionsForBudgets,
      accounts: accounts,
      categories: categories,
    );

    final sortedTransactions = [...transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    return MonthlyReport(
      month: DateTime(month.year, month.month),
      totalIncomeByCurrency: totalIncomeByCurrency,
      totalExpenseByCurrency: categorySpending.totalExpenseByCurrency,
      spendingByCategory: categorySpending.spendingByCategory,
      accountBreakdown: accountBreakdown,
      budgetProgress: budgetProgress,
      transactions: sortedTransactions,
    );
  }
}
