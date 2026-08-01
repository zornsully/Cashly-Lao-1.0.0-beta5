import 'package:intl/intl.dart';

import '../constants/app_currency.dart';

/// Formats an amount using the given currency's symbol and conventional
/// decimal precision (e.g. Lao Kip is shown with no cents).
abstract final class CurrencyFormatter {
  static String format(double amount, AppCurrency currency) {
    // Format the magnitude separately so the sign consistently precedes the
    // symbol: -₭271,000 and -$271.00. `NumberFormat.currency` places signs
    // differently between locales and also inserts a space after symbols by
    // default, neither of which suits Cashly's compact financial UI.
    final number = NumberFormat.decimalPatternDigits(
      locale: 'en_US',
      decimalDigits: currency.decimalDigits,
    );
    final prefix = amount.isNegative ? '-' : '';
    return '$prefix${currency.symbol}${number.format(amount.abs())}';
  }
}
