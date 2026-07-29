import '../entities/financial_insight.dart';
import '../entities/financial_insight_message.dart';
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
    var headline = const FinancialInsightMessage(
      FinancialInsightMessageKey.steadySpendingHeadline,
    );
    var explanation = const FinancialInsightMessage(
      FinancialInsightMessageKey.steadySpendingExplanation,
    );
    final actions = <FinancialInsightAction>[];

    if (signals.balance.isNegative) {
      narrativeTone = FinancialInsightTone.critical;
      headline = const FinancialInsightMessage(
        FinancialInsightMessageKey.negativeBalanceHeadline,
      );
      explanation = FinancialInsightMessage(
        FinancialInsightMessageKey.negativeBalanceExplanation,
        {
          'currency': snapshot.currencyCode,
          'amount': _amount(
            snapshot.balance.totalBalance,
            snapshot.currencyCode,
          ),
        },
      );
      actions.add(
        const FinancialInsightAction(
          title: FinancialInsightMessage(
            FinancialInsightMessageKey.planEssentialExpenseTitle,
          ),
          detail: FinancialInsightMessage(
            FinancialInsightMessageKey.planEssentialExpenseDetail,
          ),
        ),
      );
    } else if (signals.overBudget != null) {
      final budget = signals.overBudget!;
      narrativeTone = FinancialInsightTone.critical;
      headline = FinancialInsightMessage(
        FinancialInsightMessageKey.categoryOverBudgetHeadline,
        {'category': budget.categoryName},
      );
      explanation = FinancialInsightMessage(
        FinancialInsightMessageKey.categoryOverBudgetExplanation,
        {
          'spent': _amount(budget.spent, snapshot.currencyCode),
          'limit': _amount(budget.limit, snapshot.currencyCode),
        },
      );
      actions.add(
        FinancialInsightAction(
          title: FinancialInsightMessage(
            FinancialInsightMessageKey.pauseCategorySpendingTitle,
            {'category': budget.categoryName},
          ),
          detail: const FinancialInsightMessage(
            FinancialInsightMessageKey.pauseCategorySpendingDetail,
          ),
        ),
      );
    } else if (signals.nearBudget != null || signals.pacedBudget != null) {
      final budget = signals.nearBudget ?? signals.pacedBudget!;
      narrativeTone = FinancialInsightTone.caution;
      headline = FinancialInsightMessage(
        FinancialInsightMessageKey.categoryNeedsRoomHeadline,
        {'category': budget.categoryName},
      );
      explanation = FinancialInsightMessage(
        FinancialInsightMessageKey.categoryNeedsRoomExplanation,
        {
          'percent': _percent(budget.usage),
          'limit': _amount(budget.limit, snapshot.currencyCode),
        },
      );
      actions.add(
        FinancialInsightAction(
          title: FinancialInsightMessage(
            FinancialInsightMessageKey.setRestOfMonthLimitTitle,
            {'category': budget.categoryName},
          ),
          detail: FinancialInsightMessage(
            FinancialInsightMessageKey.setRestOfMonthLimitDetail,
            {'remaining': _amount(budget.remaining, snapshot.currencyCode)},
          ),
        ),
      );
    }

    if (signals.weeklyCategorySpike != null) {
      final spike = signals.weeklyCategorySpike!;
      if (narrativeTone == FinancialInsightTone.positive) {
        narrativeTone = FinancialInsightTone.watch;
        headline = FinancialInsightMessage(
          FinancialInsightMessageKey.categoryHigherThanUsualHeadline,
          {'category': spike.categoryName},
        );
        explanation = FinancialInsightMessage(
          FinancialInsightMessageKey.categoryHigherThanUsualExplanation,
          {'changePercent': _changePercent(spike.changePercent!)},
        );
      }
      actions.add(
        FinancialInsightAction(
          title: FinancialInsightMessage(
            FinancialInsightMessageKey.reviewNextCategoryPurchaseTitle,
            {'category': spike.categoryName},
          ),
          detail: const FinancialInsightMessage(
            FinancialInsightMessageKey.reviewNextCategoryPurchaseDetail,
          ),
        ),
      );
    } else if (signals.todaySpike) {
      if (narrativeTone == FinancialInsightTone.positive) {
        narrativeTone = FinancialInsightTone.watch;
        headline = const FinancialInsightMessage(
          FinancialInsightMessageKey.todaySpendingFasterHeadline,
        );
        explanation = const FinancialInsightMessage(
          FinancialInsightMessageKey.todaySpendingFasterExplanation,
        );
      }
      actions.add(
        const FinancialInsightAction(
          title: FinancialInsightMessage(
            FinancialInsightMessageKey.checkNextExpenseTitle,
          ),
          detail: FinancialInsightMessage(
            FinancialInsightMessageKey.checkNextExpenseDetail,
          ),
        ),
      );
    }

    if (signals.spendingOverIncome) {
      if (narrativeTone == FinancialInsightTone.positive) {
        narrativeTone = FinancialInsightTone.watch;
        headline = const FinancialInsightMessage(
          FinancialInsightMessageKey.spendingAheadOfIncomeHeadline,
        );
        explanation = const FinancialInsightMessage(
          FinancialInsightMessageKey.spendingAheadOfIncomeExplanation,
        );
      }
      actions.add(
        const FinancialInsightAction(
          title: FinancialInsightMessage(
            FinancialInsightMessageKey.chooseLowPriorityExpenseTitle,
          ),
          detail: FinancialInsightMessage(
            FinancialInsightMessageKey.chooseLowPriorityExpenseDetail,
          ),
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
          title: FinancialInsightMessage(
            FinancialInsightMessageKey.keepExpenseIntentionalTitle,
          ),
          detail: FinancialInsightMessage(
            FinancialInsightMessageKey.keepExpenseIntentionalPaceDetail,
          ),
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
    final reasons = <FinancialInsightMessage>[];
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
        FinancialInsightMessage(
          FinancialInsightMessageKey.categoryOverBudgetReasonToday,
          {'category': signals.overBudget!.categoryName},
        ),
      );
    } else if (signals.nearBudget != null) {
      score -= 12;
      reasons.add(
        FinancialInsightMessage(
          FinancialInsightMessageKey.categoryNearBudgetReasonToday,
          {'category': signals.nearBudget!.categoryName},
        ),
      );
    }

    if (signals.todaySpike) {
      score -= 20;
      reasons.add(
        const FinancialInsightMessage(
          FinancialInsightMessageKey.todaySpikeReason,
        ),
      );
    } else if (_isComparableIncrease(snapshot.today, 0.6)) {
      score -= 12;
      reasons.add(
        FinancialInsightMessage(
          FinancialInsightMessageKey.todayComparableIncreaseReason,
          {
            'changePercent': _changePercent(
              snapshot.today.expenseChangePercent!,
            ),
          },
        ),
      );
    }

    if (snapshot.today.expense == 0 && snapshot.today.income == 0) {
      reasons.add(
        const FinancialInsightMessage(
          FinancialInsightMessageKey.noActivityTodayReason,
        ),
      );
    } else if (snapshot.today.income >= snapshot.today.expense &&
        snapshot.today.income > 0) {
      score += 2;
      reasons.add(
        const FinancialInsightMessage(
          FinancialInsightMessageKey.incomeCoversTodayReason,
        ),
      );
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
    final reasons = <FinancialInsightMessage>[];
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
        FinancialInsightMessage(
          FinancialInsightMessageKey.categoryOverBudgetReasonWeek,
          {'category': signals.overBudget!.categoryName},
        ),
      );
    } else if (signals.nearBudget != null) {
      score -= 14;
      reasons.add(
        FinancialInsightMessage(
          FinancialInsightMessageKey.categoryNearBudgetReasonWeek,
          {'category': signals.nearBudget!.categoryName},
        ),
      );
    } else if (signals.pacedBudget != null) {
      score -= 9;
      reasons.add(
        FinancialInsightMessage(
          FinancialInsightMessageKey.categoryPacedBudgetReasonWeek,
          {'category': signals.pacedBudget!.categoryName},
        ),
      );
    }

    if (signals.weeklyCategorySpike != null) {
      final spike = signals.weeklyCategorySpike!;
      score -= 18;
      reasons.add(
        FinancialInsightMessage(
          FinancialInsightMessageKey.weeklyCategorySpikeReason,
          {
            'category': spike.categoryName,
            'changePercent': _changePercent(spike.changePercent!),
          },
        ),
      );
    }

    if (_isComparableIncrease(snapshot.week, 0.6)) {
      score -= 16;
      reasons.add(
        FinancialInsightMessage(
          FinancialInsightMessageKey.weekComparableIncreaseReason,
          {
            'changePercent': _changePercent(
              snapshot.week.expenseChangePercent!,
            ),
          },
        ),
      );
    } else if (_isComparableDecrease(snapshot.week, 0.1)) {
      score += 3;
      reasons.add(
        const FinancialInsightMessage(
          FinancialInsightMessageKey.weekComparableDecreaseReason,
        ),
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
        // The persisted calculation's reasons are an auditable historical
        // record kept in English by design (see CLAUDE.md's Phase 2a entry)
        // — rendered verbatim via the `literal` passthrough rather than
        // mapped onto a localizable key.
        reasons: lifecycleCalculation.reasons
            .map(FinancialInsightMessage.literal)
            .toList(),
      );
    }

    var score = 100;
    final reasons = <FinancialInsightMessage>[];
    final balanceImpact = signals.balance.impactFor(
      FinancialWindowKind.month,
      snapshot.currencyCode,
    );
    score += balanceImpact.points;
    if (balanceImpact.reason != null) reasons.add(balanceImpact.reason!);

    if (signals.overBudget != null) {
      score -= 38;
      reasons.add(
        FinancialInsightMessage(
          FinancialInsightMessageKey.categoryOverBudgetReasonMonth,
          {
            'category': signals.overBudget!.categoryName,
            'percent': _percent(signals.overBudget!.usage - 1),
          },
        ),
      );
    } else if (signals.nearBudget != null) {
      score -= 20;
      reasons.add(
        FinancialInsightMessage(
          FinancialInsightMessageKey.categoryNearBudgetReasonMonth,
          {
            'category': signals.nearBudget!.categoryName,
            'remaining': _amount(
              signals.nearBudget!.remaining,
              snapshot.currencyCode,
            ),
          },
        ),
      );
    } else if (signals.pacedBudget != null) {
      score -= 12;
      reasons.add(
        FinancialInsightMessage(
          FinancialInsightMessageKey.categoryPacedBudgetReasonMonth,
          {'category': signals.pacedBudget!.categoryName},
        ),
      );
    }

    if (signals.spendingOverIncome) {
      score -= 18;
      reasons.add(
        FinancialInsightMessage(
          FinancialInsightMessageKey.spendingOverIncomeReasonMonth,
          {
            'expense': _amount(snapshot.month.expense, snapshot.currencyCode),
            'income': _amount(snapshot.month.income, snapshot.currencyCode),
          },
        ),
      );
    } else if (snapshot.month.income >= snapshot.month.expense &&
        snapshot.month.income > 0) {
      score += 3;
      reasons.add(
        const FinancialInsightMessage(
          FinancialInsightMessageKey.incomeCoversMonthReason,
        ),
      );
    }

    if (_isComparableIncrease(snapshot.month, 0.4)) {
      score -= 12;
      reasons.add(
        FinancialInsightMessage(
          FinancialInsightMessageKey.monthComparableIncreaseReason,
          {
            'changePercent': _changePercent(
              snapshot.month.expenseChangePercent!,
            ),
          },
        ),
      );
    } else if (_isComparableDecrease(snapshot.month, 0.1)) {
      score += 4;
      reasons.add(
        const FinancialInsightMessage(
          FinancialInsightMessageKey.monthComparableDecreaseReason,
        ),
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
    required List<FinancialInsightMessage> reasons,
    required bool forceCritical,
  }) {
    final maximum = period == FinancialWindowKind.month ? 150 : 100;
    final value = score.clamp(0, maximum).toInt();
    return FinancialPeriodScore(
      period: period,
      value: value,
      tone: forceCritical ? FinancialInsightTone.critical : _toneFor(value),
      reasons: reasons.isEmpty
          ? [FinancialInsightMessage(_steadyReasonKey(period))]
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
    FinancialPeriodScore emptyScore(
      FinancialWindowKind period,
      FinancialInsightMessageKey reasonKey,
    ) {
      return FinancialPeriodScore(
        period: period,
        value: 75,
        tone: FinancialInsightTone.watch,
        reasons: [FinancialInsightMessage(reasonKey)],
      );
    }

    final todayScore = emptyScore(
      FinancialWindowKind.today,
      FinancialInsightMessageKey.notEnoughActivityTodayReason,
    );
    final lifecycleCalculation = snapshot.monthlyScoreCalculation;
    final monthScore = lifecycleCalculation == null
        ? emptyScore(
            FinancialWindowKind.month,
            FinancialInsightMessageKey.notEnoughActivityMonthReason,
          )
        : FinancialPeriodScore(
            period: FinancialWindowKind.month,
            value: lifecycleCalculation.score,
            tone: _monthlyToneFor(lifecycleCalculation),
            reasons: lifecycleCalculation.reasons
                .map(FinancialInsightMessage.literal)
                .toList(),
          );
    return FinancialInsight(
      currencyCode: snapshot.currencyCode,
      totalBalance: snapshot.balance.totalBalance,
      todayScore: todayScore,
      weekScore: emptyScore(
        FinancialWindowKind.week,
        FinancialInsightMessageKey.notEnoughActivityWeekReason,
      ),
      monthScore: monthScore,
      tone: FinancialInsightTone.watch,
      headline: const FinancialInsightMessage(
        FinancialInsightMessageKey.onboardingHeadline,
      ),
      explanation: const FinancialInsightMessage(
        FinancialInsightMessageKey.onboardingExplanation,
      ),
      scoreReasons: monthScore.reasons,
      actions: const [
        FinancialInsightAction(
          title: FinancialInsightMessage(
            FinancialInsightMessageKey.logNextExpenseTitle,
          ),
          detail: FinancialInsightMessage(
            FinancialInsightMessageKey.logNextExpenseDetail,
          ),
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

  FinancialInsightMessageKey _steadyReasonKey(
    FinancialWindowKind period,
  ) => switch (period) {
    FinancialWindowKind.today => FinancialInsightMessageKey.steadyReasonToday,
    FinancialWindowKind.week => FinancialInsightMessageKey.steadyReasonWeek,
    FinancialWindowKind.month => FinancialInsightMessageKey.steadyReasonMonth,
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

  FinancialInsightMessage get attentionHeadline => switch (health) {
    _BalanceHealth.empty => const FinancialInsightMessage(
      FinancialInsightMessageKey.balanceZeroHeadline,
    ),
    _BalanceHealth.thin => const FinancialInsightMessage(
      FinancialInsightMessageKey.balanceThinHeadline,
    ),
    _BalanceHealth.limited => const FinancialInsightMessage(
      FinancialInsightMessageKey.balanceLimitedHeadline,
    ),
    _ => const FinancialInsightMessage(
      FinancialInsightMessageKey.balanceSteadyHeadline,
    ),
  };

  FinancialInsightMessage attentionExplanation(String currencyCode) =>
      switch (health) {
        _BalanceHealth.empty => FinancialInsightMessage(
          FinancialInsightMessageKey.balanceZeroExplanation,
          {'currency': currencyCode},
        ),
        _BalanceHealth.thin => FinancialInsightMessage(
          FinancialInsightMessageKey.balanceThinExplanation,
          {'currency': currencyCode, 'days': _wholeDays},
        ),
        _BalanceHealth.limited => FinancialInsightMessage(
          FinancialInsightMessageKey.balanceLimitedExplanation,
          {'currency': currencyCode, 'days': _wholeDays},
        ),
        _ => const FinancialInsightMessage(
          FinancialInsightMessageKey.balanceSteadyExplanation,
        ),
      };

  FinancialInsightAction get practicalAction => switch (health) {
    _BalanceHealth.empty => const FinancialInsightAction(
      title: FinancialInsightMessage(
        FinancialInsightMessageKey.protectEssentialExpenseTitle,
      ),
      detail: FinancialInsightMessage(
        FinancialInsightMessageKey.protectEssentialExpenseDetail,
      ),
    ),
    _BalanceHealth.thin => FinancialInsightAction(
      title: FinancialInsightMessage(
        FinancialInsightMessageKey.reserveNextDaysTitle,
        {'days': _wholeDays},
      ),
      detail: const FinancialInsightMessage(
        FinancialInsightMessageKey.reserveNextDaysDetail,
      ),
    ),
    _BalanceHealth.limited => const FinancialInsightAction(
      title: FinancialInsightMessage(
        FinancialInsightMessageKey.setShortRestOfWeekLimitTitle,
      ),
      detail: FinancialInsightMessage(
        FinancialInsightMessageKey.setShortRestOfWeekLimitDetail,
      ),
    ),
    _ => const FinancialInsightAction(
      title: FinancialInsightMessage(
        FinancialInsightMessageKey.keepExpenseIntentionalTitle,
      ),
      detail: FinancialInsightMessage(
        FinancialInsightMessageKey.keepExpenseIntentionalBalanceDetail,
      ),
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
      _BalanceHealth.negative => FinancialInsightMessage(
        FinancialInsightMessageKey.balanceImpactNegativeReason,
        {'currency': currencyCode},
      ),
      _BalanceHealth.empty => FinancialInsightMessage(
        FinancialInsightMessageKey.balanceImpactEmptyReason,
        {'currency': currencyCode},
      ),
      _BalanceHealth.thin => FinancialInsightMessage(
        FinancialInsightMessageKey.balanceImpactLowReason,
        {'currency': currencyCode, 'days': _wholeDays},
      ),
      _BalanceHealth.limited => FinancialInsightMessage(
        FinancialInsightMessageKey.balanceImpactLowReason,
        {'currency': currencyCode, 'days': _wholeDays},
      ),
      _BalanceHealth.healthy => FinancialInsightMessage(
        FinancialInsightMessageKey.balanceImpactHealthyReason,
        {'currency': currencyCode},
      ),
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
  final FinancialInsightMessage? reason;
  final bool forceCritical;
}
