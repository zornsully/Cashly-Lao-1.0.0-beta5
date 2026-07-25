import '../../../transactions/domain/entities/transaction_entity.dart';
import '../entities/goal_completion_estimate.dart';
import '../entities/savings_goal_progress.dart';

/// Pure projection logic — no repository dependency. Priority order: an
/// explicit auto-contribution schedule always wins when configured (it's a
/// deliberate commitment, more predictable than history); otherwise this
/// falls back to the recent pace of transfers into the linked account
/// ([recentContributions], expected to already be filtered by the caller to
/// `type == transfer && toAccountId == goal.accountId` within the trailing
/// window); with neither, there's nothing to project from.
class EstimateGoalCompletionUseCase {
  const EstimateGoalCompletionUseCase();

  /// How far back [recentContributions] is expected to already be filtered
  /// by the caller — public so provider-layer code building that filter
  /// doesn't duplicate the number.
  static const trailingWindowDays = 90;

  /// A projection beyond this many scheduled periods, or this many days,
  /// isn't a meaningful "on track to finish by X" answer — treated as
  /// [GoalCompletionEstimateBasis.insufficientData] instead. Without this,
  /// a tiny auto-contribution amount against a large target would loop
  /// [GoalContributionFrequency.nextDueDate] an unbounded number of times
  /// (a real hang risk), and a tiny trailing daily rate would produce a
  /// wildly distant (and, at extreme ratios, overflow-risking) [DateTime].
  static const _maxProjectionPeriods = 1200;
  static const _maxProjectionDays = 36500;

  GoalCompletionEstimate call({
    required SavingsGoalProgress progress,
    required List<TransactionEntity> recentContributions,
    required DateTime now,
  }) {
    if (progress.isCompleted) {
      return const GoalCompletionEstimate(
        basis: GoalCompletionEstimateBasis.alreadyCompleted,
      );
    }

    final goal = progress.goal;
    if (goal.hasAutoContribution) {
      // autoContributionAmount is guaranteed > 0 here: the data layer maps
      // the "no schedule" sentinel to null rather than 0 (see
      // SavingsGoalModel), and hasAutoContribution requires both schedule
      // fields to be non-null.
      final periods = (progress.remainingAmount / goal.autoContributionAmount!)
          .ceil();
      if (periods > _maxProjectionPeriods) {
        return const GoalCompletionEstimate(
          basis: GoalCompletionEstimateBasis.insufficientData,
        );
      }
      var date = goal.lastContributionAt.isBefore(now)
          ? now
          : goal.lastContributionAt;
      for (var i = 0; i < periods; i++) {
        date = goal.autoContributionFrequency!.nextDueDate(date);
      }
      return GoalCompletionEstimate(
        basis: GoalCompletionEstimateBasis.scheduled,
        estimatedDate: date,
      );
    }

    if (recentContributions.isEmpty) {
      return const GoalCompletionEstimate(
        basis: GoalCompletionEstimateBasis.insufficientData,
      );
    }

    final total = recentContributions.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
    final earliest = recentContributions
        .map((transaction) => transaction.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final spanDays = now.difference(earliest).inDays;
    final boundedSpanDays = spanDays < 1
        ? 1
        : (spanDays > trailingWindowDays ? trailingWindowDays : spanDays);
    final dailyRate = total / boundedSpanDays;
    if (dailyRate <= 0) {
      return const GoalCompletionEstimate(
        basis: GoalCompletionEstimateBasis.insufficientData,
      );
    }

    final daysNeeded = (progress.remainingAmount / dailyRate).ceil();
    if (daysNeeded > _maxProjectionDays) {
      return const GoalCompletionEstimate(
        basis: GoalCompletionEstimateBasis.insufficientData,
      );
    }
    return GoalCompletionEstimate(
      basis: GoalCompletionEstimateBasis.trailingAverage,
      estimatedDate: now.add(Duration(days: daysNeeded)),
    );
  }
}
