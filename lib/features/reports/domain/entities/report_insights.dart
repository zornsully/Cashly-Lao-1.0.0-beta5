import 'package:equatable/equatable.dart';

import '../../../dashboard/domain/entities/category_spending.dart';

/// Derived, at-a-glance figures layered on top of a `MonthlyReport` — never
/// stored, always recomputed from it (plus the previous period's totals,
/// for the month-over-month figure). Kept as a separate entity rather than
/// more `MonthlyReport` fields, the same layering `ConvertedMonthlyTotals`
/// already uses: these are optional, derived context, not part of the
/// report's own raw aggregation.
class ReportInsights extends Equatable {
  const ReportInsights({
    required this.savingsRatePercentByCurrency,
    required this.averageDailySpendByCurrency,
    required this.topCategoryByCurrency,
    required this.expenseChangePercentByCurrency,
  });

  /// (income - expense) / income * 100. 0 for a currency with no income.
  final Map<String, double> savingsRatePercentByCurrency;

  /// Total expense / number of days in the reporting period.
  final Map<String, double> averageDailySpendByCurrency;

  /// The single highest-spend category this period, per currency. Omits a
  /// currency with no expense categories at all.
  final Map<String, CategorySpending> topCategoryByCurrency;

  /// (current - previous) / previous * 100, vs. the immediately preceding
  /// period of the same length. Omits a currency whose previous-period
  /// expense was 0 — "percent change from zero" has no meaningful value,
  /// so it's left out rather than shown as 0% or an infinite figure.
  final Map<String, double> expenseChangePercentByCurrency;

  @override
  List<Object?> get props => [
    savingsRatePercentByCurrency,
    averageDailySpendByCurrency,
    topCategoryByCurrency,
    expenseChangePercentByCurrency,
  ];
}
