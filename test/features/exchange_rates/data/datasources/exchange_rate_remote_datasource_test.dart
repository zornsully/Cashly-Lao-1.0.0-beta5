import 'dart:convert';

import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/features/exchange_rates/data/datasources/exchange_rate_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetchLatestRates parses a 200 response into a model', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://open.er-api.com/v6/latest/USD');
      return http.Response(
        jsonEncode({
          'result': 'success',
          'base_code': 'USD',
          'rates': {'USD': 1, 'LAK': 22000},
        }),
        200,
      );
    });
    final dataSource = HttpExchangeRateRemoteDataSource(client: client);

    final result = await dataSource.fetchLatestRates(baseCurrencyCode: 'USD');

    expect(result.baseCurrencyCode, 'USD');
    expect(result.rates['LAK'], 22000);
  });

  test('fetchLatestRates throws ServerException on a non-200 response', () async {
    final client = MockClient((request) async => http.Response('', 500));
    final dataSource = HttpExchangeRateRemoteDataSource(client: client);

    expect(
      () => dataSource.fetchLatestRates(baseCurrencyCode: 'USD'),
      throwsA(isA<ServerException>()),
    );
  });

  test(
    'fetchLatestRates throws ServerException when the response body is malformed',
    () async {
      final client = MockClient((request) async => http.Response('{', 200));
      final dataSource = HttpExchangeRateRemoteDataSource(client: client);

      expect(
        () => dataSource.fetchLatestRates(baseCurrencyCode: 'USD'),
        throwsA(isA<ServerException>()),
      );
    },
  );
}
