import '../../../accounts/domain/entities/account_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../entities/monthly_trend_point.dart';

/// Pure aggregation logic for the multi-month Income vs Expense trend —
/// no repository dependency, same reasoning as this feature's other
/// usecase.
class BuildMonthlyTrendUseCase {
  const BuildMonthlyTrendUseCase();

  /// Buckets [transactions] (which must already cover the full
  /// `monthCount`-month window ending at [endMonth]) into one
  /// [MonthlyTrendPoint] per month, oldest first — the order a
  /// left-to-right trend chart wants.
  List<MonthlyTrendPoint> call({
    required DateTime endMonth,
    required int monthCount,
    required List<TransactionEntity> transactions,
    required List<AccountEntity> accounts,
  }) {
    final accountsById = {for (final account in accounts) account.id: account};
    final normalizedEnd = DateTime(endMonth.year, endMonth.month);

    final months = [
      for (var i = monthCount - 1; i >= 0; i--)
        DateTime(normalizedEnd.year, normalizedEnd.month - i),
    ];

    final incomeByMonthAndCurrency = <DateTime, Map<String, double>>{};
    final expenseByMonthAndCurrency = <DateTime, Map<String, double>>{};

    for (final transaction in transactions) {
      final account = accountsById[transaction.accountId];
      if (account == null) continue;

      final monthKey = DateTime(transaction.date.year, transaction.date.month);
      final byMonthAndCurrency = transaction.type == TransactionType.income
          ? incomeByMonthAndCurrency
          : expenseByMonthAndCurrency;

      final byCurrency = byMonthAndCurrency.putIfAbsent(
        monthKey,
        () => <String, double>{},
      );
      byCurrency.update(
        account.currencyCode,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    return [
      for (final month in months)
        MonthlyTrendPoint(
          month: month,
          totalIncomeByCurrency: incomeByMonthAndCurrency[month] ?? const {},
          totalExpenseByCurrency: expenseByMonthAndCurrency[month] ?? const {},
        ),
    ];
  }
}
