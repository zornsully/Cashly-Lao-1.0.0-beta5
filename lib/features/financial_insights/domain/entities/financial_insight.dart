import 'package:equatable/equatable.dart';

import 'financial_insight_message.dart';
import 'smart_money_score.dart';

/// The attention level of an insight. It informs presentation only; the
/// underlying score and reasons remain available to any future assistant.
enum FinancialInsightTone { positive, watch, caution, critical }

enum FinancialWindowKind { today, week, month }

/// An explainable score for one financial time window.
///
/// Keeping a score's window, tone, and reasons together means a future LLM
/// can return the same structured result without changing the dashboard UI.
class FinancialPeriodScore extends Equatable {
  const FinancialPeriodScore({
    required this.period,
    required this.value,
    required this.tone,
    required this.reasons,
  }) : assert(
         value >= 0 &&
             value <= (period == FinancialWindowKind.month ? 150 : 100),
       );

  final FinancialWindowKind period;
  final int value;
  final FinancialInsightTone tone;
  final List<FinancialInsightMessage> reasons;

  /// Today and week are short-horizon health scores. The monthly score is a
  /// balance-growth score and intentionally has room above 100.
  int get maximum => period == FinancialWindowKind.month ? 150 : 100;

  @override
  List<Object?> get props => [period, value, tone, reasons];
}

/// Spending in a current period alongside the comparable previous period.
class FinancialSpendingWindow extends Equatable {
  const FinancialSpendingWindow({
    required this.kind,
    required this.expense,
    required this.income,
    required this.previousExpense,
    required this.transactionCount,
  });

  final FinancialWindowKind kind;
  final double expense;
  final double income;
  final double previousExpense;
  final int transactionCount;

  double? get expenseChangePercent {
    if (previousExpense <= 0) return null;
    return ((expense - previousExpense) / previousExpense) * 100;
  }

  @override
  List<Object?> get props => [
    kind,
    expense,
    income,
    previousExpense,
    transactionCount,
  ];
}

/// Category-level movement used to detect meaningful changes in behaviour.
class FinancialCategoryTrend extends Equatable {
  const FinancialCategoryTrend({
    required this.categoryId,
    required this.categoryName,
    required this.currentExpense,
    required this.previousExpense,
    required this.monthExpense,
  });

  final String categoryId;
  final String categoryName;
  final double currentExpense;
  final double previousExpense;
  final double monthExpense;

  double? get changePercent {
    if (previousExpense <= 0) return null;
    return ((currentExpense - previousExpense) / previousExpense) * 100;
  }

  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    currentExpense,
    previousExpense,
    monthExpense,
  ];
}

/// A current-month budget and its actual progress. This is calculated, not
/// persisted, so the assistant never has a second source of truth.
class FinancialBudgetStatus extends Equatable {
  const FinancialBudgetStatus({
    required this.categoryId,
    required this.categoryName,
    required this.limit,
    required this.spent,
  });

  final String categoryId;
  final String categoryName;
  final double limit;
  final double spent;

  double get usage => limit == 0 ? 0 : spent / limit;
  double get remaining => limit - spent;

  @override
  List<Object?> get props => [categoryId, categoryName, limit, spent];
}

/// The active-account balance available for one currency.
///
/// It is deliberately a per-currency aggregate: a LAK account and a USD
/// account are never added together. Keeping this in the engine input lets a
/// future assistant account for a user's financial buffer without receiving
/// account names or individual balances.
class FinancialBalancePosition extends Equatable {
  const FinancialBalancePosition({
    required this.totalBalance,
    required this.activeAccountCount,
    this.hasCrossCurrencyTransfer = false,
    this.hasAccountCreatedThisMonth = false,
    this.hasCrossCurrencyTransferToday = false,
    this.hasCrossCurrencyTransferThisWeek = false,
    this.hasAccountCreatedToday = false,
    this.hasAccountCreatedThisWeek = false,
  });

  final double totalBalance;
  final int activeAccountCount;

  /// A transfer between accounts with different currencies has no recorded
  /// exchange rate in the transaction model. It is excluded from score
  /// reconstruction rather than treated as income, expense, or growth.
  final bool hasCrossCurrencyTransfer;

  /// Existing account records do not retain an immutable initial balance.
  /// If an account was created after the month began, a true opening balance
  /// cannot be reconstructed from current data alone.
  final bool hasAccountCreatedThisMonth;

  /// Period-specific safeguards for derived Today and Week balance movement.
  /// A cross-currency transfer that happened earlier in the week does not
  /// make a later day comparison unsafe, so these remain separate from the
  /// current-month flag used by the persistent monthly lifecycle.
  final bool hasCrossCurrencyTransferToday;
  final bool hasCrossCurrencyTransferThisWeek;

  /// The account set must be stable over a reconstructed window. These
  /// flags deliberately use the same period boundaries as the insight
  /// snapshot rather than treating every account added this month as unsafe
  /// for a later daily comparison.
  final bool hasAccountCreatedToday;
  final bool hasAccountCreatedThisWeek;

  bool get isNegative => totalBalance < 0;

  @override
  List<Object?> get props => [
    totalBalance,
    activeAccountCount,
    hasCrossCurrencyTransfer,
    hasAccountCreatedThisMonth,
    hasCrossCurrencyTransferToday,
    hasCrossCurrencyTransferThisWeek,
    hasAccountCreatedToday,
    hasAccountCreatedThisWeek,
  ];
}

