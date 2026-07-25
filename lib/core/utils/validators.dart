import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Shared form-field validators reused across every feature that collects
/// user input (auth, transactions, budgets, etc.). Each returns a
/// user-facing, localized error string, or `null` when the value is valid.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  static String? email(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.emailRequiredError;
    if (!_emailPattern.hasMatch(trimmed)) return l10n.emailInvalidError;
    return null;
  }

  static String? password(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    final input = value ?? '';
    if (input.isEmpty) return l10n.passwordRequiredError;
    if (input.length < 8) return l10n.passwordTooShortError;
    if (!input.contains(RegExp(r'[A-Z]'))) {
      return l10n.passwordNeedsUppercaseError;
    }
    if (!input.contains(RegExp(r'[0-9]'))) {
      return l10n.passwordNeedsNumberError;
    }
    return null;
  }

  static String? confirmPassword(
    BuildContext context,
    String? value,
    String password,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.confirmPasswordRequiredError;
    }
    if (value != password) return l10n.passwordsDoNotMatchError;
    return null;
  }

  static String? displayName(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.nameRequiredError;
    if (trimmed.length < 2) return l10n.nameTooShortError;
    return null;
  }

  /// Generic "this field can't be empty" check for short free-text fields
  /// (account name, category name, budget name, ...). [label] should
  /// already be the localized field name (e.g. `l10n.accountNameLabel`).
  static String? requiredField(
    BuildContext context,
    String? value, {
    required String label,
  }) {
    if ((value ?? '').trim().isNotEmpty) return null;
    return AppLocalizations.of(context)!.fieldRequiredError(label);
  }

  /// Parses a signed decimal amount (negative allowed, e.g. credit card
  /// debt). Returns the error message, or `null` when [value] is a valid
  /// number.
  static String? amount(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.amountRequiredError;
    if (double.tryParse(trimmed) == null) return l10n.amountInvalidError;
    return null;
  }

  /// Parses a strictly-positive decimal amount. Transactions store an
  /// unsigned magnitude and derive the sign from [TransactionType], so
  /// zero and negative entries aren't valid here (unlike [amount], which
  /// allows negative account balances for credit card debt).
  static String? positiveAmount(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.amountRequiredError;
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return l10n.amountInvalidError;
    if (parsed <= 0) return l10n.amountMustBePositiveError;
    return null;
  }
}
