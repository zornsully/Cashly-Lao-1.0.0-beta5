import 'package:equatable/equatable.dart';

/// Every distinct headline/explanation/action/reason template the rule
/// engine and short-horizon calculator can produce.
///
/// The domain layer never formats these into display text — it only picks a
/// key and supplies typed [FinancialInsightMessage.args] (category names,
/// already-formatted amounts/percentages, day counts). The presentation
/// layer maps each key to a localized, parameterized string. Keeping the
/// key set exhaustive (rather than embedding an English period noun like
/// "today"/"this week" as an interpolated arg) keeps every template
/// grammatically natural to translate, matching the app's existing
/// no-ICU-plural convention.
enum FinancialInsightMessageKey {
  steadySpendingHeadline,
  steadySpendingExplanation,
  negativeBalanceHeadline,
  negativeBalanceExplanation,
  planEssentialExpenseTitle,
  planEssentialExpenseDetail,
  categoryOverBudgetHeadline,
  categoryOverBudgetExplanation,
  pauseCategorySpendingTitle,
  pauseCategorySpendingDetail,
  categoryNeedsRoomHeadline,
  categoryNeedsRoomExplanation,
  setRestOfMonthLimitTitle,
  setRestOfMonthLimitDetail,
  categoryHigherThanUsualHeadline,
  categoryHigherThanUsualExplanation,
  reviewNextCategoryPurchaseTitle,
  reviewNextCategoryPurchaseDetail,
  todaySpendingFasterHeadline,
  todaySpendingFasterExplanation,
  checkNextExpenseTitle,
  checkNextExpenseDetail,
  spendingAheadOfIncomeHeadline,
  spendingAheadOfIncomeExplanation,
  chooseLowPriorityExpenseTitle,
  chooseLowPriorityExpenseDetail,
  balanceZeroHeadline,
  balanceThinHeadline,
  balanceLimitedHeadline,
  balanceSteadyHeadline,
  balanceZeroExplanation,
  balanceThinExplanation,
  balanceLimitedExplanation,
  balanceSteadyExplanation,
  protectEssentialExpenseTitle,
  protectEssentialExpenseDetail,
  reserveNextDaysTitle,
  reserveNextDaysDetail,
  setShortRestOfWeekLimitTitle,
  setShortRestOfWeekLimitDetail,
  keepExpenseIntentionalTitle,
  keepExpenseIntentionalBalanceDetail,
  keepExpenseIntentionalPaceDetail,
  onboardingHeadline,
  onboardingExplanation,
  logNextExpenseTitle,
  logNextExpenseDetail,
  notEnoughActivityTodayReason,
  notEnoughActivityWeekReason,
  notEnoughActivityMonthReason,
  balanceImpactNegativeReason,
  balanceImpactEmptyReason,
  balanceImpactLowReason,
  balanceImpactHealthyReason,
  categoryOverBudgetReasonToday,
  categoryNearBudgetReasonToday,
  todaySpikeReason,
  todayComparableIncreaseReason,
  noActivityTodayReason,
  incomeCoversTodayReason,
  categoryOverBudgetReasonWeek,
  categoryNearBudgetReasonWeek,
  categoryPacedBudgetReasonWeek,
  weeklyCategorySpikeReason,
  weekComparableIncreaseReason,
  weekComparableDecreaseReason,
  categoryOverBudgetReasonMonth,
  categoryNearBudgetReasonMonth,
  categoryPacedBudgetReasonMonth,
  spendingOverIncomeReasonMonth,
  incomeCoversMonthReason,
  monthComparableIncreaseReason,
  monthComparableDecreaseReason,
  steadyReasonToday,
  steadyReasonWeek,
  steadyReasonMonth,
  shortHorizonNoActiveAccountToday,
  shortHorizonNoActiveAccountWeek,
  shortHorizonCrossCurrencyToday,
  shortHorizonCrossCurrencyWeek,
  shortHorizonAccountAddedToday,
  shortHorizonAccountAddedWeek,
  shortHorizonUnverifiableToday,
  shortHorizonUnverifiableWeek,
  shortHorizonZeroOpeningToday,
  shortHorizonZeroOpeningWeek,
  shortHorizonIncreasedToday,
  shortHorizonIncreasedWeek,
  shortHorizonDecreasedToday,
  shortHorizonDecreasedWeek,
  shortHorizonStayedLevelToday,
  shortHorizonStayedLevelWeek,

  /// Passthrough for the persisted, already-English
  /// `SmartMoneyScoreCalculation.reasons`/`unavailableReason` — an
  /// auditable historical record (see `smart_money_score_model.dart`),
  /// deliberately out of scope for localization (see `CLAUDE.md`'s Phase
  /// 2a entry). [args]`['text']` is rendered verbatim.
  literal,
}

/// A structured, framework-free stand-in for a display string.
///
/// [args] values are either plain data the presentation layer interpolates
/// as-is (a category name, an already-formatted amount/percentage string,
/// a day count) — never pre-translated English prose, except for
/// [FinancialInsightMessageKey.literal]'s deliberate exception.
class FinancialInsightMessage extends Equatable {
  const FinancialInsightMessage(this.key, [this.args = const {}]);

  factory FinancialInsightMessage.literal(String text) =>
      FinancialInsightMessage(FinancialInsightMessageKey.literal, {
        'text': text,
      });

  final FinancialInsightMessageKey key;
  final Map<String, Object> args;

  @override
  List<Object?> get props => [key, args];
}