/// Aggregated, currency-safe input for an insight engine.
///
/// A remote LLM implementation can accept this object without receiving raw
/// transaction notes or account names, which keeps the integration private by
/// default and makes the local rule engine directly replaceable.
class FinancialInsightSnapshot extends Equatable {
  const FinancialInsightSnapshot({
    required this.generatedAt,
    required this.currencyCode,
    required this.today,
    required this.week,
    required this.month,
    required this.categoryTrends,
    required this.budgets,
    required this.balance,
    this.monthlyScoreCalculation,
  });

  final DateTime generatedAt;
  final String currencyCode;
  final FinancialSpendingWindow today;
  final FinancialSpendingWindow week;
  final FinancialSpendingWindow month;
  final List<FinancialCategoryTrend> categoryTrends;
  final List<FinancialBudgetStatus> budgets;
  final FinancialBalancePosition balance;

  /// Produced by the shared Smart Money Score lifecycle before an engine
  /// generates its narrative. It is optional while old/offline data is being
  /// migrated; the rule engine has a safe legacy fallback for that state.
  final SmartMoneyScoreCalculation? monthlyScoreCalculation;

  /// Transfers are intentionally excluded: scoring needs a recorded income
  /// or expense rather than a movement between the user's own accounts.
  bool get hasActivity => [
    today,
    week,
    month,
  ].any((window) => window.expense > 0 || window.income > 0);

  bool get hasNegativeBalance => balance.isNegative;

  @override
  List<Object?> get props => [
    generatedAt,
    currencyCode,
    today,
    week,
    month,
    categoryTrends,
    budgets,
    balance,
    monthlyScoreCalculation,
  ];

  FinancialInsightSnapshot copyWith({
    SmartMoneyScoreCalculation? monthlyScoreCalculation,
  }) {
    return FinancialInsightSnapshot(
      generatedAt: generatedAt,
      currencyCode: currencyCode,
      today: today,
      week: week,
      month: month,
      categoryTrends: categoryTrends,
      budgets: budgets,
      balance: balance,
      monthlyScoreCalculation:
          monthlyScoreCalculation ?? this.monthlyScoreCalculation,
    );
  }
}

class FinancialInsightAction extends Equatable {
  const FinancialInsightAction({required this.title, required this.detail});

  final FinancialInsightMessage title;
  final FinancialInsightMessage detail;

  @override
  List<Object?> get props => [title, detail];
}

/// A user-facing result from a financial insight engine.
class FinancialInsight extends Equatable {
  const FinancialInsight({
    required this.currencyCode,
    required this.totalBalance,
    required this.todayScore,
    required this.weekScore,
    required this.monthScore,
    required this.tone,
    required this.headline,
    required this.explanation,
    required this.scoreReasons,
    required this.actions,
    required this.today,
    required this.week,
    required this.month,
    this.monthlyScoreCalculation,
    this.budgets = const [],
  });

  final String currencyCode;
  final double totalBalance;
  final FinancialPeriodScore todayScore;
  final FinancialPeriodScore weekScore;
  final FinancialPeriodScore monthScore;
  final FinancialInsightTone tone;
  final FinancialInsightMessage headline;
  final FinancialInsightMessage explanation;
  final List<FinancialInsightMessage> scoreReasons;
  final List<FinancialInsightAction> actions;
  final FinancialSpendingWindow today;
  final FinancialSpendingWindow week;
  final FinancialSpendingWindow month;

  /// The audited calculation behind [monthScore]. It can be absent only for
  /// legacy data or when an offline baseline cannot safely be reconstructed.
  final SmartMoneyScoreCalculation? monthlyScoreCalculation;

  /// Live budget progress used for a truthful score explanation. It is never
  /// copied into score history, which keeps budgets as the source of truth.
  final List<FinancialBudgetStatus> budgets;

  /// The score that needs the most attention. It drives the explanation and
  /// practical actions on the dashboard.
  FinancialPeriodScore get primaryScore {
    // Monthly balance movement is the product's primary Smart Money Score.
    // Today and week remain alongside it as shorter horizon check-ins.
    return monthScore;
  }

  FinancialInsight copyWith({
    FinancialPeriodScore? todayScore,
    FinancialPeriodScore? weekScore,
    FinancialPeriodScore? monthScore,
    FinancialInsightTone? tone,
    FinancialInsightMessage? headline,
    FinancialInsightMessage? explanation,
    List<FinancialInsightMessage>? scoreReasons,
    List<FinancialInsightAction>? actions,
    SmartMoneyScoreCalculation? monthlyScoreCalculation,
    List<FinancialBudgetStatus>? budgets,
  }) {
    return FinancialInsight(
      currencyCode: currencyCode,
      totalBalance: totalBalance,
      todayScore: todayScore ?? this.todayScore,
      weekScore: weekScore ?? this.weekScore,
      monthScore: monthScore ?? this.monthScore,
      tone: tone ?? this.tone,
      headline: headline ?? this.headline,
      explanation: explanation ?? this.explanation,
      scoreReasons: scoreReasons ?? this.scoreReasons,
      actions: actions ?? this.actions,
      today: today,
      week: week,
      month: month,
      monthlyScoreCalculation:
          monthlyScoreCalculation ?? this.monthlyScoreCalculation,
      budgets: budgets ?? this.budgets,
    );
  }

  /// Kept as a convenience for existing callers that need only today's
  /// numeric score.
  int get dailyScore => todayScore.value;

  @override
  List<Object?> get props => [
    currencyCode,
    totalBalance,
    todayScore,
    weekScore,
    monthScore,
    tone,
    headline,
    explanation,
    scoreReasons,
    actions,
    today,
    week,
    month,
    monthlyScoreCalculation,
    budgets,
  ];
}
