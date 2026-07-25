import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../accounts/domain/entities/account_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    required this.onTap,
    required this.onDelete,
    super.key,
    this.category,
    this.account,
    this.toAccount,
  });

  final TransactionEntity transaction;
  final CategoryEntity? category;
  final AccountEntity? account;

  /// Only meaningful when [transaction.type] is
  /// [TransactionType.transfer] — the destination account.
  final AccountEntity? toAccount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isTransfer = transaction.type == TransactionType.transfer;
    final isIncome = transaction.type == TransactionType.income;

    final color = isTransfer
        ? theme.colorScheme.primary
        : category?.color.color ?? theme.colorScheme.outline;
    final icon = isTransfer
        ? AppSymbols.currencyExchange
        : category?.icon.icon ?? Icons.help_outline;
    final title = isTransfer
        ? l10n.transferToLabel(toAccount?.name ?? l10n.unknownAccountLabel)
        : category?.name ?? l10n.uncategorizedLabel;
    final subtitle = isTransfer
        ? l10n.transferFromLabel(account?.name ?? l10n.unknownAccountLabel)
        : account?.name ?? l10n.unknownAccountLabel;

    final semanticColors = AppSemanticColors.of(context);
    final amountColor = isTransfer
        ? theme.colorScheme.onSurface
        : isIncome
        ? semanticColors.positiveForeground
        : semanticColors.negativeForeground;
    final sign = isTransfer
        ? ''
        : isIncome
        ? '+'
        : '-';

    return AppCard(
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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (transaction.note.isNotEmpty)
                  Text(
                    transaction.note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${transaction.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat.MMMd().format(transaction.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.delete,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
