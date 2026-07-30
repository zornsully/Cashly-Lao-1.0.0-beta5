import 'package:flutter/material.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/budget_progress.dart';

/// One category's budget progress: icon, name, spent/limit, a proportional
/// bar (red when overspent), and the remaining amount. Reused as-is by
/// both the Budget tab and the Dashboard's Budgets section.
class BudgetProgressTile extends StatelessWidget {
  const BudgetProgressTile({
    required this.progress,
    super.key,
    this.onTap,
    this.onDelete,
  });

  final BudgetProgress progress;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currency = SupportedCurrencies.byCode(progress.budget.currencyCode);
    final categoryColor = progress.category.color.color;
    final semanticColors = AppSemanticColors.of(context);
    // A third, non-text-only signal between "on track" and "overspent" —
    // never the only cue (the percent/remaining text below always states
    // it in words too, per CLAUDE.md's "never encode meaning in color
    // alone" accessibility rule).
    final isApproachingLimit =
        !progress.isOverspent && progress.percentageUsed >= 80;
    final barColor = progress.isOverspent
        ? theme.colorScheme.error
        : isApproachingLimit
        ? theme.colorScheme.tertiary
        : categoryColor;

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(progress.category.icon.icon, size: 18, color: categoryColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  progress.category.name,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (progress.isOverspent) ...[
                Icon(
                  AppSymbols.warningAmberRounded,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  '${CurrencyFormatter.format(progress.spentAmount, currency)} '
                  '/ ${CurrencyFormatter.format(progress.budget.limitAmount, currency)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: progress.isOverspent
                        ? semanticColors.negativeForeground
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(AppSymbols.deleteOutline),
                  tooltip: l10n.deleteBudgetTooltip,
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: (progress.percentageUsed / 100).clamp(0, 1),
              minHeight: AppSpacing.sm,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: barColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${l10n.budgetPercentUsedLabel(progress.percentageUsed.clamp(0, double.infinity).round().toString())}'
            ' · '
            '${progress.isOverspent ? l10n.overspentByMessage(CurrencyFormatter.format(-progress.remainingAmount, currency)) : l10n.remainingAmountMessage(CurrencyFormatter.format(progress.remainingAmount, currency))}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: progress.isOverspent
                  ? semanticColors.negativeForeground
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
