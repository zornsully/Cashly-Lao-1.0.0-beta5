import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/accounts/domain/repositories/account_repository.dart';
import 'package:cashly_lao/features/accounts/presentation/providers/account_providers.dart';
import 'package:cashly_lao/features/budget/domain/entities/budget_entity.dart';
import 'package:cashly_lao/features/budget/domain/repositories/budget_repository.dart';
import 'package:cashly_lao/features/budget/presentation/providers/budget_providers.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/categories/domain/repositories/category_repository.dart';
import 'package:cashly_lao/features/categories/presentation/providers/category_providers.dart';
import 'package:cashly_lao/features/reports/presentation/providers/report_providers.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:cashly_lao/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:cashly_lao/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Flushes pending microtasks until [read] returns a non-null value (each
/// of `monthlyReportProvider`'s several independent stream dependencies
/// needs its own resolution hop, so a single or double flush isn't always
/// enough) — bails out after a generous cap rather than hanging forever if
/// something never resolves.
Future<T> _waitFor<T extends Object>(T? Function() read) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    final value = read();
    if (value != null) return value;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Value never resolved.');
}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  final now = DateTime(2026, 3, 15);

  final accountOne = AccountEntity(
    id: 'acc-1',
    name: 'Cash',
    type: AccountType.cash,
    balance: 0,
    currencyCode: 'LAK',
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
  final accountTwo = AccountEntity(
    id: 'acc-2',
    name: 'Wallet',
    type: AccountType.cash,
    balance: 0,
    currencyCode: 'LAK',
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
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
    createdAt: now,
    updatedAt: now,
  );

  TransactionEntity expense({
    required String id,
    required String accountId,
    required double amount,
    required DateTime date,
  }) {
    return TransactionEntity(
      id: id,
      accountId: accountId,
      categoryId: 'food',
      type: TransactionType.expense,
      amount: amount,
      date: date,
      note: '',
      createdAt: date,
      updatedAt: date,
    );
  }

  late _MockAccountRepository accountRepository;
  late _MockCategoryRepository categoryRepository;
  late _MockTransactionRepository transactionRepository;
  late _MockBudgetRepository budgetRepository;
  late ProviderContainer container;

  setUp(() {
    accountRepository = _MockAccountRepository();
    categoryRepository = _MockCategoryRepository();
    transactionRepository = _MockTransactionRepository();
    budgetRepository = _MockBudgetRepository();

    when(
      () => accountRepository.watchAccounts(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value([accountOne, accountTwo]));
    when(
      () => categoryRepository.watchCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value([food]));
    when(
      () => budgetRepository.watchBudgetsForMonth(any()),
    ).thenAnswer((_) => Stream.value(const <BudgetEntity>[]));
    when(
      () => transactionRepository.watchTransactionsForMonth(any()),
    ).thenAnswer(
      (_) => Stream.value([
        expense(id: 't1', accountId: 'acc-1', amount: 100, date: now),
        expense(id: 't2', accountId: 'acc-2', amount: 50, date: now),
      ]),
    );
    when(
      () => transactionRepository.watchTransactionsInRange(
        start: any(named: 'start'),
        endExclusive: any(named: 'endExclusive'),
      ),
    ).thenAnswer((_) => Stream.value(const <TransactionEntity>[]));

    container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(accountRepository),
        categoryRepositoryProvider.overrideWithValue(categoryRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
        budgetRepositoryProvider.overrideWithValue(budgetRepository),
        selectedReportMonthProvider.overrideWith(
          () => _FixedMonth(DateTime(now.year, now.month)),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'an account filter narrows totals and account breakdown to that account',
    () async {
      container.listen(monthlyReportProvider, (_, _) {});
      final unfiltered = await _waitFor(
        () => container.read(monthlyReportProvider).value,
      );
      expect(unfiltered.totalExpenseByCurrency['LAK'], 150);

      container.read(reportFilterProvider.notifier).setAccountId('acc-1');
      // A Notifier state change recomputes dependent plain Providers
      // synchronously — every other dependency is already resolved by
      // this point, so no further async wait is needed.
      final filtered = container.read(monthlyReportProvider).value!;
      expect(filtered.totalExpenseByCurrency['LAK'], 100);
      expect(filtered.accountBreakdown['LAK'], hasLength(1));
      expect(filtered.accountBreakdown['LAK']!.single.account.id, 'acc-1');
    },
  );

  test('budget progress reflects the whole month even when an account filter '
      'is active', () async {
    when(() => budgetRepository.watchBudgetsForMonth(any())).thenAnswer(
      (_) => Stream.value([
        BudgetEntity(
          id: 'food_2026-03',
          categoryId: 'food',
          month: DateTime(now.year, now.month),
          limitAmount: 1000,
          currencyCode: 'LAK',
          createdAt: now,
          updatedAt: now,
        ),
      ]),
    );

    container.read(reportFilterProvider.notifier).setAccountId('acc-1');
    container.listen(monthlyReportProvider, (_, _) {});
    final report = await _waitFor(
      () => container.read(monthlyReportProvider).value,
    );
    // Both accounts' spend (100 + 50) counts toward the budget, even
    // though the report view itself is filtered to acc-1 only.
    expect(report.budgetProgress.single.spentAmount, 150);
    expect(report.totalExpenseByCurrency['LAK'], 100);
  });

  test('reportFilterProvider clear() resets every field', () {
    final notifier = container.read(reportFilterProvider.notifier);
    notifier.setAccountId('acc-1');
    notifier.setCategoryId('food');
    notifier.setCurrencyCode('LAK');
    notifier.clear();

    final filter = container.read(reportFilterProvider);
    expect(filter.isActive, isFalse);
    expect(filter.accountId, isNull);
    expect(filter.categoryId, isNull);
    expect(filter.currencyCode, isNull);
  });
}

/// A `SelectedReportMonth` stand-in fixed to a given month, so tests don't
/// depend on the wall-clock date the suite happens to run on.
class _FixedMonth extends SelectedReportMonth {
  _FixedMonth(this._month);

  final DateTime _month;

  @override
  DateTime build() => _month;
}
