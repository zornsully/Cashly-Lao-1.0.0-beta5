import 'package:equatable/equatable.dart';

import '../../../budget/domain/entities/budget_progress.dart';
import '../../../dashboard/domain/entities/category_spending.dart';

/// A full analytical snapshot of one calendar month: income vs expense,
/// spending by category, and budget-vs-actual — everything the Reports
/// screen's single-month view shows.
class MonthlyReport extends Equatable {
  const MonthlyReport({
    required this.month,
    required this.totalIncomeByCurrency,
    required this.totalExpenseByCurrency,
    required this.spendingByCategory,
    required this.budgetProgress,
  });

  final DateTime month;
  final Map<String, double> totalIncomeByCurrency;
  final Map<String, double> totalExpenseByCurrency;

  /// Expense categories this month, grouped by currency and sorted by
  /// amount descending within each currency — same shape Dashboard uses.
  final Map<String, List<CategorySpending>> spendingByCategory;

  /// Every budget set for this month, with actual spend computed against
  /// it — same shape the Budget tab uses.
  final List<BudgetProgress> budgetProgress;

  Set<String> get currencies => {
    ...totalIncomeByCurrency.keys,
    ...totalExpenseByCurrency.keys,
  };

  Map<String, double> get netByCurrency => {
    for (final currency in currencies)
      currency:
          (totalIncomeByCurrency[currency] ?? 0) -
          (totalExpenseByCurrency[currency] ?? 0),
  };

  bool get hasAnyActivity => currencies.isNotEmpty;

  /// Flattens this report into export-ready rows: one row per category
  /// spend, plus one totals row per currency. Kept here so a future CSV/
  /// PDF export feature has a stable, tested data shape to build on
  /// instead of re-deriving it from the raw fields above.
  List<Map<String, Object?>> toExportRows() {
    final rows = <Map<String, Object?>>[];

    for (final entry in spendingByCategory.entries) {
      final currency = entry.key;
      for (final spending in entry.value) {
        rows.add({
          'month': month.toIso8601String(),
          'currency': currency,
          'rowType': 'category',
          'category': spending.category.name,
          'amount': spending.amount,
          'percentageOfExpense': spending.percentageOfExpense,
        });
      }
    }

    final net = netByCurrency;
    for (final currency in currencies) {
      rows.add({
        'month': month.toIso8601String(),
        'currency': currency,
        'rowType': 'summary',
        'totalIncome': totalIncomeByCurrency[currency] ?? 0,
        'totalExpense': totalExpenseByCurrency[currency] ?? 0,
        'net': net[currency] ?? 0,
      });
    }

    return rows;
  }

  @override
  List<Object?> get props => [
    month,
    totalIncomeByCurrency,
    totalExpenseByCurrency,
    spendingByCategory,
    budgetProgress,
  ];
}
