import 'package:flutter/material.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/account_entity.dart';
import '../utils/account_type_label.dart';

/// A compact account row. Its share is always calculated against positive
/// assets in the same currency by the parent summary, never a mixed total.
class AccountCard extends StatelessWidget {
  const AccountCard({
    required this.account,
    required this.onTap,
    super.key,
    this.trailing,
    this.percentOfTotalBalance,
  });

  final AccountEntity account;
  final VoidCallback onTap;
  final Widget? trailing;
  final double? percentOfTotalBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = account.color.color;
    final isNegative = account.balance < 0;
    return Opacity(
      opacity: account.isArchived ? .55 : 1,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: .14),
              child: Icon(account.icon.icon, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    account.isArchived
                        ? l10n.archivedBadgeLabel
                        : isNegative
                        ? 'Overdrawn'
                        : account.type.localizedLabel(l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isNegative
                          ? AppSemanticColors.of(context).negativeForeground
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      CurrencyFormatter.format(
                        account.balance,
                        SupportedCurrencies.byCode(account.currencyCode),
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isNegative
                            ? AppSemanticColors.of(context).negativeForeground
                            : null,
                      ),
                    ),
                  ),
                  if (percentOfTotalBalance != null)
                    Text(
                      '${(percentOfTotalBalance! * 100).toStringAsFixed(1)}% of assets',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
