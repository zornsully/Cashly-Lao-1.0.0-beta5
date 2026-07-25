import 'package:equatable/equatable.dart';

/// A currency Cashly can display balances in. The list is intentionally
/// small and centered on the Lao market rather than exhaustive (ISO 4217
/// has ~180 entries); Settings (a later sprint) is where a full picker
/// would live if that's ever needed.
///
/// Equality is by [code] (via [Equatable]) rather than instance identity,
/// so `DropdownButtonFormField<AppCurrency>.initialValue` correctly matches
/// an entry in `items` regardless of which [AppCurrency] instance built it.
class AppCurrency extends Equatable {
  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimalDigits,
  });

  final String code;
  final String symbol;
  final String name;

  /// The Lao Kip and Thai Baht are conventionally quoted without cents in
  /// everyday use, so they default to 0 decimal digits.
  final int decimalDigits;

  @override
  List<Object?> get props => [code];
}

abstract final class SupportedCurrencies {
  static const AppCurrency lak = AppCurrency(
    code: 'LAK',
    symbol: '₭',
    name: 'Lao Kip',
    decimalDigits: 0,
  );

  static const AppCurrency thb = AppCurrency(
    code: 'THB',
    symbol: '฿',
    name: 'Thai Baht',
    decimalDigits: 0,
  );

  static const AppCurrency usd = AppCurrency(
    code: 'USD',
    symbol: r'$',
    name: 'US Dollar',
    decimalDigits: 2,
  );

  static const AppCurrency eur = AppCurrency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    decimalDigits: 2,
  );

  static const AppCurrency cny = AppCurrency(
    code: 'CNY',
    symbol: '¥',
    name: 'Chinese Yuan',
    decimalDigits: 2,
  );

  static const List<AppCurrency> all = [lak, thb, usd, eur, cny];

  static const AppCurrency fallback = lak;

  static AppCurrency byCode(String code) {
    return all.firstWhere((c) => c.code == code, orElse: () => fallback);
  }
}
