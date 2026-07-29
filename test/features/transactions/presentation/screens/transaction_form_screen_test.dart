import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/accounts/domain/repositories/account_repository.dart';
import 'package:cashly_lao/features/accounts/presentation/providers/account_providers.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/categories/domain/repositories/category_repository.dart';
import 'package:cashly_lao/features/categories/presentation/providers/category_providers.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:cashly_lao/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:cashly_lao/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:cashly_lao/features/transactions/presentation/screens/transaction_form_screen.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

void main() {
  late _MockAccountRepository accountRepository;
  late _MockCategoryRepository categoryRepository;
  late _MockTransactionRepository transactionRepository;

  final now = DateTime(2026, 7, 15);

  final account = AccountEntity(
    id: 'acc-1',
    name: 'Cash',
    type: AccountType.cash,
    balance: 100,
    currencyCode: 'USD',
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
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
    createdAt: now,
    updatedAt: now,
  );

  final transaction = TransactionEntity(
    id: 'txn-1',
    accountId: 'acc-1',
    categoryId: 'cat-1',
    type: TransactionType.expense,
    amount: 25.5,
    date: now,
    note: '',
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(TransactionType.expense);
    registerFallbackValue(CategoryType.expense);
  });

  setUp(() {
    accountRepository = _MockAccountRepository();
    categoryRepository = _MockCategoryRepository();
    transactionRepository = _MockTransactionRepository();

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
  });

  Future<void> pumpTransactionForm(WidgetTester tester) async {
    // TransactionFormScreen pops via go_router's context.pop() on success,
    // which throws "No GoRouter found in context" under a plain
    // MaterialApp — route it through a real (if minimal) GoRouter instead,
    // with a placeholder root so there's somewhere to pop back to.
    final router = GoRouter(
      initialLocation: '/form',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, _) => const TransactionFormScreen(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(accountRepository),
          categoryRepositoryProvider.overrideWithValue(categoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'fills in amount, account, and category, then creates the expense '
    'transaction',
    (tester) async {
      when(
        () => transactionRepository.createTransaction(
          accountId: 'acc-1',
          categoryId: 'cat-1',
          type: TransactionType.expense,
          toAccountId: null,
          amount: 25.5,
          date: any(named: 'date'),
          note: '',
        ),
      ).thenAnswer((_) async => Right(transaction));

      await pumpTransactionForm(tester);

      await tester.enterText(find.byType(TextFormField).first, '25.50');

      await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Groceries').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add transaction'));
      await tester.pumpAndSettle();

      verify(
        () => transactionRepository.createTransaction(
          accountId: 'acc-1',
          categoryId: 'cat-1',
          type: TransactionType.expense,
          toAccountId: null,
          amount: 25.5,
          date: any(named: 'date'),
          note: '',
        ),
      ).called(1);
    },
  );

  testWidgets(
    'never calls the repository when no account or category is selected',
    (tester) async {
      await pumpTransactionForm(tester);

      await tester.enterText(find.byType(TextFormField).first, '25.50');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add transaction'));
      await tester.pumpAndSettle();

      verifyNever(
        () => transactionRepository.createTransaction(
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
          type: any(named: 'type'),
          toAccountId: any(named: 'toAccountId'),
          amount: any(named: 'amount'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      );
    },
  );
}
