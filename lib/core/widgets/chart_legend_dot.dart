import 'package:flutter/material.dart';

import '../constants/app_chart_style.dart';
import '../constants/app_spacing.dart';

/// One legend entry shared by every chart in the app: a color-identity dot,
/// a label, and an optional trailing value (e.g. a percentage). Reports'
/// pie and trend charts each hand-rolled this — this is the one shared
/// implementation both should use, so a chart never carries meaning by
/// color alone without also labeling it here.
class ChartLegendDot extends StatelessWidget {
  const ChartLegendDot({
    required this.color,
    required this.label,
    super.key,
    this.trailing,
    this.expandLabel = false,
  });

  final Color color;
  final String label;
  final String? trailing;

  /// When true, the label expands to fill the row (pushing [trailing] to
  /// the far edge) — only safe when this widget sits in a bounded-width
  /// parent (e.g. a column of legend rows), not a `mainAxisSize.min` row.
  final bool expandLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelText = Text(
      label,
      style: theme.textTheme.bodySmall,
      overflow: TextOverflow.ellipsis,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppChartStyle.legendDotSize,
          height: AppChartStyle.legendDotSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        expandLabel ? Expanded(child: labelText) : Flexible(child: labelText),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            trailing!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
