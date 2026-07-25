import '../../domain/entities/exchange_rates.dart';

class ExchangeRatesModel extends ExchangeRates {
  const ExchangeRatesModel({
    required super.baseCurrencyCode,
    required super.rates,
    required super.fetchedAtUtc,
  });

  /// Parses the response shape from https://open.er-api.com/v6/latest/{base}
  /// (ExchangeRate-API's free, no-key "open access" endpoint):
  /// `{ "result": "success", "base_code": "USD", "rates": {"LAK": 22463.1, ...} }`
  factory ExchangeRatesModel.fromJson(Map<String, dynamic> json) {
    if (json['result'] != 'success') {
      throw const FormatException('Exchange rate response was not "success".');
    }
    final rawRates = json['rates'] as Map<String, dynamic>;
    return ExchangeRatesModel(
      baseCurrencyCode: json['base_code'] as String,
      rates: rawRates.map(
        (code, value) => MapEntry(code, (value as num).toDouble()),
      ),
      fetchedAtUtc: DateTime.now().toUtc(),
    );
  }
}
