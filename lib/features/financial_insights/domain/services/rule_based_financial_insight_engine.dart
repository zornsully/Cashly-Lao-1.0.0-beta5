import '../entities/financial_insight.dart';
import '../entities/smart_money_score.dart';
import 'financial_insight_engine.dart';
import 'short_horizon_balance_movement_calculator.dart';

/// Deterministic first version of the Cashly financial assistant.
///
/// Each period is evaluated independently, so users can see whether a risk
/// is isolated to today, building this week, or affecting the month. The
/// structured output remains compatible with a future LLM-backed engine.
class RuleBasedFinancialInsightEngine implements FinancialInsightEngine {
  const RuleBasedFinancialInsightEngine();

  static const _shortHorizonBalanceMovement =
      ShortHorizonBalanceMovementCalculator();

  @override
  Future<FinancialInsight> analyze(FinancialInsightSnapshot snapshot) async {
    // A negative balance needs a check-in even before there is enough
    // transaction activity to establish a spending pattern.
    if (!snapshot.hasActivity && !snapshot.hasNegativeBalance) {
      return _emptyInsight(snapshot);
    }

    final signals = _signals(snapshot);
    final todayScore = _scoreToday(snapshot, signals);
    final weekScore = _scoreWeek(snapshot, signals);
    final monthScore = _scoreMonth(snapshot, signals);
    // Cashly's monthly balance-movement score is the primary score. Today
    // and week remain useful short-horizon check-ins, not competing formulas.
    final primaryScore = monthScore;

    var narrativeTone = FinancialInsightTone.positive;
    var headline = 'Your spending is looking steady today.';
    var explanation =
        'Keep logging transactions and Cashly will make each insight more personal.';
    final actions = <FinancialInsightAction>[];

    if (signals.balance.isNegative) {
      narrativeTone = FinancialInsightTone.critical;
      headline = 'Your total balance is below zero.';
      explanation =
          'Your total ${snapshot.currencyCode} balance is ${_amount(snapshot.balance.totalBalance, snapshot.currencyCode)}. Bringing that shortfall above zero is the clearest next step.';
      actions.add(
        const FinancialInsightAction(
          title: 'Plan the next essential expense first',
          detail:
              'Focusing on one necessary expense at a time can help rebuild a positive buffer without judging past choices.',
        ),
      );
    } else if (signals.overBudget != null) {
      final budget = signals.overBudget!;
      narrativeTone = FinancialInsightTone.critical;
      headline = '${budget.categoryName} is over its monthly budget.';
      explanation =
          'You have spent ${_amount(budget.spent, snapshot.currencyCode)} against a ${_amount(budget.limit, snapshot.currencyCode)} plan.';
      actions.add(
        FinancialInsightAction(
          title: 'Pause ${budget.categoryName} spending for today',
          detail:
              'A short pause protects the rest of this month\'s plan without judging past choices.',
        ),
      );
    } else if (signals.nearBudget != null || signals.pacedBudget != null) {
      final budget = signals.nearBudget ?? signals.pacedBudget!;
      narrativeTone = FinancialInsightTone.caution;
      headline = '${budget.categoryName} needs a little room this month.';
      explanation =
          'You have used ${_percent(budget.usage)} of its ${_amount(budget.limit, snapshot.currencyCode)} budget.';
      actions.add(
        FinancialInsightAction(
          title: 'Set a rest-of-month limit for ${budget.categoryName}',
          detail:
              'Keeping the next purchases within ${_amount(budget.remaining, snapshot.currencyCode)} will keep this budget on track.',
        ),
      );
    }

    if (signals.weeklyCategorySpike != null) {
      final spike = signals.weeklyCategorySpike!;
      if (narrativeTone == FinancialInsightTone.positive) {
        narrativeTone = FinancialInsightTone.watch;
        headline = '${spike.categoryName} is higher than your usual pace.';
        explanation =
            'It is ${_changePercent(spike.changePercent!)} above the comparable period, so it is worth a quick check-in.';
      }
      actions.add(
        FinancialInsightAction(
          title: 'Review your next ${spike.categoryName} purchase',
          detail:
              'A small swap or delay can soften this increase while you decide whether it was a one-off.',
        ),
      );
    } else if (signals.todaySpike) {
      if (narrativeTone == FinancialInsightTone.positive) {
        narrativeTone = FinancialInsightTone.watch;
        headline = 'Today is spending faster than this week\'s pace.';
        explanation =
            'That can happen - one intentional check before another purchase keeps the day in your control.';
      }
      actions.add(
        const FinancialInsightAction(
          title: 'Check the next expense before you buy',
          detail:
              'A quick pause can keep today closer to your usual pace without changing what has already happened.',
        ),
      );
    }

    if (signals.spendingOverIncome) {
      if (narrativeTone == FinancialInsightTone.positive) {
        narrativeTone = FinancialInsightTone.watch;
        headline = 'This month\'s spending is ahead of income so far.';
        explanation =
            'This is a trend to watch, not a verdict - one or two intentional choices can still change the month.';
      }
      actions.add(
        const FinancialInsightAction(
          title: 'Choose one low-priority expense to delay',
          detail:
              'Focus on the next choice only; reducing one flexible cost can bring the month closer to balance.',
        ),
      );
    }

    if (signals.balance.needsAttention) {
      if (narrativeTone == FinancialInsightTone.positive) {
        narrativeTone = signals.balance.attentionTone;
        headline = signals.balance.attentionHeadline;
        explanation = signals.balance.attentionExplanation(
          snapshot.currencyCode,
        );
      }
      if (actions.length < 2) {
        actions.add(signals.balance.practicalAction);
      }
    }

    if (actions.isEmpty) {
      actions.add(
        const FinancialInsightAction(
          title: 'Keep your next expense intentional',
          detail:
              'Your current pace is healthy. A quick check before a purchase helps it stay that way.',
        ),
      );
    }

    return FinancialInsight(
      currencyCode: snapshot.currencyCode,
      totalBalance: snapshot.balance.totalBalance,
      todayScore: todayScore,
      weekScore: weekScore,
      monthScore: monthScore,
      tone: narrativeTone == FinancialInsightTone.positive
          ? primaryScore.tone
          : narrativeTone,
      headline: headline,
      explanation: explanation,
      scoreReasons: primaryScore.reasons,
      actions: actions.take(2).toList(),
      today: snapshot.today,
      week: snapshot.week,
      month: snapshot.month,
      monthlyScoreCalculation: snapshot.monthlyScoreCalculation,
      budgets: snapshot.budgets,
    );
  }

