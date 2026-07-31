import '../../../accounts/domain/entities/account_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../entities/account_spending.dart';

/// Pure aggregation — no repository dependency, same reasoning as
/// `ComputeCategorySpendingUseCase`, one level up: expenses grouped by
/// *account* instead of category, per currency, with percentages.
class BuildAccountBreakdownUseCase {
  const BuildAccountBreakdownUseCase();

  Map<String, List<AccountSpending>> call({
    required List<TransactionEntity> transactions,
    required List<AccountEntity> accounts,
  }) {
    final accountsById = {for (final account in accounts) account.id: account};

    final totalExpenseByCurrency = <String, double>{};
    // currency -> accountId -> amount
    final expenseByAccountAndCurrency = <String, Map<String, double>>{};

    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense) continue;
      final account = accountsById[transaction.accountId];
      if (account == null) continue;
      final currency = account.currencyCode;

      totalExpenseByCurrency.update(
        currency,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
      final byAccount = expenseByAccountAndCurrency.putIfAbsent(
        currency,
        () => <String, double>{},
      );
      byAccount.update(
        account.id,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final breakdown = <String, List<AccountSpending>>{};
    for (final entry in expenseByAccountAndCurrency.entries) {
      final currency = entry.key;
      final totalExpense = totalExpenseByCurrency[currency] ?? 0;

      final spendings = <AccountSpending>[
        for (final accountEntry in entry.value.entries)
          if (accountsById[accountEntry.key] case final account?)
            AccountSpending(
              account: account,
              amount: accountEntry.value,
              percentageOfExpense: totalExpense == 0
                  ? 0
                  : (accountEntry.value / totalExpense) * 100,
            ),
      ]..sort((a, b) => b.amount.compareTo(a.amount));

      breakdown[currency] = spendings;
    }

    return breakdown;
  }
}
