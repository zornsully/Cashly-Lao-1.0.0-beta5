import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/chart_legend_dot.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/monthly_trend_point.dart';

/// A grouped bar chart comparing income and expense across several months.
/// Income/expense keep the same green/red identity used everywhere else in
/// the app. Bars share one scale (the max across the whole chart) rather
/// than each having its own axis. Tapping a month's bars surfaces its exact
/// figures — the mobile equivalent of a hover tooltip.
class IncomeExpenseTrendChart extends StatelessWidget {
  const IncomeExpenseTrendChart({
    required this.points,
    required this.currency,
    super.key,
  });

  final List<MonthlyTrendPoint> points;
  final AppCurrency currency;

  static const double _chartHeight = 140;
  static const double _barAreaHeight = 108;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final semanticColors = AppSemanticColors.of(context);
    final incomeColor = semanticColors.positiveForeground;
    final expenseColor = semanticColors.negativeForeground;

    final maxValue = points.fold<double>(0, (currentMax, point) {
      final income = point.totalIncomeByCurrency[currency.code] ?? 0;
      final expense = point.totalExpenseByCurrency[currency.code] ?? 0;
      return [currentMax, income, expense].reduce((a, b) => a > b ? a : b);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChartLegendDot(color: incomeColor, label: l10n.incomeLabel),
            const SizedBox(width: AppSpacing.md),
            ChartLegendDot(color: expenseColor, label: l10n.expenseLabel),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: _chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in points)
                Expanded(
                  child: _MonthColumn(
                    point: point,
                    currency: currency,
                    maxValue: maxValue,
                    incomeColor: incomeColor,
                    expenseColor: expenseColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthColumn extends StatelessWidget {
  const _MonthColumn({
    required this.point,
    required this.currency,
    required this.maxValue,
    required this.incomeColor,
    required this.expenseColor,
  });

  final MonthlyTrendPoint point;
  final AppCurrency currency;
  final double maxValue;
  final Color incomeColor;
  final Color expenseColor;

  double _barHeight(double value) {
    if (maxValue <= 0) return 0;
    return (value / maxValue) * IncomeExpenseTrendChart._barAreaHeight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final income = point.totalIncomeByCurrency[currency.code] ?? 0;
    final expense = point.totalExpenseByCurrency[currency.code] ?? 0;

    return GestureDetector(
      onTap: () => AppSnackbar.showSuccess(
        context,
        l10n.monthIncomeExpenseSummaryMessage(
          DateFormat.yMMM().format(point.month),
          CurrencyFormatter.format(income, currency),
          CurrencyFormatter.format(expense, currency),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: IncomeExpenseTrendChart._barAreaHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Bar(height: _barHeight(income), color: incomeColor),
                const SizedBox(width: 3),
                _Bar(height: _barHeight(expense), color: expenseColor),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            DateFormat.MMM().format(point.month),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      child: Container(width: 10, height: height, color: color),
    );
  }
}