  FinancialPeriodScore _scoreToday(
    FinancialInsightSnapshot snapshot,
    _InsightSignals signals,
  ) {
    var score = 100;
    final reasons = <String>[];
    final balanceMovement = _shortHorizonBalanceMovement.calculate(
      snapshot: snapshot,
      period: FinancialWindowKind.today,
    );
    final balanceImpact = signals.balance.impactFor(
      FinancialWindowKind.today,
      snapshot.currencyCode,
    );
    score += balanceImpact.points;
    if (balanceImpact.reason != null) reasons.add(balanceImpact.reason!);

    if (signals.overBudget != null) {
      score -= 28;
      reasons.add(
        '${signals.overBudget!.categoryName} is already over its monthly budget.',
      );
    } else if (signals.nearBudget != null) {
      score -= 12;
      reasons.add(
        '${signals.nearBudget!.categoryName} has little budget room left this month.',
      );
    }

    if (signals.todaySpike) {
      score -= 20;
      reasons.add(
        'Today\'s spending is more than twice your earlier daily pace this week.',
      );
    } else if (_isComparableIncrease(snapshot.today, 0.6)) {
      score -= 12;
      reasons.add(
        'Today\'s spending is ${_changePercent(snapshot.today.expenseChangePercent!)} above yesterday\'s comparable total.',
      );
    }

    if (snapshot.today.expense == 0 && snapshot.today.income == 0) {
      reasons.add('No income or expense has been recorded today.');
    } else if (snapshot.today.income >= snapshot.today.expense &&
        snapshot.today.income > 0) {
      score += 2;
      reasons.add('Today\'s recorded income covers today\'s spending.');
    }

    // Balance movement is intentionally modest for a short horizon. It can
    // reinforce a real daily change but never replace budget/pace signals.
    score += balanceMovement.moderatedImpact;
    if (balanceMovement.moderatedImpact != 0 || !balanceMovement.isReliable) {
      reasons.add(balanceMovement.reason);
    }

    return _periodScore(
      period: FinancialWindowKind.today,
      score: score,
      reasons: reasons,
      forceCritical: signals.overBudget != null || balanceImpact.forceCritical,
    );
  }

