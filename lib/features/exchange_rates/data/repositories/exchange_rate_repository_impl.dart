import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/exchange_rates.dart';
import '../../domain/repositories/exchange_rate_repository.dart';
import '../datasources/exchange_rate_remote_datasource.dart';

class ExchangeRateRepositoryImpl
    with RepositoryGuard
    implements ExchangeRateRepository {
  const ExchangeRateRepositoryImpl(this._remoteDataSource);

  final ExchangeRateRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, ExchangeRates>> getLatestRates({
    required String baseCurrencyCode,
  }) {
    return guard(
      () => _remoteDataSource.fetchLatestRates(
        baseCurrencyCode: baseCurrencyCode,
      ),
    );
  }
}
