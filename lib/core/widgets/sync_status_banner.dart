import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../constants/app_motion.dart';
import '../constants/app_spacing.dart';
import '../constants/app_symbols.dart';
import '../providers/connectivity_providers.dart';

/// A slim banner shown above the tab content whenever the app is offline —
/// Firestore already keeps working from its local cache and syncs the
/// moment connectivity returns (see [isOnlineProvider]'s doc comment), this
/// just makes that state visible instead of leaving the user to guess why
/// a change hasn't shown up elsewhere yet. Collapses to nothing (no
/// reserved space) while online.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Loading and error both default to "online" (no banner) — a brief
    // flash on startup or a mis-shown banner on some unrelated Firestore
    // error would be more confusing than briefly saying nothing.
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    return AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: isOnline
          ? const SizedBox.shrink(key: ValueKey('online'))
          : Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              color: theme.colorScheme.tertiaryContainer,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppSymbols.cloudOffOutlined,
                    size: 16,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      l10n.offlineBannerMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
