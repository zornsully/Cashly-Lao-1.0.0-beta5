import '../../../exchange_rates/domain/entities/exchange_rates.dart';
import '../entities/converted_monthly_totals.dart';
import '../entities/monthly_report.dart';

/// Converts a [MonthlyReport]'s per-currency totals into one figure in
/// [targetCurrencyCode], using [rates]. Pure and Firebase-free, same shape
/// as every other reports usecase.
class ConvertReportTotalsUseCase {
  const ConvertReportTotalsUseCase();

  /// Returns null only when [report] has nothing convertible at all (no
  /// currency present is covered by [rates]) — callers should treat that
  /// the same as "conversion unavailable," never show a zeroed-out figure.
  ///
  /// When [rates] covers *some* but not all of the report's currencies, the
  /// returned total still reflects only the covered ones —
  /// [ConvertedMonthlyTotals.excludedCurrencyCodes] names what was left
  /// out, so a caller can say so rather than presenting a partial figure
  /// as if it were complete.
  ConvertedMonthlyTotals? call({
    required MonthlyReport report,
    required ExchangeRates rates,
    required String targetCurrencyCode,
  }) {
    var totalIncome = 0.0;
    var totalExpense = 0.0;
    var convertedAnyCurrency = false;
    final excludedCurrencyCodes = <String>[];

    for (final currencyCode in report.currencies) {
      final income = report.totalIncomeByCurrency[currencyCode] ?? 0;
      final expense = report.totalExpenseByCurrency[currencyCode] ?? 0;

      final convertedIncome = rates.convert(
        amount: income,
        from: currencyCode,
        to: targetCurrencyCode,
      );
      final convertedExpense = rates.convert(
        amount: expense,
        from: currencyCode,
        to: targetCurrencyCode,
      );
      if (convertedIncome == null || convertedExpense == null) {
        excludedCurrencyCodes.add(currencyCode);
        continue;
      }

      totalIncome += convertedIncome;
      totalExpense += convertedExpense;
      convertedAnyCurrency = true;
    }

    if (!convertedAnyCurrency) return null;

    return ConvertedMonthlyTotals(
      currencyCode: targetCurrencyCode,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      ratesAsOfUtc: rates.fetchedAtUtc,
      excludedCurrencyCodes: excludedCurrencyCodes,
    );
  }
}
