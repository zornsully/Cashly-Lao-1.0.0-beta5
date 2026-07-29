import 'package:cashly_lao/features/financial_insights/domain/entities/financial_insight.dart';
import 'package:cashly_lao/features/financial_insights/domain/entities/smart_money_score.dart';
import 'package:cashly_lao/features/financial_insights/domain/services/smart_money_score_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = SmartMoneyScoreCalculator();

  FinancialInsightSnapshot snapshot({
    double currentBalance = 1000,
    double income = 0,
    double expense = 0,
    double previousExpense = 0,
    List<FinancialBudgetStatus> budgets = const [],
  }) {
    FinancialSpendingWindow window(FinancialWindowKind kind) =>
        FinancialSpendingWindow(
          kind: kind,
          income: kind == FinancialWindowKind.month ? income : 0,
          expense: kind == FinancialWindowKind.month ? expense : 0,
          previousExpense: kind == FinancialWindowKind.month
              ? previousExpense
              : 0,
          transactionCount: income == 0 && expense == 0 ? 0 : 1,
        );

    return FinancialInsightSnapshot(
      generatedAt: DateTime(2026, 7, 20),
      currencyCode: 'LAK',
      today: window(FinancialWindowKind.today),
      week: window(FinancialWindowKind.week),
      month: window(FinancialWindowKind.month),
      categoryTrends: const [],
      budgets: budgets,
      balance: FinancialBalancePosition(
        totalBalance: currentBalance,
        activeAccountCount: 1,
      ),
    );
  }

  SmartMoneyScoreOpening opening({
    double balance = 1000,
    SmartMoneyScoreBaselineState state = SmartMoneyScoreBaselineState.reliable,
  }) => SmartMoneyScoreOpening(
    monthStart: DateTime(2026, 7),
    currencyCode: 'LAK',
    openingBalance: balance,
    baselineState: state,
  );

  test('uses actual balance growth as the primary monthly factor', () {
    final result = calculator.calculate(
      snapshot: snapshot(currentBalance: 1100, income: 100),
      opening: opening(),
    );

    expect(result.balanceChange, 100);
    expect(result.balanceChangePercentage, 10);
    // 100 baseline + 10% balance growth + small +5 behaviour modifier.
    expect(result.financialBehaviourModifier, 5);
    expect(result.score, 115);
    expect(result.behaviourBreakdown, isNotNull);
    expect(result.behaviourBreakdown!.incomeExpenseImpact, 3);
    expect(result.behaviourBreakdown!.savingsImpact, 2);
    expect(result.behaviourBreakdown!.appliedModifier, 5);
  });

  test('reduces the score when the actual balance falls', () {
    final result = calculator.calculate(
      snapshot: snapshot(currentBalance: 900, expense: 100),
      opening: opening(),
    );

    expect(result.balanceChangePercentage, -10);
    expect(result.financialBehaviourModifier, -5);
    expect(result.score, 85);
  });

  test(
    'keeps a zero-opening month neutral until meaningful activity exists',
    () {
      final result = calculator.calculate(
        snapshot: snapshot(currentBalance: 0),
        opening: opening(balance: 0),
      );

      expect(result.score, 100);
      expect(result.balanceChangePercentage, 0);
      expect(result.hasMeaningfulActivity, isFalse);
      expect(result.reasons.single, contains('started at zero'));
    },
  );

  test(
    'uses safe cash-flow normalisation after a zero-opening month starts',
    () {
      final result = calculator.calculate(
        snapshot: snapshot(currentBalance: 500, income: 500),
        opening: opening(balance: 0),
      );

      expect(result.balanceChangePercentage, 100);
      expect(result.balanceChangePercentage.isFinite, isTrue);
      expect(result.score, 150);
    },
  );

  test('caps financial behaviour so it cannot overpower balance movement', () {
    final result = calculator.calculate(
      snapshot: snapshot(
        currentBalance: 500,
        expense: 200,
        previousExpense: 100,
        budgets: const [
          FinancialBudgetStatus(
            categoryId: 'food',
            categoryName: 'Food',
            limit: 100,
            spent: 200,
          ),
        ],
      ),
      opening: opening(),
    );

    expect(result.financialBehaviourModifier, -10);
    expect(result.score, 40);
    expect(result.behaviourBreakdown!.uncappedModifier, -11);
    expect(result.behaviourBreakdown!.appliedModifier, -10);
  });

  test('returns a neutral result when the opening cannot be trusted', () {
    final result = calculator.calculate(
      snapshot: snapshot(currentBalance: 1500, income: 500),
      opening: opening(
        state: SmartMoneyScoreBaselineState.unsafeCurrencyMovement,
      ),
    );

    expect(result.score, 100);
    expect(result.isReliable, isFalse);
    expect(result.financialBehaviourModifier, 0);
  });
}
