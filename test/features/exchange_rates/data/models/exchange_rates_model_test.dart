import 'package:cashly_lao/features/exchange_rates/data/models/exchange_rates_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson parses a successful open.er-api.com response', () {
    final model = ExchangeRatesModel.fromJson(const {
      'result': 'success',
      'base_code': 'USD',
      'rates': {'USD': 1, 'LAK': 22463.14, 'THB': 35.2, 'EUR': 0.92},
    });

    expect(model.baseCurrencyCode, 'USD');
    expect(model.rates['LAK'], 22463.14);
    expect(model.rates['THB'], 35.2);
  });

  test('fromJson throws when the API reports a non-success result', () {
    expect(
      () => ExchangeRatesModel.fromJson(const {
        'result': 'error',
        'error-type': 'unsupported-code',
      }),
      throwsFormatException,
    );
  });
}
