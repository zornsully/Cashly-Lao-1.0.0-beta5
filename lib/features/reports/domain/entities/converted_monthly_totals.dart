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
  });

  final String currencyCode;
  final double totalIncome;
  final double totalExpense;

  /// When the underlying exchange rates were fetched — shown alongside the
  /// figure so it's never presented as more precise/live than it is.
  final DateTime ratesAsOfUtc;

  double get net => totalIncome - totalExpense;

  @override
  List<Object?> get props => [
    currencyCode,
    totalIncome,
    totalExpense,
    ratesAsOfUtc,
  ];
}
