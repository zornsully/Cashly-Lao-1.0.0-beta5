import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/financial_insights/domain/usecases/build_financial_insight_snapshots_usecase.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = BuildFinancialInsightSnapshotsUseCase();

  AccountEntity account({
    required String id,
    required String currencyCode,
    required double balance,
    bool isArchived = false,
    DateTime? createdAt,
  }) {
    return AccountEntity(
      id: id,
      name: 'Account $id',
      type: AccountType.cash,
      balance: balance,
      currencyCode: currencyCode,
      icon: AppIconKey.cash,
      color: AppColorKey.emerald,
      isArchived: isArchived,
      createdAt: createdAt ?? DateTime(2026),
      updatedAt: createdAt ?? DateTime(2026),
    );
  }

  test('builds active total balances separately for each currency', () {
    final snapshots = useCase(
      asOf: DateTime(2026, 7, 25),
      transactions: const [],
      accounts: [
        account(id: 'cash', currencyCode: 'LAK', balance: 100000),
        account(id: 'bank', currencyCode: 'LAK', balance: 250000),
        account(
          id: 'old-wallet',
          currencyCode: 'LAK',
          balance: 900000,
          isArchived: true,
        ),
        account(id: 'usd', currencyCode: 'USD', balance: 40),
      ],
      categories: const [],
      budgets: const [],
    );
    final byCurrency = {
      for (final snapshot in snapshots) snapshot.currencyCode: snapshot,
    };

    expect(byCurrency['LAK']!.balance.totalBalance, 350000);
    expect(byCurrency['LAK']!.balance.activeAccountCount, 2);
    expect(byCurrency['USD']!.balance.totalBalance, 40);
    expect(byCurrency['USD']!.balance.activeAccountCount, 1);
  });

  test(
    'marks a cross-currency transfer as unsafe for score reconstruction',
    () {
      final snapshots = useCase(
        asOf: DateTime(2026, 7, 25),
        accounts: [
          account(id: 'lak', currencyCode: 'LAK', balance: 700000),
          account(id: 'usd', currencyCode: 'USD', balance: 130),
        ],
        transactions: [
          TransactionEntity(
            id: 'transfer',
            accountId: 'lak',
            toAccountId: 'usd',
            type: TransactionType.transfer,
            amount: 100000,
            date: DateTime(2026, 7, 20),
            note: '',
            createdAt: DateTime(2026, 7, 20),
            updatedAt: DateTime(2026, 7, 20),
          ),
        ],
        categories: const [],
        budgets: const [],
      );
      final byCurrency = {
        for (final snapshot in snapshots) snapshot.currencyCode: snapshot,
      };

      expect(byCurrency['LAK']!.balance.hasCrossCurrencyTransfer, isTrue);
      expect(byCurrency['USD']!.balance.hasCrossCurrencyTransfer, isTrue);
    },
  );

  test(
    'marks an account created in the current month as unreconstructable',
    () {
      final snapshots = useCase(
        asOf: DateTime(2026, 7, 25),
        accounts: [
          AccountEntity(
            id: 'new',
            name: 'New account',
            type: AccountType.cash,
            balance: 500000,
            currencyCode: 'LAK',
            icon: AppIconKey.cash,
            color: AppColorKey.emerald,
            isArchived: false,
            createdAt: DateTime(2026, 7, 2),
            updatedAt: DateTime(2026, 7, 2),
          ),
        ],
        transactions: const [],
        categories: const [],
        budgets: const [],
      );

      expect(snapshots.single.balance.hasAccountCreatedThisMonth, isTrue);
    },
  );

  test('does not carry a prior-month currency transfer into this month', () {
    final snapshots = useCase(
      asOf: DateTime(2026, 7, 25),
      accounts: [
        account(id: 'lak', currencyCode: 'LAK', balance: 700000),
        account(id: 'usd', currencyCode: 'USD', balance: 130),
      ],
      transactions: [
        TransactionEntity(
          id: 'old-transfer',
          accountId: 'lak',
          toAccountId: 'usd',
          type: TransactionType.transfer,
          amount: 100000,
          date: DateTime(2026, 6, 20),
          note: '',
          createdAt: DateTime(2026, 6, 20),
          updatedAt: DateTime(2026, 6, 20),
        ),
      ],
      categories: const [],
      budgets: const [],
    );
    final byCurrency = {
      for (final snapshot in snapshots) snapshot.currencyCode: snapshot,
    };

    expect(byCurrency['LAK']!.balance.hasCrossCurrencyTransfer, isFalse);
    expect(byCurrency['USD']!.balance.hasCrossCurrencyTransfer, isFalse);
  });

  test('keeps an internal same-currency transfer out of score movement', () {
    final snapshots = useCase(
      asOf: DateTime(2026, 7, 25),
      accounts: [
        account(id: 'cash', currencyCode: 'LAK', balance: 700000),
        account(id: 'bank', currencyCode: 'LAK', balance: 300000),
      ],
      transactions: [
        TransactionEntity(
          id: 'transfer',
          accountId: 'cash',
          toAccountId: 'bank',
          type: TransactionType.transfer,
          amount: 100000,
          date: DateTime(2026, 7, 20),
          note: '',
          createdAt: DateTime(2026, 7, 20),
          updatedAt: DateTime(2026, 7, 20),
        ),
      ],
      categories: const [],
      budgets: const [],
    );

    expect(snapshots.single.balance.totalBalance, 1000000);
    expect(snapshots.single.balance.hasCrossCurrencyTransfer, isFalse);
    expect(snapshots.single.balance.hasCrossCurrencyTransferToday, isFalse);
    expect(snapshots.single.balance.hasCrossCurrencyTransferThisWeek, isFalse);
    expect(snapshots.single.month.income, 0);
    expect(snapshots.single.month.expense, 0);
  });

  test('tracks cross-currency safety separately for today and this week', () {
    final snapshots = useCase(
      asOf: DateTime(2026, 7, 25),
      accounts: [
        account(id: 'lak', currencyCode: 'LAK', balance: 700000),
        account(id: 'usd', currencyCode: 'USD', balance: 130),
      ],
      transactions: [
        TransactionEntity(
          id: 'earlier-this-week',
          accountId: 'lak',
          toAccountId: 'usd',
          type: TransactionType.transfer,
          amount: 100000,
          date: DateTime(2026, 7, 24),
          note: '',
          createdAt: DateTime(2026, 7, 24),
          updatedAt: DateTime(2026, 7, 24),
        ),
      ],
      categories: const [],
      budgets: const [],
    );
    final lak = snapshots.firstWhere(
      (snapshot) => snapshot.currencyCode == 'LAK',
    );

    expect(lak.balance.hasCrossCurrencyTransfer, isTrue);
    expect(lak.balance.hasCrossCurrencyTransferThisWeek, isTrue);
    expect(lak.balance.hasCrossCurrencyTransferToday, isFalse);
  });

  test('tracks account additions against each derived score window', () {
    final snapshots = useCase(
      asOf: DateTime(2026, 7, 25),
      accounts: [
        account(
          id: 'added-this-week',
          currencyCode: 'LAK',
          balance: 500000,
          createdAt: DateTime(2026, 7, 22),
        ),
      ],
      transactions: const [],
      categories: const [],
      budgets: const [],
    );

    final balance = snapshots.single.balance;
    expect(balance.hasAccountCreatedThisMonth, isTrue);
    expect(balance.hasAccountCreatedThisWeek, isTrue);
    expect(balance.hasAccountCreatedToday, isFalse);
  });
}
