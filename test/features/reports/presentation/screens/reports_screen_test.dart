import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_currency.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/constants/app_language.dart';
import 'package:cashly_lao/core/constants/app_theme_mode.dart';
import 'package:cashly_lao/core/utils/currency_formatter.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/accounts/domain/repositories/account_repository.dart';
import 'package:cashly_lao/features/accounts/presentation/providers/account_providers.dart';
import 'package:cashly_lao/features/auth/domain/entities/user_entity.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_providers.dart';
import 'package:cashly_lao/features/budget/domain/entities/budget_entity.dart';
import 'package:cashly_lao/features/budget/domain/repositories/budget_repository.dart';
import 'package:cashly_lao/features/budget/presentation/providers/budget_providers.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/categories/domain/repositories/category_repository.dart';
import 'package:cashly_lao/features/categories/presentation/providers/category_providers.dart';
import 'package:cashly_lao/features/exchange_rates/domain/entities/exchange_rates.dart';
import 'package:cashly_lao/features/exchange_rates/domain/repositories/exchange_rate_repository.dart';
import 'package:cashly_lao/features/exchange_rates/presentation/providers/exchange_rate_providers.dart';
import 'package:cashly_lao/features/reports/presentation/screens/reports_screen.dart';
import 'package:cashly_lao/features/settings/domain/entities/user_preferences_entity.dart';
import 'package:cashly_lao/features/settings/domain/repositories/user_preferences_repository.dart';
import 'package:cashly_lao/features/settings/presentation/providers/settings_providers.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:cashly_lao/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:cashly_lao/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockBudgetRepository extends Mock implements BudgetRepository {}

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

class _MockExchangeRateRepository extends Mock
    implements ExchangeRateRepository {}

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

  final expenseTransaction = TransactionEntity(
    id: 'txn-expense',
    accountId: 'acc-1',
    categoryId: 'cat-1',
    type: TransactionType.expense,
    amount: 80,
    date: thisMonth,
    note: '',
    createdAt: thisMonth,
    updatedAt: thisMonth,
  );

  testWidgets(
    'renders this month\'s income/expense summary from real activity',
    (tester) async {
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
      ).thenAnswer((_) => Stream.value([expenseTransaction]));
      when(
        () => transactionRepository.watchTransactionsInRange(
          start: any(named: 'start'),
          endExclusive: any(named: 'endExclusive'),
        ),
      ).thenAnswer((_) => Stream.value([expenseTransaction]));
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
            home: ReportsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final currency = SupportedCurrencies.byCode('USD');
      expect(find.text(l10n.incomeExpenseTrendSectionTitle), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(80, currency)), findsWidgets);
    },
  );

  testWidgets(
    'shows a converted rollup card when the report spans multiple currencies',
    (tester) async {
      final accountRepository = _MockAccountRepository();
      final categoryRepository = _MockCategoryRepository();
      final transactionRepository = _MockTransactionRepository();
      final budgetRepository = _MockBudgetRepository();
      final userPreferencesRepository = _MockUserPreferencesRepository();
      final exchangeRateRepository = _MockExchangeRateRepository();

      final lakAccount = AccountEntity(
        id: 'acc-2',
        name: 'Kip Wallet',
        type: AccountType.cash,
        balance: 1000000,
        currencyCode: 'LAK',
        icon: AppIconKey.cash,
        color: AppColorKey.emerald,
        isArchived: false,
        createdAt: thisMonth,
        updatedAt: thisMonth,
      );
      final lakExpense = TransactionEntity(
        id: 'txn-lak-expense',
        accountId: 'acc-2',
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 220000,
        date: thisMonth,
        note: '',
        createdAt: thisMonth,
        updatedAt: thisMonth,
      );

      when(
        () => accountRepository.watchAccounts(
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer((_) => Stream.value([account, lakAccount]));
      when(
        () => categoryRepository.watchCategories(
          type: any(named: 'type'),
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer((_) => Stream.value([category]));
      when(
        () => transactionRepository.watchTransactionsForMonth(any()),
      ).thenAnswer((_) => Stream.value([expenseTransaction, lakExpense]));
      when(
        () => transactionRepository.watchTransactionsInRange(
          start: any(named: 'start'),
          endExclusive: any(named: 'endExclusive'),
        ),
      ).thenAnswer((_) => Stream.value([expenseTransaction, lakExpense]));
      when(
        () => budgetRepository.watchBudgetsForMonth(any()),
      ).thenAnswer((_) => Stream.value(const <BudgetEntity>[]));
      when(() => userPreferencesRepository.watchPreferences()).thenAnswer(
        (_) => Stream.value(
          const UserPreferencesEntity(
            themeMode: AppThemeModePreference.system,
            defaultCurrencyCode: 'USD',
            language: AppLanguage.english,
            appLockEnabled: false,
            notificationsEnabled: false,
          ),
        ),
      );
      final rates = ExchangeRates(
        baseCurrencyCode: 'USD',
        rates: const {'USD': 1, 'LAK': 22000},
        fetchedAtUtc: DateTime.utc(2026, 7, 24),
      );
      when(
        () => exchangeRateRepository.getLatestRates(
          baseCurrencyCode: any(named: 'baseCurrencyCode'),
        ),
      ).thenAnswer((_) async => Right(rates));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider.overrideWithValue(accountRepository),
            categoryRepositoryProvider.overrideWithValue(categoryRepository),
            transactionRepositoryProvider.overrideWithValue(
              transactionRepository,
            ),
            budgetRepositoryProvider.overrideWithValue(budgetRepository),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(
                UserEntity(
                  uid: 'uid-1',
                  email: 'user@example.com',
                  emailVerified: true,
                  createdAt: thisMonth,
                ),
              ),
            ),
            userPreferencesRepositoryProvider.overrideWithValue(
              userPreferencesRepository,
            ),
            exchangeRateRepositoryProvider.overrideWithValue(
              exchangeRateRepository,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ReportsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      // 80 USD + (220000 LAK -> 10 USD) = 90 USD converted expense.
      final usd = SupportedCurrencies.byCode('USD');
      expect(find.text(l10n.convertedTotalsCardTitle), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(90, usd)), findsWidgets);
    },
  );

  testWidgets(
    'shows the detailed transaction list and opens the filter sheet',
    (tester) async {
      // The default test surface is too short to reach the new bottom
      // sections (insights, account breakdown, transaction list) without
      // scrolling; a taller surface avoids relying on a scroll gesture
      // just to make later-list content visible to finders.
      await tester.binding.setSurfaceSize(const Size(500, 2400));
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
      ).thenAnswer((_) => Stream.value([expenseTransaction]));
      when(
        () => transactionRepository.watchTransactionsInRange(
          start: any(named: 'start'),
          endExclusive: any(named: 'endExclusive'),
        ),
      ).thenAnswer((_) => Stream.value([expenseTransaction]));
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
            home: ReportsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      // The detailed transaction list renders the category name (the
      // transaction's title) and its account's name.
      expect(find.text(l10n.transactionsTitle), findsOneWidget);
      expect(find.text('Groceries'), findsWidgets);
      expect(find.text('Cash'), findsWidgets);

      // Opening the filter sheet shows its controls.
      await tester.tap(find.byTooltip(l10n.reportFilterTooltip));
      await tester.pumpAndSettle();

      expect(find.text(l10n.reportFilterSheetTitle), findsOneWidget);
      expect(find.text(l10n.dateRangeFilterLabel), findsOneWidget);
      expect(find.text(l10n.allAccountsLabel), findsOneWidget);
      expect(find.text(l10n.allCategoriesLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
