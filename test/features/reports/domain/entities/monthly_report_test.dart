import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/dashboard/domain/entities/category_spending.dart';
import 'package:cashly_lao/features/reports/domain/entities/monthly_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  test('currencies is the union of income and expense currency keys', () {
    final report = MonthlyReport(
      month: DateTime(2026, 3),
      totalIncomeByCurrency: {'LAK': 1000, 'USD': 50},
      totalExpenseByCurrency: {'LAK': 200},
      spendingByCategory: {},
      budgetProgress: [],
    );

    expect(report.currencies, {'LAK', 'USD'});
  });

  test('netByCurrency subtracts expense from income per currency', () {
    final report = MonthlyReport(
      month: DateTime(2026, 3),
      totalIncomeByCurrency: {'LAK': 1000},
      totalExpenseByCurrency: {'LAK': 300, 'USD': 20},
      spendingByCategory: {},
      budgetProgress: [],
    );

    expect(report.netByCurrency, {'LAK': 700, 'USD': -20});
  });

  test('hasAnyActivity is false when there is no income or expense', () {
    final report = MonthlyReport(
      month: DateTime(2026, 3),
      totalIncomeByCurrency: {},
      totalExpenseByCurrency: {},
      spendingByCategory: {},
      budgetProgress: [],
    );

    expect(report.hasAnyActivity, isFalse);
  });

  test(
    'toExportRows emits one category row plus one summary row per currency',
    () {
      final food = category(id: 'food', name: 'Food');
      final report = MonthlyReport(
        month: DateTime(2026, 3),
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
        budgetProgress: const [],
      );

      final rows = report.toExportRows();

      expect(rows, hasLength(2));
      final categoryRow = rows.firstWhere((r) => r['rowType'] == 'category');
      expect(categoryRow['category'], 'Food');
      expect(categoryRow['amount'], 400);
      expect(categoryRow['currency'], 'LAK');

      final summaryRow = rows.firstWhere((r) => r['rowType'] == 'summary');
      expect(summaryRow['totalIncome'], 1000);
      expect(summaryRow['totalExpense'], 400);
      expect(summaryRow['net'], 600);
    },
  );
}
