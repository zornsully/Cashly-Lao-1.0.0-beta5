import 'package:flutter/material.dart';

import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

/// Small status label (e.g. "Archived", "Default") shown inline next to a
/// list-item title. Account, category, and budget tiles each hand-rolled an
/// identical Container/BoxDecoration/Text for this — this replaces all of
/// them with one shared, theme-aware implementation.
class AppBadge extends StatelessWidget {
  const AppBadge({required this.label, super.key, this.color});

  final String label;

  /// A semantic tone (e.g. the theme's error color for a "Negative" badge)
  /// — never the *only* way the meaning is conveyed (the label text always
  /// carries it too), just an additional, optional emphasis. Omitted for
  /// every neutral badge (Archived, Default, Completed, ...), which keeps
  /// their existing look unchanged.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color:
            tone?.withValues(alpha: 0.14) ??
            theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: tone,
          fontWeight: tone != null ? FontWeight.w700 : null,
        ),
      ),
    );
  }
}
