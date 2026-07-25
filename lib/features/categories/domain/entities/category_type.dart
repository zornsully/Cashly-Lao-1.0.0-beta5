/// The two category types transactions can be tagged with.
enum CategoryType {
  income(label: 'Income'),
  expense(label: 'Expense');

  const CategoryType({required this.label});

  final String label;
}
