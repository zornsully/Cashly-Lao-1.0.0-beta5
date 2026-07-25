import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/chart_legend_dot.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/domain/entities/category_spending.dart';

/// A donut chart summarizing one currency's "Spending by Category", paired
/// with a text legend below it — so category identity is never carried by
/// color alone. Each slice reuses the category's own color (the same one
/// shown everywhere else in the app), consistent with [CategorySpendingBar].
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    required this.spending,
    required this.currency,
    super.key,
  });

  final List<CategorySpending> spending;
  final AppCurrency currency;

  static const double _diameter = 140;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final total = spending.fold<double>(0, (sum, s) => sum + s.amount);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _diameter,
          height: _diameter,
          child: CustomPaint(
            painter: _DonutPainter(
              spending: spending,
              total: total,
              trackColor: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.totalLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(total, currency),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in spending)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ChartLegendDot(
                    color: s.category.color.color,
                    label: s.category.name,
                    trailing: '${s.percentageOfExpense.toStringAsFixed(0)}%',
                    expandLabel: true,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.spending,
    required this.total,
    required this.trackColor,
  });

  final List<CategorySpending> spending;
  final double total;
  final Color trackColor;

  static const double _strokeWidth = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawArc(rect, 0, 2 * pi, false, trackPaint);

    if (total <= 0) return;

    var startAngle = -pi / 2;
    for (final s in spending) {
      final sweep = (s.amount / total) * 2 * pi;
      final slicePaint = Paint()
        ..color = s.category.color.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, slicePaint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) {
    return oldDelegate.spending != spending || oldDelegate.total != total;
  }
}
