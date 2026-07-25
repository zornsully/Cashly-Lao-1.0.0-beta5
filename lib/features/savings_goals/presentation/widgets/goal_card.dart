import 'package:flutter/material.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/savings_goal_progress.dart';

/// One goal's progress: icon, name, a linear progress bar, current/target
/// amounts, and status badges — mirrors `BudgetProgressTile`'s layout and
/// `AccountCard`'s icon-circle/archived-dimming treatment. The larger ring
/// visual lives only on Detail (see `GoalProgressRing`).
class GoalCard extends StatelessWidget {
  const GoalCard({required this.progress, super.key, this.onTap});

  final SavingsGoalProgress progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final goal = progress.goal;
    final currency = SupportedCurrencies.byCode(progress.currencyCode);
    final goalColor = goal.color.color;
    final isCompleted = progress.isCompleted;
    final barColor = isCompleted ? theme.colorScheme.tertiary : goalColor;

    return Opacity(
      opacity: goal.isArchived ? 0.55 : 1,
      child: AppCard(
        onTap: onTap,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: goalColor.withValues(alpha: 0.16),
                  child: Icon(goal.icon.icon, color: goalColor),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    goal.name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCompleted)
                  AppBadge(label: l10n.goalCompletedBadgeLabel)
                else if (goal.isReminderDue(DateTime.now()))
                  AppBadge(label: l10n.goalDueBadgeLabel),
                if (goal.isArchived) ...[
                  const SizedBox(width: AppSpacing.xs),
                  AppBadge(label: l10n.archivedBadgeLabel),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: (progress.percentageComplete / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: barColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${CurrencyFormatter.format(progress.currentAmount, currency)} '
              '/ ${CurrencyFormatter.format(goal.targetAmount, currency)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
