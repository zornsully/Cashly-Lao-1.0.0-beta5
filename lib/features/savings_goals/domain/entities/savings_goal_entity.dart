import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import 'goal_contribution_frequency.dart';

class SavingsGoalEntity extends Equatable {
  const SavingsGoalEntity({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.accountId,
    required this.icon,
    required this.color,
    required this.isArchived,
    required this.lastContributionAt,
    required this.createdAt,
    required this.updatedAt,
    this.autoContributionAmount,
    this.autoContributionFrequency,
  });

  final String id;
  final String name;

  /// Always a positive amount, denominated in the linked account's
  /// currency. Currency itself isn't stored here — see
  /// `SavingsGoalProgress`, which derives it live from the account instead.
  final double targetAmount;

  /// The account whose live `balance` *is* this goal's progress. Fixed at
  /// creation — pinned immutable in `firestore.rules`.
  final String accountId;

  final AppIconKey icon;
  final AppColorKey color;
  final bool isArchived;

  /// Set together — non-null (and positive) only when an auto-contribution
  /// schedule is configured; both null otherwise.
  final double? autoContributionAmount;
  final GoalContributionFrequency? autoContributionFrequency;

  /// When the most recent contribution landed — initialized to [createdAt]
  /// for a brand-new goal. Only drives [isReminderDue] and the "scheduled"
  /// completion estimate; never affects money.
  final DateTime lastContributionAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasAutoContribution =>
      autoContributionAmount != null && autoContributionFrequency != null;

  /// Whether an auto-contribution schedule's next occurrence has arrived.
  bool isReminderDue(DateTime now) {
    if (!hasAutoContribution) return false;
    return !autoContributionFrequency!
        .nextDueDate(lastContributionAt)
        .isAfter(now);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    targetAmount,
    accountId,
    icon,
    color,
    isArchived,
    autoContributionAmount,
    autoContributionFrequency,
    lastContributionAt,
    createdAt,
    updatedAt,
  ];
}
