import '../../../accounts/domain/entities/account_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../entities/dashboard_summary.dart';
import 'compute_category_spending_usecase.dart';

/// Pure aggregation logic for the Dashboard — no repository dependency.
/// It has nothing to fetch on its own: Accounts, Categories, and
/// Transactions already own that data, so the presentation layer watches
/// their existing providers and hands the results here to be combined.
/// Kept as a plain function-like class (rather than a repository-backed
/// usecase) because there's no new data source to abstract over — just
/// arithmetic over data three other features already stream.
class BuildDashboardSummaryUseCase {
  const BuildDashboardSummaryUseCase();

  static const int recentTransactionsLimit = 5;

  static const _computeCategorySpending = ComputeCategorySpendingUseCase();

  /// [monthTransactions] must already be sorted newest-first — that's the
  /// order `TransactionRepository.watchTransactionsForMonth` returns, and
  /// it's what makes `.take(recentTransactionsLimit)` below correct.
  DashboardSummary call({
    required List<AccountEntity> accounts,
    required List<TransactionEntity> monthTransactions,
    required List<CategoryEntity> categories,
  }) {
    final accountsById = {for (final account in accounts) account.id: account};

    final totalBalanceByCurrency = <String, double>{};
    for (final account in accounts) {
      totalBalanceByCurrency.update(
        account.currencyCode,
        (value) => value + account.balance,
        ifAbsent: () => account.balance,
      );
    }

    final totalIncomeByCurrency = <String, double>{};
    for (final transaction in monthTransactions) {
      if (transaction.type != TransactionType.income) continue;
      // See ComputeCategorySpendingUseCase for why a missing account
      // excludes a transaction from currency-keyed totals.
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

    return DashboardSummary(
      accounts: accounts,
      categories: categories,
      totalBalanceByCurrency: totalBalanceByCurrency,
      totalIncomeByCurrency: totalIncomeByCurrency,
      totalExpenseByCurrency: categorySpending.totalExpenseByCurrency,
      recentTransactions: monthTransactions
          .take(recentTransactionsLimit)
          .toList(),
      spendingByCategory: categorySpending.spendingByCategory,
    );
  }
}
