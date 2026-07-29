import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/constants/app_symbols.dart';
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
import 'package:cashly_lao/features/transactions/presentation/screens/transactions_list_screen.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

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

  final groceriesCategory = CategoryEntity(
    id: 'cat-groceries',
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

  final transportCategory = CategoryEntity(
    id: 'cat-transport',
    name: 'Transport',
    type: CategoryType.expense,
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isDefault: false,
    isArchived: false,
    sortOrder: 1,
    createdAt: thisMonth,
    updatedAt: thisMonth,
  );

  final groceriesTxn = TransactionEntity(
    id: 'txn-groceries',
    accountId: 'acc-1',
    categoryId: 'cat-groceries',
    type: TransactionType.expense,
    amount: 50,
    date: thisMonth,
    note: '',
    createdAt: thisMonth,
    updatedAt: thisMonth,
  );

  final transportTxn = TransactionEntity(
    id: 'txn-transport',
    accountId: 'acc-1',
    categoryId: 'cat-transport',
    type: TransactionType.expense,
    amount: 20,
    date: thisMonth,
    note: '',
    createdAt: thisMonth,
    updatedAt: thisMonth,
  );

  testWidgets('typing in search narrows the list to matching transactions', (
    tester,
  ) async {
    final accountRepository = _MockAccountRepository();
    final categoryRepository = _MockCategoryRepository();
    final transactionRepository = _MockTransactionRepository();

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
    ).thenAnswer((_) => Stream.value([groceriesCategory, transportCategory]));
    when(
      () => transactionRepository.watchTransactionsForMonth(any()),
    ).thenAnswer((_) => Stream.value([groceriesTxn, transportTxn]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(accountRepository),
          categoryRepositoryProvider.overrideWithValue(categoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TransactionsListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);

    await tester.tap(find.byIcon(AppSymbols.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'grocer');
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Transport'), findsNothing);
  });
}
