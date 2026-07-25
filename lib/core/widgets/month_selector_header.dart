import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../constants/app_spacing.dart';

/// Shared prev/month-label/next header for every screen that browses one
/// calendar month at a time (Transactions, Budget, Reports) — each has its
/// own independent month-selection provider, but the header itself was
/// identical three times over, down to the tooltips.
class MonthSelectorHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const MonthSelectorHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.previousMonthTooltip,
            onPressed: onPrevious,
          ),
          Flexible(
            child: Text(
              DateFormat.yMMMM().format(month),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.nextMonthTooltip,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
