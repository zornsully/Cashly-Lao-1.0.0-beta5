import 'package:equatable/equatable.dart';

/// A [MonthlyReport]'s per-currency totals rolled up into one comparable
/// figure in [currencyCode], using a fetched exchange rate. Raw per-currency
/// amounts stay currency-exact everywhere else — this is only ever an
/// additional, clearly-labeled converted view, never a replacement.
class ConvertedMonthlyTotals extends Equatable {
  const ConvertedMonthlyTotals({
    required this.currencyCode,
    required this.totalIncome,
    required this.totalExpense,
    required this.ratesAsOfUtc,
    this.excludedCurrencyCodes = const [],
  });

  final String currencyCode;
  final double totalIncome;
  final double totalExpense;

  /// When the underlying exchange rates were fetched — shown alongside the
  /// figure so it's never presented as more precise/live than it is.
  final DateTime ratesAsOfUtc;

  /// Currencies present in the report that [ratesAsOfUtc]'s snapshot had no
  /// rate for, so their income/expense couldn't be folded into this total.
  /// Empty means every currency in the report was converted. Kept distinct
  /// from returning `null` (see [ConvertReportTotalsUseCase]'s doc comment):
  /// a *partial* total is still a real, useful figure — it just needs to
  /// say so, rather than silently under-representing the month.
  final List<String> excludedCurrencyCodes;

  bool get isPartial => excludedCurrencyCodes.isNotEmpty;

  double get net => totalIncome - totalExpense;

  @override
  List<Object?> get props => [
    currencyCode,
    totalIncome,
    totalExpense,
    ratesAsOfUtc,
    excludedCurrencyCodes,
  ];
}