  FinancialPeriodScore _scoreWeek(
    FinancialInsightSnapshot snapshot,
    _InsightSignals signals,
  ) {
    var score = 100;
    final reasons = <String>[];
    final balanceMovement = _shortHorizonBalanceMovement.calculate(
      snapshot: snapshot,
      period: FinancialWindowKind.week,
    );
    final balanceImpact = signals.balance.impactFor(
      FinancialWindowKind.week,
      snapshot.currencyCode,
    );
    score += balanceImpact.points;
    if (balanceImpact.reason != null) reasons.add(balanceImpact.reason!);

    if (signals.overBudget != null) {
      score -= 22;
      reasons.add(
        '${signals.overBudget!.categoryName} is over budget, so this week needs a gentler pace.',
      );
    } else if (signals.nearBudget != null) {
      score -= 14;
      reasons.add(
        '${signals.nearBudget!.categoryName} is close to its monthly limit.',
      );
    } else if (signals.pacedBudget != null) {
      score -= 9;
      reasons.add(
        '${signals.pacedBudget!.categoryName} is ahead of its expected monthly pace.',
      );
    }

    if (signals.weeklyCategorySpike != null) {
      final spike = signals.weeklyCategorySpike!;
      score -= 18;
      reasons.add(
        '${spike.categoryName} is ${_changePercent(spike.changePercent!)} above the comparable week.',
      );
    }

    if (_isComparableIncrease(snapshot.week, 0.6)) {
      score -= 16;
      reasons.add(
        'This week\'s spending is ${_changePercent(snapshot.week.expenseChangePercent!)} above last week\'s comparable total.',
      );
    } else if (_isComparableDecrease(snapshot.week, 0.1)) {
      score += 3;
      reasons.add(
        'This week is spending less than the comparable previous week.',
      );
    }

    // The same capped movement rule is used across every Flutter platform.
    // An unavailable reconstruction contributes zero and surfaces a clear
    // fallback reason without guessing across account or currency changes.
    score += balanceMovement.moderatedImpact;
    if (balanceMovement.moderatedImpact != 0 || !balanceMovement.isReliable) {
      reasons.add(balanceMovement.reason);
    }

    return _periodScore(
      period: FinancialWindowKind.week,
      score: score,
      reasons: reasons,
      forceCritical: signals.overBudget != null || balanceImpact.forceCritical,
    );
  }

