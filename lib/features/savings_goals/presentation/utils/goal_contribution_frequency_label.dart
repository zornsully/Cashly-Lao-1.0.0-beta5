import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/goal_contribution_frequency.dart';

/// Localized display label for [GoalContributionFrequency] — kept in the
/// presentation layer (unlike [GoalContributionFrequency.label], which is
/// domain-level English) since it needs [AppLocalizations]. Same pattern as
/// `AccountTypeLabel`.
extension GoalContributionFrequencyLabel on GoalContributionFrequency {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    GoalContributionFrequency.weekly => l10n.goalFrequencyWeeklyLabel,
    GoalContributionFrequency.biweekly => l10n.goalFrequencyBiweeklyLabel,
    GoalContributionFrequency.monthly => l10n.goalFrequencyMonthlyLabel,
  };
}
