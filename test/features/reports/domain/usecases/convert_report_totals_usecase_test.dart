import 'package:cashly_lao/features/exchange_rates/domain/entities/exchange_rates.dart';
import 'package:cashly_lao/features/reports/domain/entities/monthly_report.dart';
import 'package:cashly_lao/features/reports/domain/usecases/convert_report_totals_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = ConvertReportTotalsUseCase();

  final rates = ExchangeRates(
    baseCurrencyCode: 'USD',
    rates: const {'USD': 1, 'LAK': 22000, 'THB': 35},
    fetchedAtUtc: DateTime.utc(2026, 7, 24),
  );

  MonthlyReport reportWith({
    required Map<String, double> income,
    required Map<String, double> expense,
  }) {
    return MonthlyReport(
      month: DateTime(2026, 7),
      totalIncomeByCurrency: income,
      totalExpenseByCurrency: expense,
      spendingByCategory: const {},
      budgetProgress: const [],
    );
  }

  test('sums every currency converted into the target currency', () {
    final report = reportWith(
      income: {'USD': 100, 'LAK': 220000},
      expense: {'USD': 20, 'LAK': 0},
    );

    final result = useCase(
      report: report,
      rates: rates,
      targetCurrencyCode: 'USD',
    );

    // 100 USD + (220000 LAK -> 10 USD) = 110 USD income.
    expect(result!.totalIncome, 110);
    // 20 USD + 0 = 20 USD expense.
    expect(result.totalExpense, 20);
    expect(result.net, 90);
    expect(result.currencyCode, 'USD');
    expect(result.ratesAsOfUtc, rates.fetchedAtUtc);
  });

  test('skips a currency the rates snapshot does not cover, and flags it '
      'as excluded rather than presenting the total as complete', () {
    final report = reportWith(income: {'USD': 100, 'EUR': 50}, expense: {});

    final result = useCase(
      report: report,
      rates: rates,
      targetCurrencyCode: 'USD',
    );

    // EUR isn't in `rates`, so only the USD leg is counted.
    expect(result!.totalIncome, 100);
    expect(result.isPartial, isTrue);
    expect(result.excludedCurrencyCodes, ['EUR']);
  });

  test('reports no excluded currencies when every currency converts', () {
    final report = reportWith(
      income: {'USD': 100, 'LAK': 220000},
      expense: {'USD': 20, 'LAK': 0},
    );

    final result = useCase(
      report: report,
      rates: rates,
      targetCurrencyCode: 'USD',
    );

    expect(result!.isPartial, isFalse);
    expect(result.excludedCurrencyCodes, isEmpty);
  });

  test('returns null when no currency in the report is covered', () {
    final report = reportWith(income: {'EUR': 50}, expense: {'EUR': 10});

    final result = useCase(
      report: report,
      rates: rates,
      targetCurrencyCode: 'USD',
    );

    expect(result, isNull);
  });

  test('returns a zero-activity total for an empty report', () {
    final report = reportWith(income: {}, expense: {});

    final result = useCase(
      report: report,
      rates: rates,
      targetCurrencyCode: 'USD',
    );

    expect(result, isNull);
  });
}
