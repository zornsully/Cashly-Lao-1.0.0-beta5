import '../../../accounts/domain/entities/account_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../entities/budget_entity.dart';
import '../entities/budget_progress.dart';

/// Pure aggregation logic for Budget progress — no repository dependency,
/// same reasoning as the Dashboard feature's
/// `BuildDashboardSummaryUseCase`: there's no new data source to abstract
/// over, just arithmetic combining Budgets' own data with Transactions'.
class BuildBudgetProgressUseCase {
  const BuildBudgetProgressUseCase();

  /// Only transactions on an account whose currency matches a given
  /// budget's [BudgetEntity.currencyCode] count against it — see
  /// PROJECT_PROGRESS.md for why budgets don't mix currencies.
  List<BudgetProgress> call({
    required List<BudgetEntity> budgets,
    required DateTime month,
    required List<TransactionEntity> monthTransactions,
    required List<AccountEntity> accounts,
    required List<CategoryEntity> categories,
  }) {
    final accountsById = {for (final account in accounts) account.id: account};
    final categoriesById = {
      for (final category in categories) category.id: category,
    };

    // categoryId -> currency -> amount spent
    final spentByCategoryAndCurrency = <String, Map<String, double>>{};
    final normalizedMonth = DateTime(month.year, month.month);
    for (final transaction in monthTransactions) {
      if (transaction.type != TransactionType.expense) continue;
      if (transaction.categoryId == null || transaction.categoryId!.isEmpty) {
        continue;
      }
      if (transaction.date.year != normalizedMonth.year ||
          transaction.date.month != normalizedMonth.month ||
          !transaction.amount.isFinite ||
          transaction.amount <= 0) {
        continue;
      }
      final account = accountsById[transaction.accountId];
      if (account == null) continue; // see Sprint 4's known limitation

      // Guaranteed non-null: every expense transaction has a category —
      // only a transfer (already filtered out above) omits one.
      final byCurrency = spentByCategoryAndCurrency.putIfAbsent(
        transaction.categoryId!,
        () => <String, double>{},
      );
      byCurrency.update(
        account.currencyCode,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    return [
      for (final budget in budgets)
        if (budget.month.year == normalizedMonth.year &&
            budget.month.month == normalizedMonth.month &&
            budget.limitAmount.isFinite &&
            budget.limitAmount > 0)
          if (categoriesById[budget.categoryId]
              case final CategoryEntity category)
            BudgetProgress(
              budget: budget,
              category: category,
              spentAmount:
                  spentByCategoryAndCurrency[budget.categoryId]?[budget
                      .currencyCode] ??
                  0,
            ),
    ];
  }
}
