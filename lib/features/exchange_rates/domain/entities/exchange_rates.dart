import 'package:equatable/equatable.dart';

/// A snapshot of currency exchange rates relative to [baseCurrencyCode],
/// as of [fetchedAtUtc]. Used to roll up spending across a user's
/// different-currency accounts into one comparable figure on Reports —
/// the underlying per-currency amounts stay currency-exact everywhere
/// else; this is only ever used for that one converted display figure.
class ExchangeRates extends Equatable {
  const ExchangeRates({
    required this.baseCurrencyCode,
    required this.rates,
    required this.fetchedAtUtc,
  });

  final String baseCurrencyCode;

  /// Units of each currency per 1 unit of [baseCurrencyCode].
  final Map<String, double> rates;
  final DateTime fetchedAtUtc;

  double? _rateOf(String currencyCode) {
    if (currencyCode == baseCurrencyCode) return 1;
    return rates[currencyCode];
  }

  /// Converts [amount] from [from] to [to], routed through
  /// [baseCurrencyCode]. Returns null if either currency isn't covered by
  /// this snapshot, so callers can degrade gracefully instead of showing a
  /// wrong number.
  double? convert({
    required double amount,
    required String from,
    required String to,
  }) {
    if (from == to) return amount;
    final fromRate = _rateOf(from);
    final toRate = _rateOf(to);
    if (fromRate == null || toRate == null || fromRate == 0) return null;
    return (amount / fromRate) * toRate;
  }

  @override
  List<Object?> get props => [baseCurrencyCode, rates, fetchedAtUtc];
}
