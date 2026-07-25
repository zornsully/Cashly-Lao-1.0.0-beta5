import 'package:flutter/material.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';

/// One balance/income/expense figure, shown as a compact Material 3 card.
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final double amount;
  final AppCurrency currency;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Counts smoothly between the old and new amount instead of
            // snapping — a small but deliberate touch (Motion is a
            // first-class design-system requirement, not polish added at
            // the end) for the number a user checks most often.
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: amount),
              duration: AppMotion.slow,
              curve: AppMotion.enter,
              builder: (context, animatedAmount, child) => Text(
                CurrencyFormatter.format(animatedAmount, currency),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
