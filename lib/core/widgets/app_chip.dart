import 'package:flutter/material.dart';

import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

/// Small pill-shaped label, optionally tappable. Distinct from [AppBadge]
/// (a static status indicator like "Archived") — a chip is meant for
/// interactive or informational tags, e.g. a future transaction filter.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    super.key,
    this.icon,
    this.onTap,
    this.color,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Defaults to the theme's primary color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return Material(
      color: chipColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: chipColor),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: chipColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
