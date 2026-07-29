import 'package:equatable/equatable.dart';

/// How confidently Cashly can compare a month's opening and current balance.
///
/// The score never guesses across currencies or account changes it cannot
/// reconstruct. A non-reliable baseline deliberately produces a neutral score
/// instead of making a user's score look better or worse for a technical
/// reason.
enum SmartMoneyScoreBaselineState {
  reliable,
  insufficientData,
  unsafeCurrencyMovement,
}

/// Immutable opening data for one currency and calendar month.
///
/// One document is retained for each month, so signing in on another device,
/// clearing a local cache, or reopening the app cannot create a new opening
/// balance. Amounts are intentionally currency-exact; cross-currency totals
/// are only safe when an immutable FX snapshot is available.
class SmartMoneyScoreOpening extends Equatable {
  const SmartMoneyScoreOpening({
    required this.monthStart,
    required this.currencyCode,
    required this.openingBalance,
    required this.baselineState,
    this.baselineNote,
  });

  final DateTime monthStart;
  final String currencyCode;
  final double openingBalance;
  final SmartMoneyScoreBaselineState baselineState;
  final String? baselineNote;

  bool get isReliable => baselineState == SmartMoneyScoreBaselineState.reliable;

  /// A deterministic ID makes the month reset idempotent across devices.
  String get documentId => '${monthKey}_$currencyCode';

  String get monthKey =>
      '${monthStart.year.toString().padLeft(4, '0')}-${monthStart.month.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [
    monthStart,
    currencyCode,
    openingBalance,
    baselineState,
    baselineNote,
  ];
}

/// The auditable pieces of the small behaviour modifier applied to the
/// balance-growth score.
///
/// Balance movement remains the primary factor. Keeping these values
/// separately means the interface can explain the formula without recreating
/// its rules (and without an LLM inventing a reason after the fact).
class SmartMoneyScoreBehaviourBreakdown extends Equatable {
  const SmartMoneyScoreBehaviourBreakdown({
    required this.incomeExpenseImpact,
    required this.savingsImpact,
    required this.budgetImpact,
    required this.spendingTrendImpact,
    required this.lowBalanceImpact,
    required this.billImpact,
    required this.appliedModifier,
  }) : assert(appliedModifier >= -10 && appliedModifier <= 10);

  /// Effect of recorded income being ahead of, or behind, expenses.
  final int incomeExpenseImpact;

  /// Effect of positive or negative net cash flow.
  final int savingsImpact;

  /// Effect of current budget progress.
  final int budgetImpact;

  /// Effect of spending compared with the previous comparable period.
  final int spendingTrendImpact;

  /// Small safety adjustment for a negative overall balance.
  final int lowBalanceImpact;

  /// Reserved for Bills & Reminders once a shared bill data source exists.
  /// It is persisted as zero today rather than silently implying a bill
  /// penalty where Cashly has no verified bill data.
  final int billImpact;

  /// Capped total used by the formula.
  final int appliedModifier;

  int get uncappedModifier =>
      incomeExpenseImpact +
      savingsImpact +
      budgetImpact +
      spendingTrendImpact +
      lowBalanceImpact +
      billImpact;

  @override
  List<Object?> get props => [
    incomeExpenseImpact,
    savingsImpact,
    budgetImpact,
    spendingTrendImpact,
    lowBalanceImpact,
    billImpact,
    appliedModifier,
  ];
}

/// All deterministic inputs and outputs needed to explain a monthly score.
///
/// Persisting this compact calculation makes historical scores auditable
/// without retaining transaction notes or account names in the score record.
class SmartMoneyScoreCalculation extends Equatable {
  const SmartMoneyScoreCalculation({
    required this.calculatedAt,
    required this.currentBalance,
    required this.balanceChange,
    required this.balanceChangePercentage,
    required this.income,
    required this.expense,
    required this.netCashFlow,
    required this.financialBehaviourModifier,
    required this.score,
    required this.isReliable,
    required this.hasMeaningfulActivity,
    required this.reasons,
    this.behaviourBreakdown,
    this.unavailableReason,
  }) : assert(score >= 0 && score <= 150),
       assert(
         financialBehaviourModifier >= -10 && financialBehaviourModifier <= 10,
       );

  final DateTime calculatedAt;
  final double currentBalance;
  final double balanceChange;
  final double balanceChangePercentage;
  final double income;
  final double expense;
  final double netCashFlow;
  final int financialBehaviourModifier;
  final int score;
  final bool isReliable;
  final bool hasMeaningfulActivity;
  final List<String> reasons;

  /// Kept optional so older persisted score history remains readable.
  final SmartMoneyScoreBehaviourBreakdown? behaviourBreakdown;
  final String? unavailableReason;

  @override
  List<Object?> get props => [
    calculatedAt,
    currentBalance,
    balanceChange,
    balanceChangePercentage,
    income,
    expense,
    netCashFlow,
    financialBehaviourModifier,
    score,
    isReliable,
    hasMeaningfulActivity,
    reasons,
    behaviourBreakdown,
    unavailableReason,
  ];
}

/// A persisted, immutable-month score history entry.
///
/// [opening] is written exactly once. [latestCalculation] changes whenever
/// synchronised financial inputs change, preserving the current explanation
/// for the historical month without letting a device reset its opening value.
class SmartMoneyScoreMonth extends Equatable {
  const SmartMoneyScoreMonth({
    required this.opening,
    required this.createdAt,
    required this.updatedAt,
    this.latestCalculation,
  });

  final SmartMoneyScoreOpening opening;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SmartMoneyScoreCalculation? latestCalculation;

  String get id => opening.documentId;

  @override
  List<Object?> get props => [opening, createdAt, updatedAt, latestCalculation];
}
