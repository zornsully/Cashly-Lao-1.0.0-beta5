import 'package:flutter/material.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/account_entity.dart';
import '../utils/account_type_label.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    required this.account,
    required this.onTap,
    super.key,
    this.trailing,
  });

  final AccountEntity account;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = account.color.color;
    final currency = SupportedCurrencies.byCode(account.currencyCode);
    final isNegative = account.balance < 0;

    return Opacity(
      opacity: account.isArchived ? 0.55 : 1,
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.16),
              child: Icon(account.icon.icon, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (account.isArchived) ...[
                        const SizedBox(width: AppSpacing.sm),
                        AppBadge(label: l10n.archivedBadgeLabel),
                      ],
                    ],
                  ),
                  Text(
                    account.type.localizedLabel(l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                CurrencyFormatter.format(account.balance, currency),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isNegative
                      ? AppSemanticColors.of(context).negativeForeground
                      : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
