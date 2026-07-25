import '../../../accounts/domain/entities/account_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../entities/transaction_entity.dart';
import '../entities/transaction_filter.dart';
import '../entities/transaction_sort_option.dart';

/// Applies search/filter/sort to an already-fetched list of transactions.
/// Pure and repository-free — same reasoning as `BuildBudgetProgressUseCase`
/// and `ComputeCategorySpendingUseCase`: this is arithmetic/list-processing
/// over data the caller already streams, not a new data source to abstract
/// over.
class FilterTransactionsUseCase {
  const FilterTransactionsUseCase();

  List<TransactionEntity> call({
    required List<TransactionEntity> transactions,
    required List<AccountEntity> accounts,
    required List<CategoryEntity> categories,
    required TransactionFilter filter,
  }) {
    final accountsById = {for (final account in accounts) account.id: account};
    final categoriesById = {
      for (final category in categories) category.id: category,
    };

    Iterable<TransactionEntity> result = transactions;

    if (filter.type != null) {
      result = result.where((t) => t.type == filter.type);
    }

    if (filter.accountId != null) {
      result = result.where(
        (t) =>
            t.accountId == filter.accountId ||
            t.toAccountId == filter.accountId,
      );
    }

    if (filter.categoryId != null) {
      result = result.where((t) => t.categoryId == filter.categoryId);
    }

    if (filter.searchQuery.isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      result = result.where((t) {
        if (t.note.toLowerCase().contains(query)) return true;
        final category = categoriesById[t.categoryId];
        if (category != null && category.name.toLowerCase().contains(query)) {
          return true;
        }
        final account = accountsById[t.accountId];
        if (account != null && account.name.toLowerCase().contains(query)) {
          return true;
        }
        final toAccount = accountsById[t.toAccountId];
        return toAccount != null &&
            toAccount.name.toLowerCase().contains(query);
      });
    }

    final sorted = result.toList();
    switch (filter.sortOption) {
      case TransactionSortOption.dateDesc:
        sorted.sort((a, b) => b.date.compareTo(a.date));
      case TransactionSortOption.dateAsc:
        sorted.sort((a, b) => a.date.compareTo(b.date));
      case TransactionSortOption.amountDesc:
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
      case TransactionSortOption.amountAsc:
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
    }
    return sorted;
  }
}
