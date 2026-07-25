import '../../../accounts/domain/entities/account_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../entities/category_spending.dart';

/// The result of grouping a set of expense transactions by category and
/// currency.
class CategorySpendingResult {
  const CategorySpendingResult({
    required this.totalExpenseByCurrency,
    required this.spendingByCategory,
  });

  final Map<String, double> totalExpenseByCurrency;
  final Map<String, List<CategorySpending>> spendingByCategory;
}

/// Pure aggregation — no repository dependency, same reasoning as
/// [BuildDashboardSummaryUseCase]. Extracted as its own usecase because
/// it's shared: both Dashboard's summary and Reports' monthly report need
/// the identical "expenses grouped by category, per currency, with
/// percentages" computation.
class ComputeCategorySpendingUseCase {
  const ComputeCategorySpendingUseCase();

  CategorySpendingResult call({
    required List<TransactionEntity> transactions,
    required List<AccountEntity> accounts,
    required List<CategoryEntity> categories,
  }) {
    final accountsById = {for (final account in accounts) account.id: account};
    final categoriesById = {
      for (final category in categories) category.id: category,
    };

    final totalExpenseByCurrency = <String, double>{};
    // currency -> categoryId -> amount
    final expenseByCategoryAndCurrency = <String, Map<String, double>>{};

    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense) continue;
      // If the linked account was since deleted there's no currency to
      // attribute this transaction to, so it's excluded here.
      final account = accountsById[transaction.accountId];
      if (account == null) continue;
      final currency = account.currencyCode;

      totalExpenseByCurrency.update(
        currency,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
      final byCategory = expenseByCategoryAndCurrency.putIfAbsent(
        currency,
        () => <String, double>{},
      );
      // Guaranteed non-null: every expense transaction has a category —
      // only a transfer (already filtered out above) omits one.
      byCategory.update(
        transaction.categoryId!,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final spendingByCategory = <String, List<CategorySpending>>{};
    for (final entry in expenseByCategoryAndCurrency.entries) {
      final currency = entry.key;
      final totalExpense = totalExpenseByCurrency[currency] ?? 0;

      final spendings = <CategorySpending>[
        for (final categoryEntry in entry.value.entries)
          if (categoriesById[categoryEntry.key] case final category?)
            CategorySpending(
              category: category,
              amount: categoryEntry.value,
              percentageOfExpense: totalExpense == 0
                  ? 0
                  : (categoryEntry.value / totalExpense) * 100,
            ),
      ]..sort((a, b) => b.amount.compareTo(a.amount));

      spendingByCategory[currency] = spendings;
    }

    return CategorySpendingResult(
      totalExpenseByCurrency: totalExpenseByCurrency,
      spendingByCategory: spendingByCategory,
    );
  }
}
