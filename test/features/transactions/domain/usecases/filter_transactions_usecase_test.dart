import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_filter.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_sort_option.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:cashly_lao/features/transactions/domain/usecases/filter_transactions_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = FilterTransactionsUseCase();

  final cashAccount = AccountEntity(
    id: 'acc-cash',
    name: 'Cash Wallet',
    type: AccountType.cash,
    balance: 0,
    currencyCode: 'LAK',
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isArchived: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final bankAccount = AccountEntity(
    id: 'acc-bank',
    name: 'Bank Account',
    type: AccountType.bank,
    balance: 0,
    currencyCode: 'LAK',
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isArchived: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final groceriesCategory = CategoryEntity(
    id: 'cat-groceries',
    name: 'Groceries',
    type: CategoryType.expense,
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isDefault: false,
    isArchived: false,
    sortOrder: 0,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final salaryCategory = CategoryEntity(
    id: 'cat-salary',
    name: 'Salary',
    type: CategoryType.income,
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isDefault: false,
    isArchived: false,
    sortOrder: 0,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final accounts = [cashAccount, bankAccount];
  final categories = [groceriesCategory, salaryCategory];

  TransactionEntity transaction({
    required String id,
    required TransactionType type,
    required double amount,
    required DateTime date,
    String accountId = 'acc-cash',
    String? categoryId,
    String? toAccountId,
    String note = '',
  }) {
    return TransactionEntity(
      id: id,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      toAccountId: toAccountId,
      amount: amount,
      date: date,
      note: note,
      createdAt: date,
      updatedAt: date,
    );
  }

  final groceries = transaction(
    id: 'txn-groceries',
    type: TransactionType.expense,
    amount: 50000,
    date: DateTime(2026, 3, 1),
    categoryId: 'cat-groceries',
    note: 'Weekly shop',
  );

  final salary = transaction(
    id: 'txn-salary',
    type: TransactionType.income,
    amount: 2000000,
    date: DateTime(2026, 3, 10),
    accountId: 'acc-bank',
    categoryId: 'cat-salary',
  );

  final transfer = transaction(
    id: 'txn-transfer',
    type: TransactionType.transfer,
    amount: 100000,
    date: DateTime(2026, 3, 5),
    accountId: 'acc-cash',
    toAccountId: 'acc-bank',
  );

  final all = [groceries, salary, transfer];

  test('with no filter, returns everything sorted newest-first (default)', () {
    final result = useCase(
      transactions: all,
      accounts: accounts,
      categories: categories,
      filter: const TransactionFilter(),
    );

    expect(result.map((t) => t.id), [salary.id, transfer.id, groceries.id]);
  });

  test('filters by type', () {
    final result = useCase(
      transactions: all,
      accounts: accounts,
      categories: categories,
      filter: const TransactionFilter(type: TransactionType.transfer),
    );

    expect(result, [transfer]);
  });

  test('filters by account, matching either side of a transfer', () {
    final result = useCase(
      transactions: all,
      accounts: accounts,
      categories: categories,
      filter: const TransactionFilter(accountId: 'acc-bank'),
    );

    expect(result.map((t) => t.id), containsAll([salary.id, transfer.id]));
    expect(result, isNot(contains(groceries)));
  });

  test('filters by category', () {
    final result = useCase(
      transactions: all,
      accounts: accounts,
      categories: categories,
      filter: const TransactionFilter(categoryId: 'cat-groceries'),
    );

    expect(result, [groceries]);
  });

  test('search matches the note, case-insensitively', () {
    final result = useCase(
      transactions: all,
      accounts: accounts,
      categories: categories,
      filter: const TransactionFilter(searchQuery: 'WEEKLY'),
    );

    expect(result, [groceries]);
  });

  test('search matches the category name', () {
    final result = useCase(
      transactions: all,
      accounts: accounts,
      categories: categories,
      filter: const TransactionFilter(searchQuery: 'salary'),
    );

    expect(result, [salary]);
  });

  test('search matches either account name on a transfer', () {
    final result = useCase(
      transactions: all,
      accounts: accounts,
      categories: categories,
      filter: const TransactionFilter(searchQuery: 'bank'),
    );

    // Salary is on the bank account too, and the transfer touches it as
    // its destination — both should match "bank".
    expect(result.map((t) => t.id), containsAll([salary.id, transfer.id]));
  });

  test('sorts by amount ascending', () {
    final result = useCase(
      transactions: all,
      accounts: accounts,
      categories: categories,
      filter: const TransactionFilter(
        sortOption: TransactionSortOption.amountAsc,
      ),
    );

    expect(result.map((t) => t.id), [groceries.id, transfer.id, salary.id]);
  });

  test('sorts by date ascending', () {
    final result = useCase(
      transactions: all,
      accounts: accounts,
      categories: categories,
      filter: const TransactionFilter(
        sortOption: TransactionSortOption.dateAsc,
      ),
    );

    expect(result.map((t) => t.id), [groceries.id, transfer.id, salary.id]);
  });

  test('combines a type filter with search', () {
    final result = useCase(
      transactions: all,
      accounts: accounts,
      categories: categories,
      filter: const TransactionFilter(
        type: TransactionType.expense,
        searchQuery: 'weekly',
      ),
    );

    expect(result, [groceries]);
  });

  test('TransactionFilter.isActive is false only for the default filter', () {
    expect(const TransactionFilter().isActive, isFalse);
    expect(const TransactionFilter(searchQuery: 'x').isActive, isTrue);
    expect(const TransactionFilter(accountId: 'a').isActive, isTrue);
    expect(const TransactionFilter(categoryId: 'c').isActive, isTrue);
    expect(
      const TransactionFilter(type: TransactionType.income).isActive,
      isTrue,
    );
    // Sort option alone doesn't count as an active filter — it doesn't
    // narrow the result set.
    expect(
      const TransactionFilter(
        sortOption: TransactionSortOption.amountAsc,
      ).isActive,
      isFalse,
    );
  });
}
