import 'package:cashly_lao/features/financial_insights/domain/entities/financial_insight.dart';
import 'package:cashly_lao/features/financial_insights/domain/entities/financial_insight_message.dart';
import 'package:cashly_lao/features/financial_insights/domain/services/short_horizon_balance_movement_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = ShortHorizonBalanceMovementCalculator();

  FinancialInsightSnapshot snapshot({
    double currentBalance = 1000,
    double todayIncome = 0,
    double todayExpense = 0,
    double weekIncome = 0,
    double weekExpense = 0,
    bool hasCrossCurrencyTransferToday = false,
    bool hasCrossCurrencyTransferThisWeek = false,
    bool hasAccountCreatedToday = false,
    bool hasAccountCreatedThisWeek = false,
    int activeAccountCount = 1,
  }) {
    FinancialSpendingWindow window(
      FinancialWindowKind kind, {
      double income = 0,
      double expense = 0,
    }) => FinancialSpendingWindow(
      kind: kind,
      income: income,
      expense: expense,
      previousExpense: 0,
      transactionCount: income == 0 && expense == 0 ? 0 : 1,
    );

    return FinancialInsightSnapshot(
      generatedAt: DateTime(2026, 7, 20, 10),
      currencyCode: 'LAK',
      today: window(
        FinancialWindowKind.today,
        income: todayIncome,
        expense: todayExpense,
      ),
      week: window(
        FinancialWindowKind.week,
        income: weekIncome,
        expense: weekExpense,
      ),
      month: window(FinancialWindowKind.month),
      categoryTrends: const [],
      budgets: const [],
      balance: FinancialBalancePosition(
        totalBalance: currentBalance,
        activeAccountCount: activeAccountCount,
        hasCrossCurrencyTransferToday: hasCrossCurrencyTransferToday,
        hasCrossCurrencyTransferThisWeek: hasCrossCurrencyTransferThisWeek,
        hasAccountCreatedToday: hasAccountCreatedToday,
        hasAccountCreatedThisWeek: hasAccountCreatedThisWeek,
      ),
    );
  }

  test('derives a modest daily impact from a safe opening balance', () {
    final movement = calculator.calculate(
      snapshot: snapshot(currentBalance: 1100, todayIncome: 100),
      period: FinancialWindowKind.today,
    );

    expect(movement.isReliable, isTrue);
    expect(movement.openingBalance, 1000);
    expect(movement.balanceChange, 100);
    expect(movement.balanceChangePercentage, 10);
    expect(movement.moderatedImpact, 3);
  });

  test('keeps weekly balance movement deliberately capped', () {
    final movement = calculator.calculate(
      snapshot: snapshot(currentBalance: 100, weekExpense: 900),
      period: FinancialWindowKind.week,
    );

    expect(movement.openingBalance, 1000);
    expect(movement.balanceChangePercentage, -90);
    expect(
      movement.moderatedImpact,
      -ShortHorizonBalanceMovementCalculator.maxModeratedImpact,
    );
  });

  test('avoids division by zero before a zero-opening day has activity', () {
    final movement = calculator.calculate(
      snapshot: snapshot(currentBalance: 0),
      period: FinancialWindowKind.today,
    );

    expect(movement.isReliable, isFalse);
    expect(movement.balanceChangePercentage, 0);
    expect(movement.moderatedImpact, 0);
    expect(
      movement.reason.key,
      FinancialInsightMessageKey.shortHorizonZeroOpeningToday,
    );
  });

  test('uses a safe cash-flow denominator after zero-opening activity', () {
    final movement = calculator.calculate(
      snapshot: snapshot(currentBalance: 500, todayIncome: 500),
      period: FinancialWindowKind.today,
    );

    expect(movement.isReliable, isTrue);
    expect(movement.openingBalance, 0);
    expect(movement.balanceChangePercentage, 100);
    expect(
      movement.moderatedImpact,
      ShortHorizonBalanceMovementCalculator.maxModeratedImpact,
    );
  });

  test('uses period-specific guards for cross-currency transfers', () {
    final source = snapshot(
      currentBalance: 1100,
      todayIncome: 100,
      weekIncome: 100,
      hasCrossCurrencyTransferThisWeek: true,
    );

    final today = calculator.calculate(
      snapshot: source,
      period: FinancialWindowKind.today,
    );
    final week = calculator.calculate(
      snapshot: source,
      period: FinancialWindowKind.week,
    );

    expect(today.isReliable, isTrue);
    expect(week.isReliable, isFalse);
    expect(week.state, ShortHorizonBalanceMovementState.unsafeCurrencyMovement);
    expect(week.moderatedImpact, 0);
    expect(
      week.reason.key,
      FinancialInsightMessageKey.shortHorizonCrossCurrencyWeek,
    );
  });

  test('falls back when an account was added inside the score window', () {
    final movement = calculator.calculate(
      snapshot: snapshot(
        currentBalance: 1100,
        todayIncome: 100,
        hasAccountCreatedToday: true,
      ),
      period: FinancialWindowKind.today,
    );

    expect(movement.isReliable, isFalse);
    expect(movement.state, ShortHorizonBalanceMovementState.insufficientData);
    expect(movement.moderatedImpact, 0);
    expect(
      movement.reason.key,
      FinancialInsightMessageKey.shortHorizonAccountAddedToday,
    );
  });
}
