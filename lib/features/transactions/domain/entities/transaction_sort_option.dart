/// How [FilterTransactionsUseCase] orders its result. Newest-first matches
/// the order Firestore already returns (see
/// `transaction_remote_datasource.dart`), so [dateDesc] is a no-op sort in
/// the common case — the others are genuine re-orderings.
enum TransactionSortOption {
  dateDesc(label: 'Newest first'),
  dateAsc(label: 'Oldest first'),
  amountDesc(label: 'Amount: high to low'),
  amountAsc(label: 'Amount: low to high');

  const TransactionSortOption({required this.label});

  final String label;
}
