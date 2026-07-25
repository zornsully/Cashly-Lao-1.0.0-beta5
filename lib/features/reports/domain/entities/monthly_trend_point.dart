import 'package:equatable/equatable.dart';

/// One month's income/expense totals in a multi-month trend — the data
/// behind the Income vs Expense trend chart.
class MonthlyTrendPoint extends Equatable {
  const MonthlyTrendPoint({
    required this.month,
    required this.totalIncomeByCurrency,
    required this.totalExpenseByCurrency,
  });

  final DateTime month;
  final Map<String, double> totalIncomeByCurrency;
  final Map<String, double> totalExpenseByCurrency;

  @override
  List<Object?> get props => [
    month,
    totalIncomeByCurrency,
    totalExpenseByCurrency,
  ];
}
