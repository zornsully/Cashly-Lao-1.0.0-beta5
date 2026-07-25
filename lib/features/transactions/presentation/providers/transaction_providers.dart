import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/datasources/transaction_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_sort_option.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/create_transaction_usecase.dart';
import '../../domain/usecases/delete_transaction_usecase.dart';
import '../../domain/usecases/filter_transactions_usecase.dart';
import '../../domain/usecases/update_transaction_usecase.dart';

final transactionRemoteDataSourceProvider =
    Provider<TransactionRemoteDataSource>((ref) {
      return FirestoreTransactionRemoteDataSource(
        firestore: ref.watch(firestoreProvider),
        firebaseAuth: ref.watch(firebaseAuthProvider),
      );
    });

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    ref.watch(transactionRemoteDataSourceProvider),
  );
});

/// The month currently shown by the Transactions list, truncated to its
/// first day. Persists for the app session (not autoDispose) so switching
/// tabs and coming back doesn't reset the user's place back to "this
/// month."
class SelectedTransactionsMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }
}

final selectedTransactionsMonthProvider =
    NotifierProvider<SelectedTransactionsMonth, DateTime>(
      SelectedTransactionsMonth.new,
    );

/// Transactions for an arbitrary month, updating in real time as Firestore
/// changes. Shared by any feature that needs a specific month's
/// transactions independent of the Transactions tab's own browsing state
/// (Dashboard's and Budget's providers both key off this rather than each
/// re-deriving the same stream).
final transactionsForMonthProvider =
    StreamProvider.family<List<TransactionEntity>, DateTime>((ref, month) {
      return ref
          .watch(transactionRepositoryProvider)
          .watchTransactionsForMonth(month);
    });

/// Query parameters for [transactionsInRangeProvider]. A record gets
/// structural equality for free, which is exactly what a Riverpod
/// `family` key needs.
typedef TransactionsRangeQuery = ({DateTime start, DateTime endExclusive});

/// Transactions in an arbitrary date range, updating in real time as
/// Firestore changes. Used by Reports for multi-month trends.
final transactionsInRangeProvider =
    StreamProvider.family<List<TransactionEntity>, TransactionsRangeQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(transactionRepositoryProvider)
          .watchTransactionsInRange(
            start: query.start,
            endExclusive: query.endExclusive,
          );
    });

/// Transactions for [selectedTransactionsMonthProvider], updating in real
/// time as Firestore changes.
final transactionsProvider = StreamProvider<List<TransactionEntity>>((ref) {
  final month = ref.watch(selectedTransactionsMonthProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watchTransactionsForMonth(month);
});

/// The Transactions tab's current search/filter/sort state. Lives
/// per-screen (autoDispose) so it always resets when the user leaves and
/// comes back — same reasoning as `ShowArchivedAccounts`.
class TransactionsFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => const TransactionFilter();

  void setSearchQuery(String query) {
    state = TransactionFilter(
      searchQuery: query,
      accountId: state.accountId,
      categoryId: state.categoryId,
      type: state.type,
      sortOption: state.sortOption,
    );
  }

  void setAccountId(String? accountId) {
    state = TransactionFilter(
      searchQuery: state.searchQuery,
      accountId: accountId,
      categoryId: state.categoryId,
      type: state.type,
      sortOption: state.sortOption,
    );
  }

  void setCategoryId(String? categoryId) {
    state = TransactionFilter(
      searchQuery: state.searchQuery,
      accountId: state.accountId,
      categoryId: categoryId,
      type: state.type,
      sortOption: state.sortOption,
    );
  }

  void setType(TransactionType? type) {
    state = TransactionFilter(
      searchQuery: state.searchQuery,
      accountId: state.accountId,
      categoryId: state.categoryId,
      type: type,
      sortOption: state.sortOption,
    );
  }

  void setSortOption(TransactionSortOption sortOption) {
    state = TransactionFilter(
      searchQuery: state.searchQuery,
      accountId: state.accountId,
      categoryId: state.categoryId,
      type: state.type,
      sortOption: sortOption,
    );
  }

  /// Clears every filter/search field, but keeps the current sort — sort
  /// isn't a "filter" the user would expect a Clear action to reset (see
  /// `TransactionFilter.isActive`, which excludes it for the same reason).
  void clearFilters() {
    state = TransactionFilter(sortOption: state.sortOption);
  }
}

final transactionsFilterProvider =
    NotifierProvider.autoDispose<TransactionsFilterNotifier, TransactionFilter>(
      TransactionsFilterNotifier.new,
    );

const _filterTransactions = FilterTransactionsUseCase();

/// [transactionsProvider], narrowed by [transactionsFilterProvider]. The
/// screen should watch this instead of [transactionsProvider] directly.
final filteredTransactionsProvider =
    Provider<AsyncValue<List<TransactionEntity>>>((ref) {
      final transactionsAsync = ref.watch(transactionsProvider);
      final accounts = ref.watch(accountsProvider(true)).value ?? [];
      final categories =
          ref
              .watch(categoriesProvider((type: null, includeArchived: true)))
              .value ??
          [];
      final filter = ref.watch(transactionsFilterProvider);

      return transactionsAsync.whenData(
        (transactions) => _filterTransactions(
          transactions: transactions,
          accounts: accounts,
          categories: categories,
          filter: filter,
        ),
      );
    });

final createTransactionUseCaseProvider = Provider<CreateTransactionUseCase>((
  ref,
) {
  return CreateTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final updateTransactionUseCaseProvider = Provider<UpdateTransactionUseCase>((
  ref,
) {
  return UpdateTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>((
  ref,
) {
  return DeleteTransactionUseCase(ref.watch(transactionRepositoryProvider));
});