  FinancialPeriodScore _scoreMonth(
    FinancialInsightSnapshot snapshot,
    _InsightSignals signals,
  ) {
    final lifecycleCalculation = snapshot.monthlyScoreCalculation;
    if (lifecycleCalculation != null) {
      return FinancialPeriodScore(
        period: FinancialWindowKind.month,
        value: lifecycleCalculation.score,
        tone: _monthlyToneFor(lifecycleCalculation),
        reasons: lifecycleCalculation.reasons,
      );
    }

    var score = 100;
    final reasons = <String>[];
    final balanceImpact = signals.balance.impactFor(
      FinancialWindowKind.month,
      snapshot.currencyCode,
    );
    score += balanceImpact.points;
    if (balanceImpact.reason != null) reasons.add(balanceImpact.reason!);

    if (signals.overBudget != null) {
      score -= 38;
      reasons.add(
        '${signals.overBudget!.categoryName} is ${_percent(signals.overBudget!.usage - 1)} over budget.',
      );
    } else if (signals.nearBudget != null) {
      score -= 20;
      reasons.add(
        '${signals.nearBudget!.categoryName} has ${_amount(signals.nearBudget!.remaining, snapshot.currencyCode)} remaining.',
      );
    } else if (signals.pacedBudget != null) {
      score -= 12;
      reasons.add(
        '${signals.pacedBudget!.categoryName} is spending faster than its monthly plan.',
      );
    }

    if (signals.spendingOverIncome) {
      score -= 18;
      reasons.add(
        'Month-to-date spending is ${_amount(snapshot.month.expense, snapshot.currencyCode)} versus ${_amount(snapshot.month.income, snapshot.currencyCode)} income.',
      );
    } else if (snapshot.month.income >= snapshot.month.expense &&
        snapshot.month.income > 0) {
      score += 3;
      reasons.add('Income currently covers this month\'s recorded spending.');
    }

    if (_isComparableIncrease(snapshot.month, 0.4)) {
      score -= 12;
      reasons.add(
        'Month-to-date spending is ${_changePercent(snapshot.month.expenseChangePercent!)} above the comparable previous month.',
      );
    } else if (_isComparableDecrease(snapshot.month, 0.1)) {
      score += 4;
      reasons.add(
        'Month-to-date spending is lower than the comparable previous period.',
      );
    }

    return _periodScore(
      period: FinancialWindowKind.month,
      score: score,
      reasons: reasons,
      forceCritical: signals.overBudget != null || balanceImpact.forceCritical,
    );
  }

  FinancialPeriodScore _periodScore({
    required FinancialWindowKind period,
    required int score,
    required List<String> reasons,
    required bool forceCritical,
  }) {
    final maximum = period == FinancialWindowKind.month ? 150 : 100;
    final value = score.clamp(0, maximum).toInt();
    return FinancialPeriodScore(
      period: period,
      value: value,
      tone: forceCritical ? FinancialInsightTone.critical : _toneFor(value),
      reasons: reasons.isEmpty
          ? [_steadyReason(period)]
          : reasons.take(3).toList(),
    );
  }

  _InsightSignals _signals(FinancialInsightSnapshot snapshot) {
    final overBudget = _firstBudget(snapshot, (budget) => budget.usage >= 1);
    final nearBudget = _firstBudget(snapshot, (budget) => budget.usage >= .85);
    final pacedBudget = _firstBudget(snapshot, (budget) {
      final daysInMonth = DateTime(
        snapshot.generatedAt.year,
        snapshot.generatedAt.month + 1,
        0,
      ).day;
      final expectedUsage = snapshot.generatedAt.day / daysInMonth;
      return budget.usage > expectedUsage + .15;
    });

    return _InsightSignals(
      overBudget: overBudget,
      nearBudget: nearBudget,
      pacedBudget: pacedBudget,
      weeklyCategorySpike: _largestComparableSpike(snapshot),
      todaySpike: _hasTodaySpike(snapshot),
      spendingOverIncome:
          snapshot.month.income > 0 &&
          snapshot.month.expense > snapshot.month.income * 1.1,
      balance: _balanceBuffer(snapshot),
    );
  }

  _BalanceBuffer _balanceBuffer(FinancialInsightSnapshot snapshot) {
    final position = snapshot.balance;
    if (position.activeAccountCount == 0) {
      return const _BalanceBuffer.unavailable();
    }
    if (position.totalBalance < 0) {
      return const _BalanceBuffer.negative();
    }
    if (position.totalBalance == 0 && snapshot.hasActivity) {
      return const _BalanceBuffer.empty();
    }

    // A user's own recent daily pace makes the balance evaluation meaningful
    // across LAK, THB, USD, and any other supported currency.
    final monthDailyPace =
        snapshot.month.expense / snapshot.generatedAt.day.clamp(1, 31);
    final weekDailyPace =
        snapshot.week.expense / snapshot.generatedAt.weekday.clamp(1, 7);
    final dailyPace = monthDailyPace > weekDailyPace
        ? monthDailyPace
        : weekDailyPace;
    if (dailyPace <= 0) return const _BalanceBuffer.unavailable();

    final daysCovered = position.totalBalance / dailyPace;
    if (daysCovered < 3) return _BalanceBuffer.thin(daysCovered);
    if (daysCovered < 7) return _BalanceBuffer.limited(daysCovered);
    if (daysCovered >= 30) return _BalanceBuffer.healthy(daysCovered);
    return _BalanceBuffer.steady(daysCovered);
  }

