import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/reports/domain/entities/expense_watch_item.dart';
import 'package:cashly_lao/features/reports/domain/usecases/detect_expense_watch_usecase.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = DetectExpenseWatchUseCase();

  final account = AccountEntity(
    id: 'acc-1',
    name: 'Cash',
    type: AccountType.cash,
    balance: 0,
    currencyCode: 'LAK',
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isArchived: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  final food = CategoryEntity(
    id: 'food',
    name: 'Food',
    type: CategoryType.expense,
    icon: AppIconKey.other,
    color: AppColorKey.grey,
    isDefault: false,
    isArchived: false,
    sortOrder: 0,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  TransactionEntity expense({
    required String id,
    required double amount,
    required DateTime date,
    String categoryId = 'food',
    String accountId = 'acc-1',
  }) {
    return TransactionEntity(
      id: id,
      accountId: accountId,
      categoryId: categoryId,
      type: TransactionType.expense,
      amount: amount,
      date: date,
      note: '',
      createdAt: date,
      updatedAt: date,
    );
  }

  group('large expense', () {
    test('flags a transaction well above its category trailing average', () {
      final trailing = [
        expense(id: 't1', amount: 100, date: DateTime(2026, 2, 1)),
        expense(id: 't2', amount: 100, date: DateTime(2026, 2, 10)),
      ];
      final current = [
        expense(id: 't3', amount: 250, date: DateTime(2026, 3, 5)),
      ];

      final items = useCase(
        currentPeriodTransactions: current,
        trailingTransactions: trailing,
        trailingPeriodCount: 1,
        accounts: [account],
        categories: [food],
      );

      final large = items.whereType<LargeExpenseWatchItem>();
      expect(large, hasLength(1));
      expect(large.single.transaction.id, 't3');
      expect(large.single.categoryAverageAmount, 100);
    });

    test('does not flag when there are too few trailing samples', () {
      final trailing = [
        expense(id: 't1', amount: 100, date: DateTime(2026, 2, 1)),
      ];
      final current = [
        expense(id: 't2', amount: 250, date: DateTime(2026, 3, 5)),
      ];

      final items = useCase(
        currentPeriodTransactions: current,
        trailingTransactions: trailing,
        trailingPeriodCount: 1,
        accounts: [account],
        categories: [food],
      );

      expect(items.whereType<LargeExpenseWatchItem>(), isEmpty);
    });

    test('does not flag an amount under the large-expense multiplier', () {
      final trailing = [
        expense(id: 't1', amount: 100, date: DateTime(2026, 2, 1)),
        expense(id: 't2', amount: 100, date: DateTime(2026, 2, 10)),
      ];
      final current = [
        expense(id: 't3', amount: 150, date: DateTime(2026, 3, 5)),
      ];

      final items = useCase(
        currentPeriodTransactions: current,
        trailingTransactions: trailing,
        trailingPeriodCount: 1,
        accounts: [account],
        categories: [food],
      );

      expect(items.whereType<LargeExpenseWatchItem>(), isEmpty);
    });
  });

  group('repeated expense', () {
    test('flags two same-amount transactions within the repeat window', () {
      final current = [
        expense(id: 't1', amount: 75, date: DateTime(2026, 3, 5)),
        expense(id: 't2', amount: 75, date: DateTime(2026, 3, 6)),
      ];

      final items = useCase(
        currentPeriodTransactions: current,
        trailingTransactions: const [],
        trailingPeriodCount: 1,
        accounts: [account],
        categories: [food],
      );

      final repeated = items.whereType<RepeatedExpenseWatchItem>();
      expect(repeated, hasLength(1));
      expect(repeated.single.transactions.map((t) => t.id), ['t1', 't2']);
      expect(repeated.single.amount, 75);
    });

    test('does not flag transactions outside the repeat window', () {
      final current = [
        expense(id: 't1', amount: 75, date: DateTime(2026, 3, 1)),
        expense(id: 't2', amount: 75, date: DateTime(2026, 3, 10)),
      ];

      final items = useCase(
        currentPeriodTransactions: current,
        trailingTransactions: const [],
        trailingPeriodCount: 1,
        accounts: [account],
        categories: [food],
      );

      expect(items.whereType<RepeatedExpenseWatchItem>(), isEmpty);
    });

    test('does not flag transactions with different amounts', () {
      final current = [
        expense(id: 't1', amount: 75, date: DateTime(2026, 3, 5)),
        expense(id: 't2', amount: 80, date: DateTime(2026, 3, 6)),
      ];

      final items = useCase(
        currentPeriodTransactions: current,
        trailingTransactions: const [],
        trailingPeriodCount: 1,
        accounts: [account],
        categories: [food],
      );

      expect(items.whereType<RepeatedExpenseWatchItem>(), isEmpty);
    });
  });

  group('rising category', () {
    test('flags a category spending well above its trailing average', () {
      final trailing = [
        expense(id: 't1', amount: 300, date: DateTime(2026, 1, 15)),
      ];
      final current = [
        expense(id: 't2', amount: 200, date: DateTime(2026, 3, 5)),
      ];

      final items = useCase(
        currentPeriodTransactions: current,
        trailingTransactions: trailing,
        trailingPeriodCount: 3,
        accounts: [account],
        categories: [food],
      );

      final rising = items.whereType<RisingCategoryWatchItem>();
      expect(rising, hasLength(1));
      expect(rising.single.category.id, 'food');
      expect(rising.single.averageAmount, 100);
      expect(rising.single.currentAmount, 200);
      expect(rising.single.percentIncrease, 100);
    });

    test('does not flag when trailingPeriodCount is zero or negative', () {
      final trailing = [
        expense(id: 't1', amount: 300, date: DateTime(2026, 1, 15)),
      ];
      final current = [
        expense(id: 't2', amount: 200, date: DateTime(2026, 3, 5)),
      ];

      final items = useCase(
        currentPeriodTransactions: current,
        trailingTransactions: trailing,
        trailingPeriodCount: 0,
        accounts: [account],
        categories: [food],
      );

      expect(items.whereType<RisingCategoryWatchItem>(), isEmpty);
    });

    test('does not flag a category with no trailing history at all', () {
      final current = [
        expense(id: 't1', amount: 500, date: DateTime(2026, 3, 5)),
      ];

      final items = useCase(
        currentPeriodTransactions: current,
        trailingTransactions: const [],
        trailingPeriodCount: 3,
        accounts: [account],
        categories: [food],
      );

      expect(items.whereType<RisingCategoryWatchItem>(), isEmpty);
    });
  });

  test('excludes transactions whose account no longer exists', () {
    final current = [
      expense(
        id: 't1',
        amount: 500,
        date: DateTime(2026, 3, 5),
        accountId: 'gone',
      ),
    ];

    final items = useCase(
      currentPeriodTransactions: current,
      trailingTransactions: const [],
      trailingPeriodCount: 3,
      accounts: [account],
      categories: [food],
    );

    expect(items, isEmpty);
  });

  test('ignores income and transfer transactions entirely', () {
    final income = TransactionEntity(
      id: 'income-1',
      accountId: 'acc-1',
      categoryId: 'food',
      type: TransactionType.income,
      amount: 1000000,
      date: DateTime(2026, 3, 5),
      note: '',
      createdAt: DateTime(2026, 3, 5),
      updatedAt: DateTime(2026, 3, 5),
    );

    final items = useCase(
      currentPeriodTransactions: [income],
      trailingTransactions: const [],
      trailingPeriodCount: 3,
      accounts: [account],
      categories: [food],
    );

    expect(items, isEmpty);
  });
}
