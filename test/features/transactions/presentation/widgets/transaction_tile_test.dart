import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_currency.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/utils/currency_formatter.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:cashly_lao/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('formats a Lao Kip expense without decimal places', (
    tester,
  ) async {
    await tester.pumpWidget(_tile(currencyCode: 'LAK', amount: 90000));

    expect(
      find.text('-${CurrencyFormatter.format(90000, SupportedCurrencies.lak)}'),
      findsOneWidget,
    );
    expect(find.textContaining('.00'), findsNothing);
  });

  testWidgets('uses the source account currency for the amount', (
    tester,
  ) async {
    await tester.pumpWidget(_tile(currencyCode: 'USD', amount: 12.5));

    expect(
      find.text('-${CurrencyFormatter.format(12.5, SupportedCurrencies.usd)}'),
      findsOneWidget,
    );
  });

  testWidgets('keeps the trailing actions within a narrow layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _tile(
        currencyCode: 'LAK',
        amount: 123456789,
        categoryName: 'A very long category name that must truncate safely',
        note: 'A very long note that must not force the row to overflow',
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Material's own default minimum interactive size — deliberately never
    // shrunk on a narrow screen (see TransactionTile._actionButtonSize and
    // this app's 44px minimum touch-target requirement).
    expect(
      tester.getSize(find.byType(IconButton)).width,
      greaterThanOrEqualTo(44),
    );
  });
}

Widget _tile({
  required String currencyCode,
  required double amount,
  String categoryName = 'Food & Dining',
  String note = '',
}) {
  final date = DateTime(2026, 7, 25);
  final account = AccountEntity(
    id: 'account-1',
    name: 'Cash',
    type: AccountType.cash,
    balance: 0,
    currencyCode: currencyCode,
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isArchived: false,
    createdAt: date,
    updatedAt: date,
  );
  final category = CategoryEntity(
    id: 'category-1',
    name: categoryName,
    type: CategoryType.expense,
    icon: AppIconKey.food,
    color: AppColorKey.orange,
    isDefault: false,
    isArchived: false,
    sortOrder: 0,
    createdAt: date,
    updatedAt: date,
  );
  final transaction = TransactionEntity(
    id: 'transaction-1',
    accountId: account.id,
    categoryId: category.id,
    type: TransactionType.expense,
    amount: amount,
    date: date,
    note: note,
    createdAt: date,
    updatedAt: date,
  );

  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: TransactionTile(
        transaction: transaction,
        category: category,
        account: account,
        onTap: () {},
        onDuplicate: () {},
        onDelete: () {},
      ),
    ),
  );
}