  FinancialInsight _emptyInsight(FinancialInsightSnapshot snapshot) {
    FinancialPeriodScore emptyScore(FinancialWindowKind period) {
      return FinancialPeriodScore(
        period: period,
        value: 75,
        tone: FinancialInsightTone.watch,
        reasons: [
          'There is not enough recent activity to score this ${_periodLabel(period).toLowerCase()} trend yet.',
        ],
      );
    }

    final todayScore = emptyScore(FinancialWindowKind.today);
    final lifecycleCalculation = snapshot.monthlyScoreCalculation;
    final monthScore = lifecycleCalculation == null
        ? emptyScore(FinancialWindowKind.month)
        : FinancialPeriodScore(
            period: FinancialWindowKind.month,
            value: lifecycleCalculation.score,
            tone: _monthlyToneFor(lifecycleCalculation),
            reasons: lifecycleCalculation.reasons,
          );
    return FinancialInsight(
      currencyCode: snapshot.currencyCode,
      totalBalance: snapshot.balance.totalBalance,
      todayScore: todayScore,
      weekScore: emptyScore(FinancialWindowKind.week),
      monthScore: monthScore,
      tone: FinancialInsightTone.watch,
      headline: 'Let\'s build your first spending pattern.',
      explanation:
          'Add a few income or expense entries and Cashly will turn them into personal daily, weekly, and monthly check-ins.',
      scoreReasons: monthScore.reasons,
      actions: const [
        FinancialInsightAction(
          title: 'Log your next expense',
          detail:
              'Even a small everyday purchase gives the assistant a better starting point.',
        ),
      ],
      today: snapshot.today,
      week: snapshot.week,
      month: snapshot.month,
      monthlyScoreCalculation: snapshot.monthlyScoreCalculation,
      budgets: snapshot.budgets,
    );
  }

  FinancialBudgetStatus? _firstBudget(
    FinancialInsightSnapshot snapshot,
    bool Function(FinancialBudgetStatus budget) predicate,
  ) {
    final matches = snapshot.budgets.where(predicate).toList()
      ..sort((a, b) => b.usage.compareTo(a.usage));
    return matches.isEmpty ? null : matches.first;
  }

  FinancialCategoryTrend? _largestComparableSpike(
    FinancialInsightSnapshot snapshot,
  ) {
    final monthExpense = snapshot.month.expense;
    final spikes = snapshot.categoryTrends.where((trend) {
      final change = trend.changePercent;
      return change != null &&
          change >= 60 &&
          trend.currentExpense >= monthExpense * .2;
    }).toList()..sort((a, b) => b.changePercent!.compareTo(a.changePercent!));
    return spikes.isEmpty ? null : spikes.first;
  }

  bool _hasTodaySpike(FinancialInsightSnapshot snapshot) {
    final elapsedWeekDays = snapshot.generatedAt.weekday;
    if (elapsedWeekDays <= 1 || snapshot.week.expense <= 0) return false;
    final earlierWeekExpense = snapshot.week.expense - snapshot.today.expense;
    final average = earlierWeekExpense / (elapsedWeekDays - 1);
    return average > 0 && snapshot.today.expense > average * 2;
  }

  bool _isComparableIncrease(
    FinancialSpendingWindow window,
    double threshold,
  ) =>
      window.expenseChangePercent != null &&
      window.expenseChangePercent! >= threshold * 100;

  bool _isComparableDecrease(
    FinancialSpendingWindow window,
    double threshold,
  ) =>
      window.expenseChangePercent != null &&
      window.expenseChangePercent! <= -threshold * 100;

