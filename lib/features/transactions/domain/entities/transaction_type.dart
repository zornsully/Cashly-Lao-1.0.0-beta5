/// Whether a transaction adds to or subtracts from its account's balance,
/// or moves money between two of the user's own accounts.
enum TransactionType {
  income(label: 'Income'),
  expense(label: 'Expense'),
  transfer(label: 'Transfer');

  const TransactionType({required this.label});

  final String label;
}
