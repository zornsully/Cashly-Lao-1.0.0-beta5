import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/account_type.dart';

/// Localized display label for [AccountType] — kept in the presentation
/// layer (unlike [AccountType.label], which is domain-level English used
/// for cases that don't have a `BuildContext`, e.g. logs) since it needs
/// [AppLocalizations].
extension AccountTypeLabel on AccountType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    AccountType.cash => l10n.accountTypeCashLabel,
    AccountType.wallet => l10n.accountTypeWalletLabel,
    AccountType.bank => l10n.accountTypeBankLabel,
    AccountType.creditCard => l10n.accountTypeCreditCardLabel,
    AccountType.savings => l10n.accountTypeSavingsLabel,
  };
}
