import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/smart_money_score.dart';

/// Firestore mapper for one immutable-month Smart Money Score record.
class SmartMoneyScoreModel extends SmartMoneyScoreMonth {
  const SmartMoneyScoreModel({
    required super.opening,
    required super.createdAt,
    required super.updatedAt,
    super.latestCalculation,
  });

  factory SmartMoneyScoreModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final latestRaw = data['latestCalculation'] as Map<String, dynamic>?;
    return SmartMoneyScoreModel(
      opening: SmartMoneyScoreOpening(
        monthStart: _date(data['monthStart']) ?? DateTime.now(),
        currencyCode: data['currencyCode'] as String,
        openingBalance: (data['openingBalance'] as num).toDouble(),
        baselineState: SmartMoneyScoreBaselineState.values.byName(
          data['baselineState'] as String,
        ),
        baselineNote: _emptyToNull(data['baselineNote'] as String? ?? ''),
      ),
      createdAt: _date(data['createdAt']) ?? DateTime.now(),
      updatedAt: _date(data['updatedAt']) ?? DateTime.now(),
      latestCalculation: latestRaw == null
          ? null
          : _calculationFromFirestore(latestRaw),
    );
  }

  static Map<String, Object?> openingToFirestore(
    SmartMoneyScoreOpening opening,
  ) {
    return {
      'monthStart': Timestamp.fromDate(opening.monthStart),
      'monthKey': opening.monthKey,
      'currencyCode': opening.currencyCode,
      'openingBalance': opening.openingBalance,
      'baselineState': opening.baselineState.name,
      'baselineNote': opening.baselineNote ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, Object?> calculationToFirestore(
    SmartMoneyScoreCalculation calculation,
  ) {
    return {
      'calculatedAt': Timestamp.fromDate(calculation.calculatedAt),
      'currentBalance': calculation.currentBalance,
      'balanceChange': calculation.balanceChange,
      'balanceChangePercentage': calculation.balanceChangePercentage,
      'income': calculation.income,
      'expense': calculation.expense,
      'netCashFlow': calculation.netCashFlow,
      'financialBehaviourModifier': calculation.financialBehaviourModifier,
      'score': calculation.score,
      'isReliable': calculation.isReliable,
      'hasMeaningfulActivity': calculation.hasMeaningfulActivity,
      'reasons': calculation.reasons,
      if (calculation.behaviourBreakdown != null)
        'behaviourBreakdown': _breakdownToFirestore(
          calculation.behaviourBreakdown!,
        ),
      'unavailableReason': calculation.unavailableReason ?? '',
    };
  }

  static SmartMoneyScoreCalculation _calculationFromFirestore(
    Map<String, dynamic> data,
  ) {
    final breakdownRaw = data['behaviourBreakdown'];
    return SmartMoneyScoreCalculation(
      calculatedAt: _date(data['calculatedAt']) ?? DateTime.now(),
      currentBalance: (data['currentBalance'] as num).toDouble(),
      balanceChange: (data['balanceChange'] as num).toDouble(),
      balanceChangePercentage: (data['balanceChangePercentage'] as num)
          .toDouble(),
      income: (data['income'] as num).toDouble(),
      expense: (data['expense'] as num).toDouble(),
      netCashFlow: (data['netCashFlow'] as num).toDouble(),
      financialBehaviourModifier: (data['financialBehaviourModifier'] as num)
          .toInt(),
      score: (data['score'] as num).toInt(),
      isReliable: data['isReliable'] as bool,
      hasMeaningfulActivity: data['hasMeaningfulActivity'] as bool,
      reasons: (data['reasons'] as List<dynamic>).cast<String>(),
      behaviourBreakdown: breakdownRaw is Map<String, dynamic>
          ? _breakdownFromFirestore(breakdownRaw)
          : null,
      unavailableReason: _emptyToNull(
        data['unavailableReason'] as String? ?? '',
      ),
    );
  }

  static Map<String, int> _breakdownToFirestore(
    SmartMoneyScoreBehaviourBreakdown breakdown,
  ) {
    return {
      'incomeExpenseImpact': breakdown.incomeExpenseImpact,
      'savingsImpact': breakdown.savingsImpact,
      'budgetImpact': breakdown.budgetImpact,
      'spendingTrendImpact': breakdown.spendingTrendImpact,
      'lowBalanceImpact': breakdown.lowBalanceImpact,
      'billImpact': breakdown.billImpact,
      'appliedModifier': breakdown.appliedModifier,
    };
  }

  static SmartMoneyScoreBehaviourBreakdown _breakdownFromFirestore(
    Map<String, dynamic> data,
  ) {
    int value(String key) => (data[key] as num?)?.toInt() ?? 0;
    return SmartMoneyScoreBehaviourBreakdown(
      incomeExpenseImpact: value('incomeExpenseImpact'),
      savingsImpact: value('savingsImpact'),
      budgetImpact: value('budgetImpact'),
      spendingTrendImpact: value('spendingTrendImpact'),
      lowBalanceImpact: value('lowBalanceImpact'),
      billImpact: value('billImpact'),
      appliedModifier: value('appliedModifier').clamp(-10, 10).toInt(),
    );
  }

  static DateTime? _date(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime dateTime => dateTime,
    _ => null,
  };

  static String? _emptyToNull(String value) => value.isEmpty ? null : value;
}
