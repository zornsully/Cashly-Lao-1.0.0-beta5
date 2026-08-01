import 'package:cashly_lao/core/constants/app_currency.dart';
import 'package:cashly_lao/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats LAK without decimals and with a leading negative sign', () {
      expect(
        CurrencyFormatter.format(6200585, SupportedCurrencies.lak),
        '₭6,200,585',
      );
      expect(
        CurrencyFormatter.format(-271000, SupportedCurrencies.lak),
        '-₭271,000',
      );
    });

    test('formats USD with two decimals and a leading negative sign', () {
      expect(
        CurrencyFormatter.format(806.79, SupportedCurrencies.usd),
        r'$806.79',
      );
      expect(
        CurrencyFormatter.format(-271, SupportedCurrencies.usd),
        r'-$271.00',
      );
    });
  });
}
