import 'package:intl/intl.dart';

import '../constants/app_currency.dart';

/// Formats an amount using the given currency's symbol and conventional
/// decimal precision (e.g. Lao Kip is shown with no cents).
abstract final class CurrencyFormatter {
  static String format(double amount, AppCurrency currency) {
    final format = NumberFormat.currency(
      symbol: '${currency.symbol} ',
      decimalDigits: currency.decimalDigits,
    );
    return format.format(amount);
  }
}
