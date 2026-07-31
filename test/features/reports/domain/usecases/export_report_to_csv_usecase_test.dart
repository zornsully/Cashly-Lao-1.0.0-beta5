import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/dashboard/domain/entities/category_spending.dart';
import 'package:cashly_lao/features/reports/domain/entities/monthly_report.dart';
import 'package:cashly_lao/features/reports/domain/usecases/export_report_to_csv_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = ExportReportToCsvUseCase();

  CategoryEntity category({required String id, required String name}) {
    return CategoryEntity(
      id: id,
      name: name,
      type: CategoryType.expense,
      icon: AppIconKey.other,
      color: AppColorKey.grey,
      isDefault: false,
      isArchived: false,
      sortOrder: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  test('an empty report still produces just the header row', () {
    final report = MonthlyReport(
      month: DateTime(2026, 3),
      totalIncomeByCurrency: const {},
      totalExpenseByCurrency: const {},
      spendingByCategory: const {},
      accountBreakdown: const {},
      budgetProgress: const [],
      transactions: const [],
    );

    final csv = useCase(report);
    final lines = csv.trim().split('\n');

    expect(lines, hasLength(1));
    expect(
      lines.first,
      'month,currency,rowType,category,amount,percentageOfExpense,'
      'totalIncome,totalExpense,net',
    );
  });

  test('emits a category row and a summary row per currency', () {
    final food = category(id: 'food', name: 'Food');
    final report = MonthlyReport(
      month: DateTime(2026, 3, 1),
      totalIncomeByCurrency: const {'LAK': 1000},
      totalExpenseByCurrency: const {'LAK': 400},
      spendingByCategory: {
        'LAK': [
          CategorySpending(
            category: food,
            amount: 400,
            percentageOfExpense: 100,
          ),
        ],
      },
      accountBreakdown: const {},
      budgetProgress: const [],
      transactions: const [],
    );

    final csv = useCase(report);
    final lines = csv.trim().split('\n');

    expect(lines, hasLength(3));
    expect(lines[1], contains('category'));
    expect(lines[1], contains('Food'));
    expect(lines[1], contains('400.0'));
    // The category row has no totalIncome/totalExpense/net — those
    // trailing columns should be empty, not shifted or omitted.
    expect(lines[1], endsWith(',,,'));
    expect(lines[2], contains('summary'));
    expect(lines[2], contains('1000.0'));
  });

  test('quotes and escapes a category name containing a comma', () {
    final giftsAndDonations = category(id: 'gifts', name: 'Gifts, Donations');
    final report = MonthlyReport(
      month: DateTime(2026, 3, 1),
      totalIncomeByCurrency: const {},
      totalExpenseByCurrency: const {'LAK': 100},
      spendingByCategory: {
        'LAK': [
          CategorySpending(
            category: giftsAndDonations,
            amount: 100,
            percentageOfExpense: 100,
          ),
        ],
      },
      accountBreakdown: const {},
      budgetProgress: const [],
      transactions: const [],
    );

    final csv = useCase(report);

    expect(csv, contains('"Gifts, Donations"'));
  });

  test('doubles an internal double-quote character', () {
    final quoted = category(id: 'q', name: 'The "Best" Category');
    final report = MonthlyReport(
      month: DateTime(2026, 3, 1),
      totalIncomeByCurrency: const {},
      totalExpenseByCurrency: const {'LAK': 100},
      spendingByCategory: {
        'LAK': [
          CategorySpending(
            category: quoted,
            amount: 100,
            percentageOfExpense: 100,
          ),
        ],
      },
      accountBreakdown: const {},
      budgetProgress: const [],
      transactions: const [],
    );

    final csv = useCase(report);

    expect(csv, contains('"The ""Best"" Category"'));
  });
}
