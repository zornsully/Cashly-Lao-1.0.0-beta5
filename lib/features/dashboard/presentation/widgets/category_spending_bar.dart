import 'package:flutter/material.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/category_spending.dart';

/// A single row in the "Spending by Category" list: icon, name, amount,
/// and a proportional bar. The bar uses the category's own color (already
/// chosen by the user in Sprint 3) so it stays consistent with how that
/// category looks everywhere else in the app, rather than introducing a
/// separate chart palette. The percentage is also printed as text, so the
/// comparison isn't color-only.
class CategorySpendingBar extends StatelessWidget {
  const CategorySpendingBar({
    required this.spending,
    required this.currency,
    super.key,
  });

  final CategorySpending spending;
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = spending.category.color.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(spending.category.icon.icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  spending.category.name,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                CurrencyFormatter.format(spending.amount, currency),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 44,
                child: Text(
                  '${spending.percentageOfExpense.toStringAsFixed(0)}%',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: (spending.percentageOfExpense / 100).clamp(0, 1),
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
