import '../entities/monthly_report.dart';
import '../entities/report_insights.dart';

/// Pure arithmetic over an already-built `MonthlyReport` plus the previous
/// period's totals — no repository dependency, same reasoning as every
/// other Reports usecase.
class ComputeReportInsightsUseCase {
  const ComputeReportInsightsUseCase();

  /// [periodDays] is the number of days the report's transactions span
  /// (e.g. the number of days in the anchor month, or a custom range's
  /// length) — always at least 1. [previousPeriodExpenseByCurrency] is the
  /// immediately preceding period of the same length, used only for the
  /// month-over-month figure.
  ReportInsights call({
    required MonthlyReport report,
    required int periodDays,
    required Map<String, double> previousPeriodExpenseByCurrency,
  }) {
    final days = periodDays < 1 ? 1 : periodDays;

    final savingsRateByCurrency = <String, double>{};
    final averageDailySpendByCurrency = <String, double>{};
    final expenseChangePercentByCurrency = <String, double>{};

    for (final currency in report.currencies) {
      final income = report.totalIncomeByCurrency[currency] ?? 0;
      final expense = report.totalExpenseByCurrency[currency] ?? 0;

      savingsRateByCurrency[currency] = income == 0
          ? 0
          : ((income - expense) / income) * 100;

      averageDailySpendByCurrency[currency] = expense / days;

      final previousExpense = previousPeriodExpenseByCurrency[currency];
      if (previousExpense != null && previousExpense > 0) {
        expenseChangePercentByCurrency[currency] =
            ((expense - previousExpense) / previousExpense) * 100;
      }
    }

    final topCategoryByCurrency = {
      for (final entry in report.spendingByCategory.entries)
        if (entry.value.isNotEmpty) entry.key: entry.value.first,
    };

    return ReportInsights(
      savingsRatePercentByCurrency: savingsRateByCurrency,
      averageDailySpendByCurrency: averageDailySpendByCurrency,
      topCategoryByCurrency: topCategoryByCurrency,
      expenseChangePercentByCurrency: expenseChangePercentByCurrency,
    );
  }
}
