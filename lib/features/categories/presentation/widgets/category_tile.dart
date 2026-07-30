import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/category_entity.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.category,
    required this.onTap,
    required this.reorderIndex,
    super.key,
    this.trailingMenu,
  });

  final CategoryEntity category;
  final VoidCallback onTap;
  final Widget? trailingMenu;

  /// Index within the [ReorderableListView] this tile lives in — required
  /// by [ReorderableDragStartListener].
  final int reorderIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = category.color.color;

    return Opacity(
      opacity: category.isArchived ? 0.55 : 1,
      child: AppCard(
        onTap: onTap,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.16),
              child: Icon(category.icon.icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      category.name,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (category.isDefault) ...[
                    const SizedBox(width: AppSpacing.sm),
                    AppBadge(label: l10n.defaultBadgeLabel),
                  ],
                  if (category.isArchived) ...[
                    const SizedBox(width: AppSpacing.sm),
                    AppBadge(label: l10n.archivedBadgeLabel),
                  ],
                ],
              ),
            ),
            ?trailingMenu,
            ReorderableDragStartListener(
              index: reorderIndex,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(
                  AppSymbols.dragHandle,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
