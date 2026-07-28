import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/error/failure.dart';
import '../../data/datasources/exchange_rate_remote_datasource.dart';
import '../../data/repositories/exchange_rate_repository_impl.dart';
import '../../domain/entities/exchange_rates.dart';
import '../../domain/repositories/exchange_rate_repository.dart';

final _httpClientProvider = Provider<http.Client>((ref) => http.Client());

final exchangeRateRemoteDataSourceProvider =
    Provider<ExchangeRateRemoteDataSource>((ref) {
      return HttpExchangeRateRemoteDataSource(
        client: ref.watch(_httpClientProvider),
      );
    });

final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  return ExchangeRateRepositoryImpl(
    ref.watch(exchangeRateRemoteDataSourceProvider),
  );
});

/// USD is used as the fetch anchor regardless of which currencies the user
/// actually holds — [ExchangeRates.convert] routes any pair through it, so
/// one daily fetch covers every currency Cashly supports and switching the
/// user's default currency never triggers a re-fetch.
const _rollupBaseCurrencyCode = 'USD';

/// The latest exchange rates, fetched once and cached for the app session
/// (the underlying source only updates once a day, so there's no value in
/// re-fetching more often — see [ExchangeRateRepository]). Deliberately not
/// autoDispose: Reports is the only consumer today, but caching for the
/// session means re-visiting Reports doesn't re-hit the network.
final latestExchangeRatesProvider =
    FutureProvider<Either<Failure, ExchangeRates>>((ref) {
      return ref
          .watch(exchangeRateRepositoryProvider)
          .getLatestRates(baseCurrencyCode: _rollupBaseCurrencyCode);
    });
