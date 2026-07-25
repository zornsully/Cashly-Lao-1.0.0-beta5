import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/transaction_sort_option.dart';

/// Localized display label for [TransactionSortOption] — kept in the
/// presentation layer (unlike [TransactionSortOption.label], which is
/// domain-level English) since it needs [AppLocalizations]. Same pattern as
/// `AccountTypeLabel`.
extension TransactionSortOptionLabel on TransactionSortOption {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    TransactionSortOption.dateDesc => l10n.sortDateNewestLabel,
    TransactionSortOption.dateAsc => l10n.sortDateOldestLabel,
    TransactionSortOption.amountDesc => l10n.sortAmountHighLabel,
    TransactionSortOption.amountAsc => l10n.sortAmountLowLabel,
  };
}
