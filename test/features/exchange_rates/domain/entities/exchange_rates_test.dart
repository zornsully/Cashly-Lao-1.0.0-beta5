import 'package:cashly_lao/features/exchange_rates/domain/entities/exchange_rates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rates = ExchangeRates(
    baseCurrencyCode: 'USD',
    rates: const {'USD': 1, 'LAK': 22000, 'THB': 35},
    fetchedAtUtc: DateTime.utc(2026, 7, 24),
  );

  test('convert returns the same amount when from == to', () {
    expect(rates.convert(amount: 100, from: 'LAK', to: 'LAK'), 100);
  });

  test('convert from the base currency multiplies by the target rate', () {
    expect(rates.convert(amount: 10, from: 'USD', to: 'LAK'), 220000);
  });

  test('convert to the base currency divides by the source rate', () {
    expect(rates.convert(amount: 22000, from: 'LAK', to: 'USD'), 1);
  });

  test('convert routes a non-base pair through the base currency', () {
    // 35 THB = 1 USD = 22000 LAK, so 350 THB should be 220000 LAK.
    expect(rates.convert(amount: 350, from: 'THB', to: 'LAK'), 220000);
  });

  test('convert returns null when a currency is not covered', () {
    expect(rates.convert(amount: 100, from: 'EUR', to: 'LAK'), isNull);
    expect(rates.convert(amount: 100, from: 'LAK', to: 'EUR'), isNull);
  });
}
