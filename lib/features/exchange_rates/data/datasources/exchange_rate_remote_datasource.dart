import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../models/exchange_rates_model.dart';

abstract interface class ExchangeRateRemoteDataSource {
  Future<ExchangeRatesModel> fetchLatestRates({required String baseCurrencyCode});
}

/// Backed by ExchangeRate-API's free, no-API-key "open access" endpoint —
/// updates once a day, covers LAK alongside every other currency Cashly
/// supports. See https://www.exchangerate-api.com/docs/free for terms;
/// its required attribution is shown wherever converted figures appear.
class HttpExchangeRateRemoteDataSource implements ExchangeRateRemoteDataSource {
  HttpExchangeRateRemoteDataSource({required http.Client client})
    : _client = client; // ignore: prefer_initializing_formals

  final http.Client _client;

  static const _baseUrl = 'https://open.er-api.com/v6/latest';

  @override
  Future<ExchangeRatesModel> fetchLatestRates({
    required String baseCurrencyCode,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$baseCurrencyCode');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ServerException(
          'Exchange rate request failed (${response.statusCode}).',
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ExchangeRatesModel.fromJson(json);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Could not fetch exchange rates: $e');
    }
  }
}
