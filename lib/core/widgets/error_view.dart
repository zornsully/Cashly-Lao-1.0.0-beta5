import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../constants/app_spacing.dart';
import '../constants/app_symbols.dart';

/// Reusable full-body error placeholder for an `AsyncValue.when(error: ...)`
/// branch. Every screen should use this instead of rendering the raw
/// exception as bare text, for the same reason [EmptyState] exists —
/// consistent look, and a single place to improve error presentation.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppSymbols.errorOutline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.errorGenericTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(AppSymbols.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
