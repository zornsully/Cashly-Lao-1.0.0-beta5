import 'dart:math' as math;

import '../entities/financial_insight.dart';
import '../entities/smart_money_score.dart';

/// The one shared, deterministic Smart Money Score formula.
///
/// Monthly balance movement is deliberately the dominant component. The
/// behavioural modifier is capped to a small range, so categories, budgets,
/// and transaction habits can make the explanation more useful without
/// overriding what actually happened to the user's balance.
class SmartMoneyScoreCalculator {
  const SmartMoneyScoreCalculator();

  SmartMoneyScoreCalculation calculate({
    required FinancialInsightSnapshot snapshot,
    required SmartMoneyScoreOpening opening,
  }) {
    final month = snapshot.month;
    final currentBalance = snapshot.balance.totalBalance;
    final hasMeaningfulActivity = month.income != 0 || month.expense != 0;

    if (opening.currencyCode != snapshot.currencyCode) {
      return _neutralCalculation(
        snapshot: snapshot,
        hasMeaningfulActivity: hasMeaningfulActivity,
        unavailableReason:
            'This month\'s opening balance uses a different currency.',
      );
    }
    if (!opening.isReliable) {
      return _neutralCalculation(
        snapshot: snapshot,
        hasMeaningfulActivity: hasMeaningfulActivity,
        unavailableReason:
            opening.baselineNote ??
            'Cashly needs a reliable opening balance before comparing this month.',
      );
    }
    if (!_isFinite(
      opening.openingBalance,
      currentBalance,
      month.income,
      month.expense,
      month.previousExpense,
    )) {
      return _neutralCalculation(
        snapshot: snapshot,
        hasMeaningfulActivity: hasMeaningfulActivity,
        unavailableReason:
            'Cashly could not verify the financial values for this month.',
      );
    }

    final balanceChange = currentBalance - opening.openingBalance;
    final netCashFlow = month.income - month.expense;
    final reasons = <String>[];

    final double balanceChangePercentage;
    if (opening.openingBalance == 0) {
      if (!hasMeaningfulActivity) {
        // There is no meaningful denominator yet. A calm, neutral 100 is
        // more truthful than pretending a zero balance has grown by infinity.
        reasons.add(
          'This month started at zero, and there is not enough activity to compare a balance change yet.',
        );
        return SmartMoneyScoreCalculation(
          calculatedAt: snapshot.generatedAt,
          currentBalance: currentBalance,
          balanceChange: balanceChange,
          balanceChangePercentage: 0,
          income: month.income,
          expense: month.expense,
          netCashFlow: netCashFlow,
          financialBehaviourModifier: 0,
          score: 100,
          isReliable: true,
          hasMeaningfulActivity: false,
          reasons: reasons,
          behaviourBreakdown: const SmartMoneyScoreBehaviourBreakdown(
            incomeExpenseImpact: 0,
            savingsImpact: 0,
            budgetImpact: 0,
            spendingTrendImpact: 0,
            lowBalanceImpact: 0,
            billImpact: 0,
            appliedModifier: 0,
          ),
        );
      }

      // Normalise zero-opening months against recorded cash flow rather than
      // dividing by zero. The same inputs always give the same result.
      final cashFlowScale = math.max(
        math.max(month.income.abs(), month.expense.abs()),
        1,
      );
      balanceChangePercentage = (balanceChange / cashFlowScale) * 100;
      reasons.add(
        'This month started at zero, so balance movement is compared with recorded cash flow.',
      );
    } else {
      final denominator = math.max(opening.openingBalance.abs(), 1);
      balanceChangePercentage = (balanceChange / denominator) * 100;
      final direction = balanceChange >= 0 ? 'increased' : 'decreased';
      reasons.add(
        'Your balance has $direction by ${_roundedPercent(balanceChangePercentage)} since this month began.',
      );
    }

    final behaviour = _behaviourModifier(snapshot, netCashFlow);
    reasons.addAll(behaviour.reasons);
    final score = (100 + balanceChangePercentage + behaviour.value)
        .round()
        .clamp(0, 150)
        .toInt();

    return SmartMoneyScoreCalculation(
      calculatedAt: snapshot.generatedAt,
      currentBalance: currentBalance,
      balanceChange: balanceChange,
      balanceChangePercentage: balanceChangePercentage,
      income: month.income,
      expense: month.expense,
      netCashFlow: netCashFlow,
      financialBehaviourModifier: behaviour.value,
      score: score,
      isReliable: true,
      hasMeaningfulActivity: hasMeaningfulActivity,
      reasons: reasons.take(4).toList(),
      behaviourBreakdown: behaviour.breakdown,
    );
  }

