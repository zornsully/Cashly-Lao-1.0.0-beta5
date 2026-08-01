import 'account_entity.dart';

/// Currency-safe account totals for the Accounts feature.
///
/// Totals are deliberately never converted or mixed. A negative balance is a
/// liability; only a positive balance can contribute to an asset share.
class AccountCurrencySummary {
  const AccountCurrencySummary({
    required this.currencyCode,
    required this.accounts,
    required this.assets,
    required this.liabilities,
  });

  final String currencyCode;
  final List<AccountEntity> accounts;
  final double assets;
  final double liabilities;

  double get netWorth => assets - liabilities;

  double? assetShareFor(AccountEntity account) =>
      account.balance > 0 && assets > 0 ? account.balance / assets : null;
}

List<AccountCurrencySummary> buildAccountCurrencySummaries(
  List<AccountEntity> accounts,
) {
  final grouped = <String, List<AccountEntity>>{};
  for (final account in accounts) {
    grouped.putIfAbsent(account.currencyCode, () => []).add(account);
  }
  final summaries =
      grouped.entries.map((entry) {
        var assets = 0.0;
        var liabilities = 0.0;
        for (final account in entry.value) {
          if (account.balance >= 0) {
            assets += account.balance;
          } else {
            liabilities += -account.balance;
          }
        }
        return AccountCurrencySummary(
          currencyCode: entry.key,
          accounts: List.unmodifiable(entry.value),
          assets: assets,
          liabilities: liabilities,
        );
      }).toList()..sort(
        (a, b) => _currencyRank(
          a.currencyCode,
        ).compareTo(_currencyRank(b.currencyCode)),
      );
  return List.unmodifiable(summaries);
}

int _currencyRank(String code) => switch (code) {
  'LAK' => 0,
  'USD' => 1,
  _ => 2,
};
