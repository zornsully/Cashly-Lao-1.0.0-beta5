import 'package:flutter/material.dart';

import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

/// Small status label (e.g. "Archived", "Default") shown inline next to a
/// list-item title. Account, category, and budget tiles each hand-rolled an
/// identical Container/BoxDecoration/Text for this — this replaces all of
/// them with one shared, theme-aware implementation.
class AppBadge extends StatelessWidget {
  const AppBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}
