import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/reports/domain/usecases/export_transactions_to_csv_usecase.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = ExportTransactionsToCsvUseCase();
  final now = DateTime(2026, 8, 4, 12, 30);
  final account = AccountEntity(
    id: 'cash', name: 'Cash', type: AccountType.cash, balance: 0,
    currencyCode: 'LAK', icon: AppIconKey.cash, color: AppColorKey.emerald,
    isArchived: false, createdAt: now, updatedAt: now,
  );
  final category = CategoryEntity(
    id: 'food', name: 'Food, drinks', type: CategoryType.expense,
    icon: AppIconKey.other, color: AppColorKey.grey, isDefault: false,
    isArchived: false, sortOrder: 0, createdAt: now, updatedAt: now,
  );

  test('exports one UTF-8-safe row per real transaction with numeric amount', () {
    final transaction = TransactionEntity(
      id: 'TX001', accountId: account.id, categoryId: category.id,
      type: TransactionType.expense, amount: 75000, date: now,
      note: 'Lunch, "special"\nອາຫານ', createdAt: now, updatedAt: now,
    );

    final csv = useCase(
      transactions: [transaction],
      accountsById: {account.id: account},
      categoriesById: {category.id: category},
    );

    expect(csv, startsWith('Transaction ID,Date,Time,Type'));
    expect(csv, contains('TX001,2026-08-04,12:30:00,expense'));
    expect(csv, contains('75000.0,LAK'));
    expect(csv, contains('"Food, drinks"'));
    expect(csv, contains('ອາຫານ'));
    expect(csv, contains('"Lunch, ""special""'));
  });

  test('an empty selection exports the header only', () {
    final csv = useCase(
      transactions: const [], accountsById: const {}, categoriesById: const {},
    );
    expect(csv.trim().split('\r\n'), hasLength(1));
  });
}
