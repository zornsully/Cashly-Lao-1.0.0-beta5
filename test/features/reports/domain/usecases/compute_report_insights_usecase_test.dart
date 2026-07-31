import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/dashboard/domain/entities/category_spending.dart';
import 'package:cashly_lao/features/reports/domain/entities/monthly_report.dart';
import 'package:cashly_lao/features/reports/domain/usecases/compute_report_insights_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = ComputeReportInsightsUseCase();

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

  MonthlyReport report({
    required Map<String, double> income,
    required Map<String, double> expense,
    Map<String, List<CategorySpending>> spendingByCategory = const {},
  }) {
    return MonthlyReport(
      month: DateTime(2026, 3),
      totalIncomeByCurrency: income,
      totalExpenseByCurrency: expense,
      spendingByCategory: spendingByCategory,
      accountBreakdown: const {},
      budgetProgress: const [],
      transactions: const [],
    );
  }

  test('computes savings rate, average daily spend, and top category', () {
    final food = category(id: 'food', name: 'Food');
    final result = useCase(
      report: report(
        income: const {'LAK': 1000},
        expense: const {'LAK': 400},
        spendingByCategory: {
          'LAK': [
            CategorySpending(
              category: food,
              amount: 400,
              percentageOfExpense: 100,
            ),
          ],
        },
      ),
      periodDays: 20,
      previousPeriodExpenseByCurrency: const {},
    );

    expect(result.savingsRatePercentByCurrency['LAK'], 60);
    expect(result.averageDailySpendByCurrency['LAK'], 20);
    expect(result.topCategoryByCurrency['LAK']?.category.id, 'food');
    expect(result.expenseChangePercentByCurrency, isEmpty);
  });

  test('savings rate is 0 when there is no income, not a divide-by-zero', () {
    final result = useCase(
      report: report(income: const {}, expense: const {'LAK': 100}),
      periodDays: 10,
      previousPeriodExpenseByCurrency: const {},
    );

    expect(result.savingsRatePercentByCurrency['LAK'], 0);
  });

  test('computes a positive month-over-month expense change', () {
    final result = useCase(
      report: report(income: const {}, expense: const {'LAK': 150}),
      periodDays: 30,
      previousPeriodExpenseByCurrency: const {'LAK': 100},
    );

    expect(result.expenseChangePercentByCurrency['LAK'], 50);
  });

  test('computes a negative month-over-month expense change', () {
    final result = useCase(
      report: report(income: const {}, expense: const {'LAK': 50}),
      periodDays: 30,
      previousPeriodExpenseByCurrency: const {'LAK': 100},
    );

    expect(result.expenseChangePercentByCurrency['LAK'], -50);
  });

  test(
    'omits the month-over-month figure when the previous period was zero',
    () {
      final result = useCase(
        report: report(income: const {}, expense: const {'LAK': 50}),
        periodDays: 30,
        previousPeriodExpenseByCurrency: const {'LAK': 0},
      );

      expect(result.expenseChangePercentByCurrency, isEmpty);
    },
  );

  test('treats a period of less than a day as at least one day', () {
    final result = useCase(
      report: report(income: const {}, expense: const {'LAK': 40}),
      periodDays: 0,
      previousPeriodExpenseByCurrency: const {},
    );

    expect(result.averageDailySpendByCurrency['LAK'], 40);
  });
}