  SmartMoneyScoreCalculation _neutralCalculation({
    required FinancialInsightSnapshot snapshot,
    required bool hasMeaningfulActivity,
    required String unavailableReason,
  }) {
    final month = snapshot.month;
    return SmartMoneyScoreCalculation(
      calculatedAt: snapshot.generatedAt,
      currentBalance: snapshot.balance.totalBalance,
      balanceChange: 0,
      balanceChangePercentage: 0,
      income: month.income,
      expense: month.expense,
      netCashFlow: month.income - month.expense,
      financialBehaviourModifier: 0,
      score: 100,
      isReliable: false,
      hasMeaningfulActivity: hasMeaningfulActivity,
      reasons: [unavailableReason],
      behaviourBreakdown: const SmartMoneyScoreBehaviourBreakdown(
        incomeExpenseImpact: 0,
        savingsImpact: 0,
        budgetImpact: 0,
        spendingTrendImpact: 0,
        lowBalanceImpact: 0,
        billImpact: 0,
        appliedModifier: 0,
      ),
      unavailableReason: unavailableReason,
    );
  }

  _BehaviourModifier _behaviourModifier(
    FinancialInsightSnapshot snapshot,
    double netCashFlow,
  ) {
    final month = snapshot.month;
    var incomeExpenseImpact = 0;
    var savingsImpact = 0;
    var budgetImpact = 0;
    var spendingTrendImpact = 0;
    var lowBalanceImpact = 0;
    final reasons = <String>[];

    if (month.income > 0 && month.income > month.expense) {
      incomeExpenseImpact = 3;
      reasons.add('Recorded income is ahead of this month\'s expenses.');
    } else if (month.expense > month.income && month.expense > 0) {
      incomeExpenseImpact = -3;
      reasons.add('Recorded expenses are ahead of this month\'s income.');
    }

    if (netCashFlow > 0) {
      savingsImpact = 2;
      reasons.add('This month currently has positive net cash flow.');
    } else if (netCashFlow < 0) {
      savingsImpact = -2;
      reasons.add('This month currently has negative net cash flow.');
    }

    final hasOverBudget = snapshot.budgets.any((budget) => budget.usage >= 1);
    final hasNearBudget = snapshot.budgets.any((budget) => budget.usage >= .85);
    if (hasOverBudget) {
      budgetImpact = -4;
      reasons.add('At least one monthly budget has been exceeded.');
    } else if (hasNearBudget) {
      budgetImpact = -2;
      reasons.add('At least one monthly budget has little room remaining.');
    } else if (snapshot.budgets.isNotEmpty) {
      budgetImpact = 1;
      reasons.add('Current spending remains within the budgets you set.');
    }

    final expenseChange = month.expenseChangePercent;
    if (expenseChange != null && expenseChange <= -10) {
      spendingTrendImpact = 2;
      reasons.add('Spending is lower than the comparable previous period.');
    } else if (expenseChange != null && expenseChange >= 40) {
      spendingTrendImpact = -2;
      reasons.add(
        'Spending is notably higher than the comparable previous period.',
      );
    }

    if (snapshot.balance.totalBalance < 0) {
      lowBalanceImpact = -2;
      reasons.add('The current balance is below zero.');
    }

    final uncappedModifier =
        incomeExpenseImpact +
        savingsImpact +
        budgetImpact +
        spendingTrendImpact +
        lowBalanceImpact;
    final appliedModifier = uncappedModifier.clamp(-10, 10).toInt();
    return _BehaviourModifier(
      value: appliedModifier,
      reasons: reasons,
      breakdown: SmartMoneyScoreBehaviourBreakdown(
        incomeExpenseImpact: incomeExpenseImpact,
        savingsImpact: savingsImpact,
        budgetImpact: budgetImpact,
        spendingTrendImpact: spendingTrendImpact,
        lowBalanceImpact: lowBalanceImpact,
        billImpact: 0,
        appliedModifier: appliedModifier,
      ),
    );
  }

  bool _isFinite(double a, double b, double c, double d, double e) =>
      a.isFinite && b.isFinite && c.isFinite && d.isFinite && e.isFinite;

  String _roundedPercent(double value) => '${value.round()}%';
}

class _BehaviourModifier {
  const _BehaviourModifier({
    required this.value,
    required this.reasons,
    required this.breakdown,
  });

  final int value;
  final List<String> reasons;
  final SmartMoneyScoreBehaviourBreakdown breakdown;
}
