import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/reports/domain/usecases/build_monthly_trend_usecase.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = BuildMonthlyTrendUseCase();

  AccountEntity account({required String id, required String currencyCode}) {
    return AccountEntity(
      id: id,
      name: 'Account $id',
      type: AccountType.cash,
      balance: 0,
      currencyCode: currencyCode,
      icon: AppIconKey.cash,
      color: AppColorKey.emerald,
      isArchived: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  TransactionEntity transaction({
    required String id,
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
  }) {
    return TransactionEntity(
      id: id,
      accountId: accountId,
      categoryId: 'cat-1',
      type: type,
      amount: amount,
      date: date,
      note: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  test('produces one point per month, oldest first, ending at endMonth', () {
    final points = useCase(
      endMonth: DateTime(2026, 3),
      monthCount: 3,
      transactions: const [],
      accounts: const [],
    );

    expect(points, hasLength(3));
    expect(points.map((p) => p.month), [
      DateTime(2026, 1),
      DateTime(2026, 2),
      DateTime(2026, 3),
    ]);
  });

  test('buckets income and expense per currency into the right month', () {
    final accounts = [account(id: 'acc-1', currencyCode: 'LAK')];
    final transactions = [
      transaction(
        id: 't1',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: 1000,
        date: DateTime(2026, 2, 5),
      ),
      transaction(
        id: 't2',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: 200,
        date: DateTime(2026, 2, 20),
      ),
      transaction(
        id: 't3',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: 50,
        date: DateTime(2026, 3, 1),
      ),
    ];

    final points = useCase(
      endMonth: DateTime(2026, 3),
      monthCount: 3,
      transactions: transactions,
      accounts: accounts,
    );

    final feb = points.firstWhere((p) => p.month == DateTime(2026, 2));
    final mar = points.firstWhere((p) => p.month == DateTime(2026, 3));
    final jan = points.firstWhere((p) => p.month == DateTime(2026, 1));

    expect(feb.totalIncomeByCurrency, {'LAK': 1000});
    expect(feb.totalExpenseByCurrency, {'LAK': 200});
    expect(mar.totalExpenseByCurrency, {'LAK': 50});
    expect(jan.totalIncomeByCurrency, isEmpty);
    expect(jan.totalExpenseByCurrency, isEmpty);
  });

  test('excludes transactions whose account no longer exists', () {
    final transactions = [
      transaction(
        id: 'orphan',
        accountId: 'deleted-account',
        type: TransactionType.expense,
        amount: 999,
        date: DateTime(2026, 3, 1),
      ),
    ];

    final points = useCase(
      endMonth: DateTime(2026, 3),
      monthCount: 1,
      transactions: transactions,
      accounts: const [],
    );

    expect(points.single.totalExpenseByCurrency, isEmpty);
  });

  test('excludes transactions outside the requested window', () {
    final accounts = [account(id: 'acc-1', currencyCode: 'LAK')];
    final transactions = [
      transaction(
        id: 'too-old',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: 100,
        date: DateTime(2025, 12, 15),
      ),
    ];

    final points = useCase(
      endMonth: DateTime(2026, 3),
      monthCount: 3,
      transactions: transactions,
      accounts: accounts,
    );

    expect(points.every((p) => p.totalExpenseByCurrency.isEmpty), isTrue);
  });

  test('does not count an own-account transfer as an expense', () {
    final points = useCase(
      endMonth: DateTime(2026, 3),
      monthCount: 1,
      accounts: [account(id: 'acc-1', currencyCode: 'LAK')],
      transactions: [
        transaction(
          id: 'transfer',
          accountId: 'acc-1',
          type: TransactionType.transfer,
          amount: 500,
          date: DateTime(2026, 3, 10),
        ),
      ],
    );

    expect(points.single.totalIncomeByCurrency, isEmpty);
    expect(points.single.totalExpenseByCurrency, isEmpty);
  });
}
