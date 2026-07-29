import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../accounts/domain/entities/account_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionTile extends StatelessWidget {
  static const double _avatarDiameter = 40;
  static const double _standardAmountBlockWidth = 124;
  static const double _compactAmountBlockWidth = 104;
  static const double _standardDeleteButtonSize = 40;
  static const double _compactDeleteButtonSize = 36;

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
    final currency = SupportedCurrencies.byCode(
      account?.currencyCode ?? SupportedCurrencies.fallback.code,
    );
    final formattedAmount =
        '$sign${CurrencyFormatter.format(transaction.amount, currency)}';

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;
          final trailingGap = isCompact ? AppSpacing.xs : AppSpacing.sm;
          final deleteButtonSize = isCompact
              ? _compactDeleteButtonSize
              : _standardDeleteButtonSize;
          final preferredAmountBlockWidth = isCompact
              ? _compactAmountBlockWidth
              : _standardAmountBlockWidth;

          // Keep the amount/date together at the trailing edge. On a very
          // narrow screen, shrink only this block so the leading text can
          // gracefully ellipsize instead of making the Row overflow.
          final amountBlockWidth = constraints.hasBoundedWidth
              ? (constraints.maxWidth -
                        _avatarDiameter -
                        AppSpacing.md -
                        (trailingGap * 2) -
                        deleteButtonSize)
                    .clamp(0.0, preferredAmountBlockWidth)
                    .toDouble()
              : preferredAmountBlockWidth;

          return Row(
            children: [
              CircleAvatar(
                radius: _avatarDiameter / 2,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (transaction.note.isNotEmpty)
                      Text(
                        transaction.note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              SizedBox(width: trailingGap),
              SizedBox(
                width: amountBlockWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedAmount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat.MMMd().format(transaction.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: trailingGap),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.delete,
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(
                  width: deleteButtonSize,
                  height: deleteButtonSize,
                ),
                visualDensity: VisualDensity.compact,
                splashRadius: deleteButtonSize / 2,
              ),
            ],
          );
        },
      ),
    );
  }
}
