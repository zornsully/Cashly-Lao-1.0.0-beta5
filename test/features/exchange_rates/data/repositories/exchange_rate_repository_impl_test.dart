import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/exchange_rates/data/datasources/exchange_rate_remote_datasource.dart';
import 'package:cashly_lao/features/exchange_rates/data/models/exchange_rates_model.dart';
import 'package:cashly_lao/features/exchange_rates/data/repositories/exchange_rate_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockExchangeRateRemoteDataSource extends Mock
    implements ExchangeRateRemoteDataSource {}

void main() {
  late _MockExchangeRateRemoteDataSource dataSource;
  late ExchangeRateRepositoryImpl repository;

  setUp(() {
    dataSource = _MockExchangeRateRemoteDataSource();
    repository = ExchangeRateRepositoryImpl(dataSource);
  });

  test('getLatestRates returns Right on success', () async {
    final model = ExchangeRatesModel(
      baseCurrencyCode: 'USD',
      rates: const {'USD': 1, 'LAK': 22000},
      fetchedAtUtc: DateTime.utc(2026, 7, 24),
    );
    when(
      () => dataSource.fetchLatestRates(baseCurrencyCode: 'USD'),
    ).thenAnswer((_) async => model);

    final result = await repository.getLatestRates(baseCurrencyCode: 'USD');

    expect(result, Right<Failure, dynamic>(model));
  });

  test('getLatestRates maps ServerException to ServerFailure', () async {
    when(
      () => dataSource.fetchLatestRates(baseCurrencyCode: 'USD'),
    ).thenThrow(const ServerException('boom'));

    final result = await repository.getLatestRates(baseCurrencyCode: 'USD');

    expect(result, const Left<Failure, dynamic>(ServerFailure('boom')));
  });
}
