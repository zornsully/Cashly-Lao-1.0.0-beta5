import 'package:equatable/equatable.dart';

import 'transaction_sort_option.dart';
import 'transaction_type.dart';

/// Search/filter/sort criteria for the Transactions list, applied
/// client-side over whatever month is already loaded (see
/// `FilterTransactionsUseCase`) — no new Firestore query, same reasoning as
/// Accounts/Categories filtering their already-fetched collection
/// client-side rather than adding server-side query complexity for a
/// personal-finance app's realistic data volumes.
class TransactionFilter extends Equatable {
  const TransactionFilter({
    this.searchQuery = '',
    this.accountId,
    this.categoryId,
    this.type,
    this.sortOption = TransactionSortOption.dateDesc,
  });

  /// Matched against the transaction's note and its category's/account's
  /// name, case-insensitively.
  final String searchQuery;

  /// Matches a transaction whose source *or* destination account is this
  /// one — a transfer touches two accounts, and filtering by either should
  /// surface it.
  final String? accountId;

  final String? categoryId;
  final TransactionType? type;
  final TransactionSortOption sortOption;

  bool get isActive =>
      searchQuery.isNotEmpty ||
      accountId != null ||
      categoryId != null ||
      type != null;

  @override
  List<Object?> get props => [
    searchQuery,
    accountId,
    categoryId,
    type,
    sortOption,
  ];
}
