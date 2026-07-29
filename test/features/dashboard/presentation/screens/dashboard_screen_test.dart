import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_currency.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/utils/currency_formatter.dart';
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
import 'package:cashly_lao/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:cashly_lao/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:cashly_lao/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  final now = DateTime.now();
  final thisMonth = DateTime(now.year, now.month, 15);

  final account = AccountEntity(
    id: 'acc-1',
    name: 'Cash',
    type: AccountType.cash,
    balance: 500,
    currencyCode: 'USD',
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isArchived: false,
    createdAt: thisMonth,
    updatedAt: thisMonth,
  );

  final category = CategoryEntity(
    id: 'cat-1',
    name: 'Groceries',
    type: CategoryType.expense,
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isDefault: false,
    isArchived: false,
    sortOrder: 0,
    createdAt: thisMonth,
    updatedAt: thisMonth,
  );

  final incomeTransaction = TransactionEntity(
    id: 'txn-income',
    accountId: 'acc-1',
    categoryId: 'cat-1',
    type: TransactionType.income,
    amount: 200,
    date: thisMonth,
    note: '',
    createdAt: thisMonth,
    updatedAt: thisMonth,
  );

  final expenseTransaction = TransactionEntity(
    id: 'txn-expense',
    accountId: 'acc-1',
    categoryId: 'cat-1',
    type: TransactionType.expense,
    amount: 50,
    date: thisMonth,
    note: '',
    createdAt: thisMonth,
    updatedAt: thisMonth,
  );

  testWidgets(
    'uses a four-card desktop dashboard without changing live totals',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final accountRepository = _MockAccountRepository();
      final categoryRepository = _MockCategoryRepository();
      final transactionRepository = _MockTransactionRepository();
      final budgetRepository = _MockBudgetRepository();

      when(
        () => accountRepository.watchAccounts(
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer((_) => Stream.value([account]));
      when(
        () => categoryRepository.watchCategories(
          type: any(named: 'type'),
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer((_) => Stream.value([category]));
      when(
        () => transactionRepository.watchTransactionsForMonth(any()),
      ).thenAnswer(
        (_) => Stream.value([expenseTransaction, incomeTransaction]),
      );
      when(
        () => transactionRepository.watchTransactionsInRange(
          start: any(named: 'start'),
          endExclusive: any(named: 'endExclusive'),
        ),
      ).thenAnswer(
        (_) => Stream.value([expenseTransaction, incomeTransaction]),
      );
      when(
        () => budgetRepository.watchBudgetsForMonth(any()),
      ).thenAnswer((_) => Stream.value(const <BudgetEntity>[]));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider.overrideWithValue(accountRepository),
            categoryRepositoryProvider.overrideWithValue(categoryRepository),
            transactionRepositoryProvider.overrideWithValue(
              transactionRepository,
            ),
            budgetRepositoryProvider.overrideWithValue(budgetRepository),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final currency = SupportedCurrencies.byCode('USD');
      expect(find.text(CurrencyFormatter.format(500, currency)), findsWidgets);
      expect(find.text(CurrencyFormatter.format(200, currency)), findsWidgets);
      expect(find.text(CurrencyFormatter.format(50, currency)), findsWidgets);
      expect(find.text('Total balance'), findsOneWidget);
      expect(find.text('Monthly income'), findsOneWidget);
      expect(find.text('Monthly expenses'), findsOneWidget);
      expect(find.text('Net cash flow'), findsOneWidget);
      expect(find.text('Income & expenses'), findsOneWidget);
      expect(find.text('Add income'), findsOneWidget);
      expect(find.text('Add expense'), findsOneWidget);
      expect(find.text('Transfer money'), findsOneWidget);
      expect(find.text('Create budget'), findsOneWidget);

      final balancePosition = tester.getTopLeft(find.text('Total balance'));
      final incomePosition = tester.getTopLeft(find.text('Monthly income'));
      final expensePosition = tester.getTopLeft(find.text('Monthly expenses'));
      final netPosition = tester.getTopLeft(find.text('Net cash flow'));
      expect(balancePosition.dy, incomePosition.dy);
      expect(incomePosition.dy, expensePosition.dy);
      expect(expensePosition.dy, netPosition.dy);

      await tester.binding.setSurfaceSize(const Size(900, 900));
      await tester.pump();

      final tabletBalance = tester.getTopLeft(find.text('Total balance'));
      final tabletIncome = tester.getTopLeft(find.text('Monthly income'));
      final tabletExpense = tester.getTopLeft(find.text('Monthly expenses'));
      final tabletNet = tester.getTopLeft(find.text('Net cash flow'));
      expect(tabletBalance.dy, tabletIncome.dy);
      expect(tabletExpense.dy, greaterThan(tabletIncome.dy));
      expect(tabletExpense.dy, tabletNet.dy);
    },
  );
}
