import 'package:equatable/equatable.dart';

import '../../../budget/domain/entities/budget_progress.dart';
import '../../../dashboard/domain/entities/category_spending.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import 'account_spending.dart';

/// A full analytical snapshot of a reporting period: income vs expense,
/// spending by category and by account, budget-vs-actual, and the raw
/// transactions in scope — everything the Reports screen shows.
///
/// [month] is always the browsing anchor (used for CSV export labeling and
/// for [budgetProgress], since budgets are inherently monthly) — but the
/// actual window summarized can be narrower or differently placed than
/// that calendar month whenever a `ReportFilter` custom date range is
/// active. The caller (see `monthlyReportProvider`) decides which
/// transactions to pass in; this class only aggregates them.
class MonthlyReport extends Equatable {
  const MonthlyReport({
    required this.month,
    required this.totalIncomeByCurrency,
    required this.totalExpenseByCurrency,
    required this.spendingByCategory,
    required this.accountBreakdown,
    required this.budgetProgress,
    required this.transactions,
  });

  final DateTime month;
  final Map<String, double> totalIncomeByCurrency;
  final Map<String, double> totalExpenseByCurrency;

  /// Expense categories in scope, grouped by currency and sorted by
  /// amount descending within each currency — same shape Dashboard uses.
  final Map<String, List<CategorySpending>> spendingByCategory;

  /// Expense accounts in scope, grouped by currency and sorted by amount
  /// descending within each currency.
  final Map<String, List<AccountSpending>> accountBreakdown;

  /// Every budget set for [month], with actual spend computed against it —
  /// same shape the Budget tab uses. Always keyed to the anchor month,
  /// never narrowed by a custom date-range filter (a budget is a monthly
  /// concept; a sub-month range doesn't have a well-defined "budget vs
  /// actual" of its own).
  final List<BudgetProgress> budgetProgress;

  /// The raw transactions this report summarizes, newest first — used by
  /// the detailed transaction list and Expense Watch detection so both
  /// stay in sync with whatever filter produced this report.
  final List<TransactionEntity> transactions;

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
    accountBreakdown,
    budgetProgress,
    transactions,
  ];
}
