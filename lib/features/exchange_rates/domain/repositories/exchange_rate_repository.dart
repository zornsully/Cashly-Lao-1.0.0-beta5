import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/exchange_rates.dart';

abstract interface class ExchangeRateRepository {
  /// The latest available exchange rates against [baseCurrencyCode].
  /// Implementations are expected to cache this for the app session rather
  /// than re-fetching on every call — the underlying source only updates
  /// once a day.
  Future<Either<Failure, ExchangeRates>> getLatestRates({
    required String baseCurrencyCode,
  });
}