  FinancialInsightTone _toneFor(int score) => switch (score) {
    >= 86 => FinancialInsightTone.positive,
    >= 70 => FinancialInsightTone.watch,
    >= 50 => FinancialInsightTone.caution,
    _ => FinancialInsightTone.critical,
  };

  FinancialInsightTone _monthlyToneFor(SmartMoneyScoreCalculation calculation) {
    if (!calculation.isReliable) return FinancialInsightTone.watch;
    return switch (calculation.score) {
      >= 105 => FinancialInsightTone.positive,
      >= 95 => FinancialInsightTone.watch,
      >= 75 => FinancialInsightTone.caution,
      _ => FinancialInsightTone.critical,
    };
  }

  String _steadyReason(FinancialWindowKind period) => switch (period) {
    FinancialWindowKind.today => 'Today is within a healthy spending pace.',
    FinancialWindowKind.week =>
      'This week is tracking close to your recent pace.',
    FinancialWindowKind.month =>
      'This month is within the plan recorded in Cashly.',
  };

  String _periodLabel(FinancialWindowKind period) => switch (period) {
    FinancialWindowKind.today => 'Today',
    FinancialWindowKind.week => 'Week',
    FinancialWindowKind.month => 'Month',
  };

  String _amount(double value, String currencyCode) =>
      '${value.toStringAsFixed(currencyCode == 'LAK' || currencyCode == 'THB' ? 0 : 2)} $currencyCode';

  String _percent(double value) => '${(value * 100).round()}%';

  String _changePercent(double value) => '${value.round()}%';
}

class _InsightSignals {
  const _InsightSignals({
    required this.overBudget,
    required this.nearBudget,
    required this.pacedBudget,
    required this.weeklyCategorySpike,
    required this.todaySpike,
    required this.spendingOverIncome,
    required this.balance,
  });

  final FinancialBudgetStatus? overBudget;
  final FinancialBudgetStatus? nearBudget;
  final FinancialBudgetStatus? pacedBudget;
  final FinancialCategoryTrend? weeklyCategorySpike;
  final bool todaySpike;
  final bool spendingOverIncome;
  final _BalanceBuffer balance;
}

enum _BalanceHealth {
  unavailable,
  negative,
  empty,
  thin,
  limited,
  steady,
  healthy,
}

/// A currency-safe reading of the user's active-account buffer.
///
/// This remains an internal rule-engine concern. A future LLM receives the
/// same aggregated balance through [FinancialInsightSnapshot] and can choose
/// its own narrative without changing the UI contract.
class _BalanceBuffer {
  const _BalanceBuffer._({required this.health, this.daysCovered});

  const _BalanceBuffer.unavailable()
    : this._(health: _BalanceHealth.unavailable);

  const _BalanceBuffer.empty() : this._(health: _BalanceHealth.empty);

  const _BalanceBuffer.negative() : this._(health: _BalanceHealth.negative);

  const _BalanceBuffer.thin(double daysCovered)
    : this._(health: _BalanceHealth.thin, daysCovered: daysCovered);

  const _BalanceBuffer.limited(double daysCovered)
    : this._(health: _BalanceHealth.limited, daysCovered: daysCovered);

  const _BalanceBuffer.steady(double daysCovered)
    : this._(health: _BalanceHealth.steady, daysCovered: daysCovered);

  const _BalanceBuffer.healthy(double daysCovered)
    : this._(health: _BalanceHealth.healthy, daysCovered: daysCovered);

  final _BalanceHealth health;
  final double? daysCovered;

  bool get isNegative => health == _BalanceHealth.negative;

  bool get needsAttention => switch (health) {
    _BalanceHealth.empty ||
    _BalanceHealth.thin ||
    _BalanceHealth.limited => true,
    _ => false,
  };

  FinancialInsightTone get attentionTone => switch (health) {
    _BalanceHealth.empty || _BalanceHealth.thin => FinancialInsightTone.caution,
    _BalanceHealth.limited => FinancialInsightTone.watch,
    _ => FinancialInsightTone.positive,
  };

