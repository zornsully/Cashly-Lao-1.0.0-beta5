import 'package:cashly_lao/features/financial_insights/domain/entities/financial_insight.dart';
import 'package:cashly_lao/features/financial_insights/domain/entities/financial_insight_message.dart';
import 'package:cashly_lao/features/financial_insights/domain/entities/smart_money_score.dart';
import 'package:cashly_lao/features/financial_insights/domain/services/rule_based_financial_insight_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = RuleBasedFinancialInsightEngine();

  FinancialSpendingWindow window({
    FinancialWindowKind kind = FinancialWindowKind.month,
    double expense = 0,
    double income = 0,
    double previousExpense = 0,
    int transactions = 0,
  }) => FinancialSpendingWindow(
    kind: kind,
    expense: expense,
    income: income,
    previousExpense: previousExpense,
    transactionCount: transactions,
  );

  FinancialInsightSnapshot snapshot({
    List<FinancialBudgetStatus> budgets = const [],
    List<FinancialCategoryTrend> trends = const [],
    FinancialSpendingWindow? today,
    FinancialSpendingWindow? week,
    FinancialSpendingWindow? month,
    SmartMoneyScoreCalculation? monthlyScoreCalculation,
    double totalBalance = 0,
    int activeAccountCount = 1,
    bool hasCrossCurrencyTransferToday = false,
    bool hasCrossCurrencyTransferThisWeek = false,
    bool hasAccountCreatedToday = false,
    bool hasAccountCreatedThisWeek = false,
  }) => FinancialInsightSnapshot(
    generatedAt: DateTime(2026, 7, 25),
    currencyCode: 'LAK',
    today: today ?? window(kind: FinancialWindowKind.today),
    week: week ?? window(kind: FinancialWindowKind.week),
    month: month ?? window(expense: 100, transactions: 1),
    categoryTrends: trends,
    budgets: budgets,
    balance: FinancialBalancePosition(
      totalBalance: totalBalance,
      activeAccountCount: activeAccountCount,
      hasCrossCurrencyTransferToday: hasCrossCurrencyTransferToday,
      hasCrossCurrencyTransferThisWeek: hasCrossCurrencyTransferThisWeek,
      hasAccountCreatedToday: hasAccountCreatedToday,
      hasAccountCreatedThisWeek: hasAccountCreatedThisWeek,
    ),
    monthlyScoreCalculation: monthlyScoreCalculation,
  );

  test(
    'offers a gentle onboarding insight when there is no activity',
    () async {
      final result = await engine.analyze(snapshot(month: window()));

      expect(result.todayScore.value, 75);
      expect(result.weekScore.value, 75);
      expect(result.monthScore.value, 75);
      expect(
        result.headline.key,
        FinancialInsightMessageKey.onboardingHeadline,
      );
      expect(
        result.actions.single.title.key,
        FinancialInsightMessageKey.logNextExpenseTitle,
      );
    },
  );

  test('flags an over-budget category with a specific action', () async {
    final result = await engine.analyze(
      snapshot(
        budgets: const [
          FinancialBudgetStatus(
            categoryId: 'food',
            categoryName: 'Food',
            limit: 100,
            spent: 125,
          ),
        ],
      ),
    );

    expect(result.tone, FinancialInsightTone.critical);
    expect(result.dailyScore, lessThan(75));
    expect(result.monthScore.value, lessThan(result.weekScore.value));
    expect(
      result.headline.key,
      FinancialInsightMessageKey.categoryOverBudgetHeadline,
    );
    expect(result.headline.args['category'], 'Food');
    expect(result.actions.first.title.args['category'], 'Food');
  });

  test(
    'detects a comparable category spike without using generic advice',
    () async {
      final result = await engine.analyze(
        snapshot(
          trends: const [
            FinancialCategoryTrend(
              categoryId: 'transport',
              categoryName: 'Transport',
              currentExpense: 320,
              previousExpense: 100,
              monthExpense: 320,
            ),
          ],
          week: window(
            kind: FinancialWindowKind.week,
            expense: 320,
            transactions: 2,
          ),
          month: window(expense: 400, previousExpense: 350, transactions: 3),
        ),
      );

      expect(result.tone, FinancialInsightTone.watch);
      expect(
        result.headline.key,
        FinancialInsightMessageKey.categoryHigherThanUsualHeadline,
      );
      expect(result.headline.args['category'], 'Transport');
      expect(
        result.explanation.key,
        FinancialInsightMessageKey.categoryHigherThanUsualExplanation,
      );
      expect(result.explanation.args['changePercent'], '220%');
      expect(result.actions.first.title.args['category'], 'Transport');
      expect(result.primaryScore.period, FinancialWindowKind.month);
    },
  );

  test(
    'scores a daily spike separately from the weekly and monthly pace',
    () async {
      final result = await engine.analyze(
        snapshot(
          today: window(
            kind: FinancialWindowKind.today,
            expense: 300,
            previousExpense: 100,
            transactions: 1,
          ),
          week: window(
            kind: FinancialWindowKind.week,
            expense: 400,
            transactions: 2,
          ),
          month: window(expense: 400, transactions: 2),
        ),
      );

      expect(result.todayScore.period, FinancialWindowKind.today);
      expect(result.todayScore.value, lessThan(result.weekScore.value));
      expect(
        result.todayScore.reasons.map((r) => r.key),
        anyElement(
          anyOf(
            FinancialInsightMessageKey.todaySpikeReason,
            FinancialInsightMessageKey.todayComparableIncreaseReason,
          ),
        ),
      );
    },
  );

  test('scores a weekly rise without lowering the monthly score', () async {
    final result = await engine.analyze(
      snapshot(
        week: window(
          kind: FinancialWindowKind.week,
          expense: 320,
          previousExpense: 100,
          transactions: 2,
        ),
        month: window(expense: 320, transactions: 2),
      ),
    );

    expect(result.weekScore.period, FinancialWindowKind.week);
    expect(result.weekScore.value, lessThan(result.monthScore.value));
    expect(result.primaryScore.period, FinancialWindowKind.month);
  });

  test('scores monthly income coverage and month-to-date growth', () async {
    final result = await engine.analyze(
      snapshot(
        month: window(
          expense: 600,
          income: 100,
          previousExpense: 200,
          transactions: 3,
        ),
      ),
    );

    expect(result.monthScore.period, FinancialWindowKind.month);
    expect(result.monthScore.value, lessThan(result.todayScore.value));
    expect(
      result.monthScore.reasons.map((r) => r.key),
      anyElement(
        anyOf(
          FinancialInsightMessageKey.spendingOverIncomeReasonMonth,
          FinancialInsightMessageKey.monthComparableIncreaseReason,
          FinancialInsightMessageKey.monthComparableDecreaseReason,
        ),
      ),
    );
  });

  test(
    'lowers every score and creates a clear check-in for a negative balance',
    () async {
      final result = await engine.analyze(
        snapshot(totalBalance: -120000, month: window()),
      );

      expect(result.tone, FinancialInsightTone.critical);
      expect(result.todayScore.value, lessThan(75));
      expect(result.weekScore.value, lessThan(75));
      expect(result.monthScore.value, lessThan(75));
      expect(
        result.headline.key,
        FinancialInsightMessageKey.negativeBalanceHeadline,
      );
      expect(
        result.scoreReasons.map((r) => r.key),
        anyElement(FinancialInsightMessageKey.balanceImpactNegativeReason),
      );
    },
  );

  test(
    'raises scores when a balance buffer covers more than a month',
    () async {
      final thinBuffer = await engine.analyze(
        snapshot(
          totalBalance: 100,
          week: window(
            kind: FinancialWindowKind.week,
            expense: 250,
            transactions: 3,
          ),
          month: window(expense: 500, transactions: 6),
        ),
      );
      final healthyBuffer = await engine.analyze(
        snapshot(
          totalBalance: 2000,
          week: window(
            kind: FinancialWindowKind.week,
            expense: 250,
            transactions: 3,
          ),
          month: window(expense: 500, transactions: 6),
        ),
      );

      expect(
        healthyBuffer.todayScore.value,
        greaterThan(thinBuffer.todayScore.value),
      );
      expect(
        healthyBuffer.weekScore.value,
        greaterThan(thinBuffer.weekScore.value),
      );
      expect(
        healthyBuffer.monthScore.value,
        greaterThan(thinBuffer.monthScore.value),
      );
      expect(
        healthyBuffer.monthScore.reasons.map((r) => r.key),
        anyElement(FinancialInsightMessageKey.balanceImpactHealthyReason),
      );
    },
  );

  test(
    'uses the persisted lifecycle calculation for the primary month score',
    () async {
      final result = await engine.analyze(
        snapshot(
          monthlyScoreCalculation: SmartMoneyScoreCalculation(
            calculatedAt: DateTime(2026, 7, 25),
            currentBalance: 1100,
            balanceChange: 100,
            balanceChangePercentage: 10,
            income: 100,
            expense: 0,
            netCashFlow: 100,
            financialBehaviourModifier: 5,
            score: 115,
            isReliable: true,
            hasMeaningfulActivity: true,
            reasons: const ['Your balance has increased by 10%.'],
          ),
        ),
      );

      expect(result.monthScore.value, 115);
      expect(result.monthScore.maximum, 150);
      expect(result.primaryScore, result.monthScore);
      expect(
        result.scoreReasons.single.key,
        FinancialInsightMessageKey.literal,
      );
      expect(
        result.scoreReasons.single.args['text'],
        contains('increased by 10%'),
      );
    },
  );

  test(
    'applies bounded day and week balance movement when reconstruction is safe',
    () async {
      final safe = await engine.analyze(
        snapshot(
          totalBalance: 600,
          today: window(
            kind: FinancialWindowKind.today,
            expense: 400,
            transactions: 1,
          ),
          week: window(
            kind: FinancialWindowKind.week,
            expense: 400,
            transactions: 1,
          ),
          month: window(expense: 400, transactions: 1),
        ),
      );
      final unsafe = await engine.analyze(
        snapshot(
          totalBalance: 600,
          today: window(
            kind: FinancialWindowKind.today,
            expense: 400,
            transactions: 1,
          ),
          week: window(
            kind: FinancialWindowKind.week,
            expense: 400,
            transactions: 1,
          ),
          month: window(expense: 400, transactions: 1),
          hasCrossCurrencyTransferToday: true,
          hasCrossCurrencyTransferThisWeek: true,
        ),
      );

      expect(safe.todayScore.value, 90);
      expect(safe.weekScore.value, 90);
      expect(unsafe.todayScore.value, greaterThan(safe.todayScore.value));
      expect(unsafe.weekScore.value, greaterThan(safe.weekScore.value));
      expect(
        unsafe.todayScore.reasons.map((r) => r.key),
        anyElement(FinancialInsightMessageKey.shortHorizonCrossCurrencyToday),
      );
      expect(
        unsafe.weekScore.reasons.map((r) => r.key),
        anyElement(FinancialInsightMessageKey.shortHorizonCrossCurrencyWeek),
      );
    },
  );
}