  String get attentionHeadline => switch (health) {
    _BalanceHealth.empty => 'Your available balance is at zero.',
    _BalanceHealth.thin => 'Your balance buffer is getting tight.',
    _BalanceHealth.limited => 'Your balance could use a little more room.',
    _ => 'Your balance is looking steady.',
  };

  String attentionExplanation(String currencyCode) => switch (health) {
    _BalanceHealth.empty =>
      'There is no $currencyCode buffer left after recent activity. Choosing the next expense carefully can help create room again.',
    _BalanceHealth.thin =>
      'At your recent spending pace, this $currencyCode balance covers about $_wholeDays days. Protecting one essential expense first can help.',
    _BalanceHealth.limited =>
      'At your recent spending pace, this $currencyCode balance covers about $_wholeDays days. A small rest-of-week plan can preserve that room.',
    _ => 'Your balance is supporting your current pace.',
  };

  FinancialInsightAction get practicalAction => switch (health) {
    _BalanceHealth.empty => const FinancialInsightAction(
      title: 'Protect the next essential expense',
      detail:
          'Choosing the next necessary cost first can help create space before adding anything optional.',
    ),
    _BalanceHealth.thin => FinancialInsightAction(
      title: 'Reserve the next $_wholeDays days of essentials',
      detail:
          'Keeping that small buffer for needs first gives your balance more room to recover.',
    ),
    _BalanceHealth.limited => const FinancialInsightAction(
      title: 'Set a short rest-of-week limit',
      detail:
          'A small limit for flexible spending can keep your current balance working for longer.',
    ),
    _ => const FinancialInsightAction(
      title: 'Keep your next expense intentional',
      detail:
          'Your balance is supporting the current pace. A quick check before spending helps it stay that way.',
    ),
  };

  _BalanceScoreImpact impactFor(
    FinancialWindowKind period,
    String currencyCode,
  ) {
    final points = switch (health) {
      _BalanceHealth.negative => switch (period) {
        FinancialWindowKind.today => -32,
        FinancialWindowKind.week => -36,
        FinancialWindowKind.month => -40,
      },
      _BalanceHealth.empty => switch (period) {
        FinancialWindowKind.today => -14,
        FinancialWindowKind.week => -16,
        FinancialWindowKind.month => -18,
      },
      _BalanceHealth.thin => switch (period) {
        FinancialWindowKind.today => -10,
        FinancialWindowKind.week => -12,
        FinancialWindowKind.month => -14,
      },
      _BalanceHealth.limited => switch (period) {
        FinancialWindowKind.today => -5,
        FinancialWindowKind.week => -6,
        FinancialWindowKind.month => -7,
      },
      _BalanceHealth.healthy => switch (period) {
        FinancialWindowKind.today => 2,
        FinancialWindowKind.week => 3,
        FinancialWindowKind.month => 4,
      },
      _ => 0,
    };

    final reason = switch (health) {
      _BalanceHealth.negative =>
        'Your total $currencyCode balance is below zero, so rebuilding a positive buffer is the priority.',
      _BalanceHealth.empty =>
        'Your active $currencyCode balance is at zero after recent activity.',
      _BalanceHealth.thin =>
        'Your total $currencyCode balance covers about $_wholeDays days at your recent spending pace.',
      _BalanceHealth.limited =>
        'Your total $currencyCode balance covers about $_wholeDays days at your recent spending pace.',
      _BalanceHealth.healthy =>
        'Your total $currencyCode balance covers more than a month at your recent spending pace.',
      _ => null,
    };

    return _BalanceScoreImpact(
      points: points,
      reason: reason,
      forceCritical: health == _BalanceHealth.negative,
    );
  }

  int get _wholeDays => (daysCovered ?? 0).ceil().clamp(1, 999).toInt();
}

class _BalanceScoreImpact {
  const _BalanceScoreImpact({
    required this.points,
    required this.reason,
    required this.forceCritical,
  });

  final int points;
  final String? reason;
  final bool forceCritical;
}
