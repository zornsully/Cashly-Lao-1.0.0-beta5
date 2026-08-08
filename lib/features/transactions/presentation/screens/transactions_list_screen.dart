import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_skeleton_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/month_selector_header.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../accounts/domain/entities/account_entity.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_sort_option.dart';
import '../../domain/entities/transaction_type.dart';
import '../providers/transaction_controller.dart';
import '../providers/transaction_providers.dart';
import '../utils/transaction_sort_option_label.dart';

/// The maximum width the page's content grows to on very wide desktop
/// screens, narrower than [ResponsiveCenter]'s own 1440 default -- a dense,
/// text-heavy list (unlike a card-grid page) reads worse stretched much
/// past this before wrapping into a second visual column would help.
const double _maxContentWidth = 1320;

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen> {
  bool _isSearching = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity transaction,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.deleteTransactionTitle,
      message: l10n.deleteTransactionMessage,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
    );

    if (!confirmed || !context.mounted) return;

    final success = await ref
        .read(transactionControllerProvider.notifier)
        .deleteTransaction(transaction.id);

    if (!context.mounted) return;
    if (!success) {
      final message =
          ref.read(transactionControllerProvider.notifier).failure?.message ??
          l10n.deleteTransactionFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  void _stopSearching() {
    _searchController.clear();
    ref.read(transactionsFilterProvider.notifier).setSearchQuery('');
    setState(() => _isSearching = false);
  }

  void _showAddMenu(BuildContext context) {
    AppBottomSheet.show(context, builder: (context) => const _AddActionSheet());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final month = ref.watch(selectedTransactionsMonthProvider);
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(transactionsFilterProvider);
    final accounts = ref.watch(accountsProvider(true)).value ?? [];
    final categories =
        ref
            .watch(categoriesProvider((type: null, includeArchived: true)))
            .value ??
        [];

    final accountsById = {for (final a in accounts) a.id: a};
    final categoriesById = {for (final c in categories) c.id: c};

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchTransactionsHint,
                  border: InputBorder.none,
                ),
                onChanged: (value) => ref
                    .read(transactionsFilterProvider.notifier)
                    .setSearchQuery(value),
              )
            : Text(l10n.transactionsTitle),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(AppSymbols.close),
              tooltip: l10n.closeSearchTooltip,
              onPressed: _stopSearching,
            )
          else ...[
            IconButton(
              icon: const Icon(AppSymbols.search),
              tooltip: l10n.searchTooltip,
              onPressed: () => setState(() => _isSearching = true),
            ),
            Badge(
              isLabelVisible: filter.isActive,
              smallSize: 8,
              child: IconButton(
                icon: const Icon(AppSymbols.tune),
                tooltip: l10n.filterSortTooltip,
                onPressed: () => AppBottomSheet.show(
                  context,
                  isScrollControlled: true,
                  builder: (context) => const _FilterSortSheet(),
                ),
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: _maxContentWidth,
          child: transactionsAsync.when(
            loading: () => const AppSkeletonList(),
            error: (error, _) => ErrorView(message: '$error'),
            data: (transactions) {
              if (transactions.isEmpty) {
                if (filter.isActive) {
                  return EmptyState(
                    icon: AppSymbols.receiptLong,
                    title: l10n.noMatchingTransactionsTitle,
                    message: l10n.noMatchingTransactionsMessage,
                  );
                }
                return EmptyState(
                  icon: AppSymbols.receiptLong,
                  title: l10n.noTransactionsInMonthTitle(
                    DateFormat.yMMMM().format(month),
                  ),
                  message: l10n.addFirstTransactionMessage,
                  action: FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.transactionNew),
                    icon: const Icon(AppSymbols.addRounded),
                    label: Text(l10n.addTransactionButton),
                  ),
                );
              }

              final groupByDate =
                  filter.sortOption == TransactionSortOption.dateDesc ||
                  filter.sortOption == TransactionSortOption.dateAsc;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      0,
                    ),
                    child: _PeriodHeaderRow(month: month),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      0,
                    ),
                    child: _CompactSummaryBar(
                      transactions: transactions,
                      accountsById: accountsById,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      0,
                    ),
                    child: _TransactionToolbar(count: transactions.length),
                  ),
                  Expanded(
                    child: _TransactionTimeline(
                      transactions: transactions,
                      categoriesById: categoriesById,
                      accountsById: accountsById,
                      groupByDate: groupByDate,
                      onEdit: (transaction) => context.push(
                        AppRoutes.transactionEditPath(transaction.id),
                        extra: transaction,
                      ),
                      onDuplicate: (transaction) => context.push(
                        AppRoutes.transactionNew,
                        extra: transaction,
                      ),
                      onDelete: (transaction) =>
                          _confirmDelete(context, ref, transaction),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // See the same fix's comment in accounts_list_screen.dart -- every
        // shell tab's FAB otherwise shares Flutter's implicit default hero
        // tag, since the shell keeps all branches mounted simultaneously.
        // The key gives integration tests an unambiguous target too.
        key: const ValueKey('transactions-fab'),
        heroTag: 'transactions-fab',
        onPressed: () => _showAddMenu(context),
        child: const Icon(AppSymbols.addRounded),
      ),
    );
  }
}

/// Month navigation (unchanged behavior — [selectedTransactionsMonthProvider])
/// paired with a period-granularity selector. Only "Month" is functional
/// today, matching what the underlying provider actually supports; the
/// other options are surfaced (not hidden) but explicitly marked for later,
/// the same "Soon" treatment already used for not-yet-built sidebar items,
/// rather than silently doing nothing or being built out as a much larger,
/// separate feature (arbitrary day/week/year/custom querying) than this
/// page redesign scoped for.
class _PeriodHeaderRow extends StatelessWidget {
  const _PeriodHeaderRow({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Row(
      children: [
        const SizedBox(width: 40),
        Expanded(
          child: Consumer(
            builder: (context, ref, _) => MonthSelectorHeader(
              month: month,
              onPrevious: () => ref
                  .read(selectedTransactionsMonthProvider.notifier)
                  .previousMonth(),
              onNext: () => ref
                  .read(selectedTransactionsMonthProvider.notifier)
                  .nextMonth(),
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: l10n.periodMonthLabel,
          offset: const Offset(0, 36),
          onSelected: (value) {
            if (value == 'month') return;
            AppSnackbar.showInfo(context, l10n.periodNotYetAvailableMessage);
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'day', child: Text(l10n.periodDayLabel)),
            PopupMenuItem(value: 'week', child: Text(l10n.periodWeekLabel)),
            PopupMenuItem(value: 'month', child: Text(l10n.periodMonthLabel)),
            PopupMenuItem(value: 'year', child: Text(l10n.periodYearLabel)),
            PopupMenuItem(value: 'custom', child: Text(l10n.periodCustomLabel)),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.periodMonthLabel, style: theme.textTheme.labelLarge),
              const Icon(AppSymbols.keyboardArrowDown, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterSortSheet extends ConsumerWidget {
  const _FilterSortSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filter = ref.watch(transactionsFilterProvider);
    final notifier = ref.read(transactionsFilterProvider.notifier);
    final accounts = ref.watch(accountsProvider(true)).value ?? [];
    final categories =
        ref
            .watch(categoriesProvider((type: null, includeArchived: true)))
            .value ??
        [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.filterSortSheetTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (filter.isActive)
              TextButton(
                onPressed: notifier.clearFilters,
                child: Text(l10n.clearFiltersButton),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.typeFilterLabel, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: Text(l10n.allTypesLabel),
              selected: filter.type == null,
              onSelected: (_) => notifier.setType(null),
            ),
            ChoiceChip(
              label: Text(l10n.incomeLabel),
              selected: filter.type == TransactionType.income,
              onSelected: (_) => notifier.setType(TransactionType.income),
            ),
            ChoiceChip(
              label: Text(l10n.expenseLabel),
              selected: filter.type == TransactionType.expense,
              onSelected: (_) => notifier.setType(TransactionType.expense),
            ),
            ChoiceChip(
              label: Text(l10n.transferLabel),
              selected: filter.type == TransactionType.transfer,
              onSelected: (_) => notifier.setType(TransactionType.transfer),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownButtonFormField<String?>(
          initialValue: filter.accountId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.accountFilterLabel),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.allAccountsLabel)),
            for (final account in accounts)
              DropdownMenuItem(
                value: account.id,
                child: Text(account.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: notifier.setAccountId,
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String?>(
          initialValue: filter.categoryId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.categoryFilterLabel),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.allCategoriesLabel)),
            for (final category in categories)
              DropdownMenuItem(
                value: category.id,
                child: Text(category.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: notifier.setCategoryId,
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<TransactionSortOption>(
          initialValue: filter.sortOption,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.sortByLabel),
          items: [
            for (final option in TransactionSortOption.values)
              DropdownMenuItem(
                value: option,
                child: Text(option.localizedLabel(l10n)),
              ),
          ],
          onChanged: (value) {
            if (value != null) notifier.setSortOption(value);
          },
        ),
      ],
    );
  }
}

/// Compact All/Income/Expense/Transfer chips (mirrors the type filter
/// already in [_FilterSortSheet] — either surface sets the same
/// [TransactionsFilterNotifier] state) plus a sort control, immediately
/// above the list so the active type/sort is visible without opening the
/// sheet.
class _TransactionToolbar extends ConsumerWidget {
  const _TransactionToolbar({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filter = ref.watch(transactionsFilterProvider);
    final notifier = ref.read(transactionsFilterProvider.notifier);

    Widget typeChip(String label, TransactionType? type) {
      final selected = filter.type == type;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => notifier.setType(type),
      );
    }

    final sortControl = PopupMenuButton<TransactionSortOption>(
      tooltip: l10n.sortByLabel,
      initialValue: filter.sortOption,
      onSelected: notifier.setSortOption,
      itemBuilder: (context) => [
        for (final option in TransactionSortOption.values)
          PopupMenuItem(
            value: option,
            child: Text(option.localizedLabel(l10n)),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            filter.sortOption.localizedLabel(l10n),
            style: theme.textTheme.labelLarge,
          ),
          const Icon(AppSymbols.keyboardArrowDown, size: 18),
        ],
      ),
    );

    // `Wrap` (not `Row`) for the count+chips so they reflow onto a second
    // line on a narrow screen instead of overflowing -- `Spacer`/`Expanded`
    // can't live inside a `Wrap`, so the sort control is a separate,
    // fixed-width trailing sibling in an outer `Row` instead of being
    // pushed to the end of the same `Wrap`.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                '$count ${l10n.transactionCountLabel}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              typeChip(l10n.allTransactionsChipLabel, null),
              typeChip(l10n.incomeLabel, TransactionType.income),
              typeChip(l10n.expenseLabel, TransactionType.expense),
              typeChip(l10n.transferLabel, TransactionType.transfer),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        sortControl,
      ],
    );
  }
}

/// The list body: grouped by calendar date (with a daily net total) when
/// sorted by date, or a flat list when sorted by amount — grouping by date
/// while the primary order is by amount would produce a date-header
/// sequence with no coherent meaning.
class _TransactionTimeline extends StatelessWidget {
  const _TransactionTimeline({
    required this.transactions,
    required this.categoriesById,
    required this.accountsById,
    required this.groupByDate,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final List<TransactionEntity> transactions;
  final Map<String, CategoryEntity> categoriesById;
  final Map<String, AccountEntity> accountsById;
  final bool groupByDate;
  final ValueChanged<TransactionEntity> onEdit;
  final ValueChanged<TransactionEntity> onDuplicate;
  final ValueChanged<TransactionEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    if (!groupByDate) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        itemCount: transactions.length,
        separatorBuilder: (context, _) => Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        itemBuilder: (context, index) => _row(context, transactions[index]),
      );
    }

    final groups = _groupByDate(transactions);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: AppSpacing.md),
            _DateGroupHeader(
              date: group.date,
              transactions: group.transactions,
              accountsById: accountsById,
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final transaction in group.transactions) ...[
              _row(context, transaction),
              if (transaction != group.transactions.last)
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, TransactionEntity transaction) {
    return _TransactionRow(
      transaction: transaction,
      category: categoriesById[transaction.categoryId],
      account: accountsById[transaction.accountId],
      toAccount: accountsById[transaction.toAccountId],
      onTap: () => onEdit(transaction),
      onDuplicate: () => onDuplicate(transaction),
      onDelete: () => onDelete(transaction),
    );
  }
}

class _DateGroupHeader extends StatelessWidget {
  const _DateGroupHeader({
    required this.date,
    required this.transactions,
    required this.accountsById,
  });

  final DateTime date;
  final List<TransactionEntity> transactions;
  final Map<String, AccountEntity> accountsById;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semanticColors = AppSemanticColors.of(context);
    final byCurrency = _orderedByCurrency(
      _summarizeByCurrency(transactions, accountsById),
    );
    final net = byCurrency.isEmpty ? null : byCurrency.first;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            DateFormat.MMMd().format(date).toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          if (net != null) ...[
            const Spacer(),
            Text(
              '${l10n.netLabel} ${net.net >= 0 ? '+' : ''}'
              '${CurrencyFormatter.format(net.net, SupportedCurrencies.byCode(net.currencyCode))}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: net.net < 0
                    ? semanticColors.negativeForeground
                    : semanticColors.positiveForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One transaction row, built specifically for this page's denser timeline
/// rather than reusing the shared `TransactionTile` — that widget is also
/// embedded in Dashboard's recent-activity lists and Savings Goals' account
/// history, and this redesign is scoped to the Transactions page only.
/// Deliberately duplicates `TransactionTile`'s small amount of
/// title/subtitle/color-resolution logic rather than touching that shared
/// widget or extracting a new shared abstraction for a single call site.
class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.onTap,
    required this.onDuplicate,
    required this.onDelete,
    this.category,
    this.account,
    this.toAccount,
  });

  final TransactionEntity transaction;
  final CategoryEntity? category;
  final AccountEntity? account;
  final AccountEntity? toAccount;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
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
        : category?.icon.icon ?? AppSymbols.helpOutline;
    final title = isTransfer
        ? l10n.transferToLabel(toAccount?.name ?? l10n.unknownAccountLabel)
        : category?.name ?? l10n.uncategorizedLabel;

    final subtitleParts = <String>[
      if (transaction.note.isNotEmpty) transaction.note,
      isTransfer
          ? l10n.transferFromLabel(account?.name ?? l10n.unknownAccountLabel)
          : account?.name ?? l10n.unknownAccountLabel,
    ];

    final semanticColors = AppSemanticColors.of(context);
    final amountColor = isTransfer
        ? theme.colorScheme.primary
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitleParts.join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedAmount,
                    style: theme.textTheme.bodyLarge?.copyWith(
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
                  ),
                ],
              ),
              PopupMenuButton<_RowAction>(
                tooltip: l10n.moreActionsTooltip,
                icon: const Icon(AppSymbols.moreVert, size: 20),
                onSelected: (action) {
                  switch (action) {
                    case _RowAction.edit:
                      onTap();
                    case _RowAction.duplicate:
                      onDuplicate();
                    case _RowAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _RowAction.edit,
                    child: Row(
                      children: [
                        const Icon(AppSymbols.edit, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(l10n.editMenuItem),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _RowAction.duplicate,
                    child: Row(
                      children: [
                        const Icon(AppSymbols.contentCopy, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(l10n.duplicateMenuItem),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _RowAction.delete,
                    child: Row(
                      children: [
                        Icon(
                          AppSymbols.deleteOutline,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          l10n.delete,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RowAction { edit, duplicate, delete }

/// FAB menu: reuses the exact same navigation/extras the desktop Dashboard's
/// own quick actions already use (`AppRoutes.transactionNew` with a
/// [TransactionType] extra) — no new creation logic, just another entry
/// point into the existing form.
class _AddActionSheet extends StatelessWidget {
  const _AddActionSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final semanticColors = AppSemanticColors.of(context);
    final theme = Theme.of(context);

    Widget option({
      required IconData icon,
      required Color color,
      required String label,
      required TransactionType? type,
    }) {
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: theme.textTheme.bodyLarge),
        onTap: () {
          Navigator.of(context).pop();
          context.push(AppRoutes.transactionNew, extra: type);
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        option(
          icon: AppSymbols.removeRounded,
          color: semanticColors.negativeForeground,
          label: l10n.dashboardQuickActionAddExpense,
          type: TransactionType.expense,
        ),
        option(
          icon: AppSymbols.addRounded,
          color: semanticColors.positiveForeground,
          label: l10n.dashboardQuickActionAddIncome,
          type: TransactionType.income,
        ),
        option(
          icon: AppSymbols.swapHoriz,
          color: theme.colorScheme.primary,
          label: l10n.dashboardQuickActionTransferMoney,
          type: TransactionType.transfer,
        ),
      ],
    );
  }
}

/// Income/Expense/Net (per currency present, never summed across them — see
/// `CLAUDE.md`'s Coding Standards) plus a single overall transaction count,
/// computed from whatever the current filter/search/month already narrowed
/// [transactions] down to. Shown at every width — a currency beyond the
/// first (LAK-prioritized) renders as a smaller secondary line under the
/// primary figure instead of a second row of cards.
class _CompactSummaryBar extends StatelessWidget {
  const _CompactSummaryBar({
    required this.transactions,
    required this.accountsById,
  });

  final List<TransactionEntity> transactions;
  final Map<String, AccountEntity> accountsById;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final semanticColors = AppSemanticColors.of(context);
    final byCurrency = _orderedByCurrency(
      _summarizeByCurrency(transactions, accountsById),
    );
    final primary = byCurrency.isNotEmpty
        ? byCurrency.first
        : _CurrencySummary(
            currencyCode: SupportedCurrencies.fallback.code,
            income: 0,
            expense: 0,
          );
    final secondary = byCurrency.length > 1
        ? byCurrency.sublist(1)
        : const <_CurrencySummary>[];

    String secondaryFor(double Function(_CurrencySummary) pick) {
      if (secondary.isEmpty) return '';
      final s = secondary.first;
      final currency = SupportedCurrencies.byCode(s.currencyCode);
      return CurrencyFormatter.format(pick(s), currency);
    }

    final primaryCurrency = SupportedCurrencies.byCode(primary.currencyCode);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: columns == 4 ? 2.3 : 2.6,
          children: [
            _SummaryTile(
              label: l10n.incomeLabel,
              value: CurrencyFormatter.format(primary.income, primaryCurrency),
              secondaryValue: secondaryFor((s) => s.income),
              color: semanticColors.positiveForeground,
            ),
            _SummaryTile(
              label: l10n.expenseLabel,
              value: CurrencyFormatter.format(primary.expense, primaryCurrency),
              secondaryValue: secondaryFor((s) => s.expense),
              color: semanticColors.negativeForeground,
            ),
            _SummaryTile(
              label: l10n.netLabel,
              value:
                  '${primary.net >= 0 ? '+' : ''}'
                  '${CurrencyFormatter.format(primary.net, primaryCurrency)}',
              secondaryValue: secondary.isEmpty
                  ? ''
                  : '${secondary.first.net >= 0 ? '+' : ''}'
                        '${secondaryFor((s) => s.net)}',
              color: primary.net < 0
                  ? semanticColors.negativeForeground
                  : semanticColors.primaryForeground,
            ),
            _SummaryTile(
              label: l10n.transactionCountLabel,
              value: '${transactions.length}',
              secondaryValue: '',
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.secondaryValue,
    required this.color,
  });

  final String label;
  final String value;
  final String secondaryValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            if (secondaryValue.isNotEmpty)
              Text(
                secondaryValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CurrencySummary {
  const _CurrencySummary({
    required this.currencyCode,
    required this.income,
    required this.expense,
  });

  final String currencyCode;
  final double income;
  final double expense;

  double get net => income - expense;
}

/// Groups [transactions] by their *account's* currency (never the
/// transaction itself — see `CLAUDE.md`'s Coding Standards), summing
/// income/expense separately per currency. Transfers are excluded from
/// both, matching every other money aggregation in this app (they move
/// money between the user's own accounts rather than earning/spending
/// it). A transaction whose account can no longer be resolved has no
/// currency to attribute it to and is skipped, the same handling
/// `BuildDashboardSummaryUseCase` already uses for the same case.
List<_CurrencySummary> _summarizeByCurrency(
  List<TransactionEntity> transactions,
  Map<String, AccountEntity> accountsById,
) {
  final incomeByCurrency = <String, double>{};
  final expenseByCurrency = <String, double>{};

  for (final transaction in transactions) {
    if (transaction.type == TransactionType.transfer) continue;
    final currencyCode = accountsById[transaction.accountId]?.currencyCode;
    if (currencyCode == null) continue;

    if (transaction.type == TransactionType.income) {
      incomeByCurrency.update(
        currencyCode,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    } else {
      expenseByCurrency.update(
        currencyCode,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
  }

  final currencyCodes = {
    ...incomeByCurrency.keys,
    ...expenseByCurrency.keys,
  }.toList()..sort();

  return [
    for (final code in currencyCodes)
      _CurrencySummary(
        currencyCode: code,
        income: incomeByCurrency[code] ?? 0,
        expense: expenseByCurrency[code] ?? 0,
      ),
  ];
}

/// Puts Lao Kip first when present — Cashly's primary, default-lens
/// currency (see `CLAUDE.md`'s Financial dashboard rules) — ahead of the
/// plain alphabetical order `_summarizeByCurrency` returns, so the summary
/// bar's single "primary" figure is always LAK for a typical Lao user
/// rather than whichever other currency happens to sort first.
List<_CurrencySummary> _orderedByCurrency(List<_CurrencySummary> summaries) {
  final lakIndex = summaries.indexWhere(
    (s) => s.currencyCode == SupportedCurrencies.lak.code,
  );
  if (lakIndex <= 0) return summaries;
  final reordered = [...summaries];
  final lak = reordered.removeAt(lakIndex);
  reordered.insert(0, lak);
  return reordered;
}

class _DateGroup {
  const _DateGroup({required this.date, required this.transactions});

  final DateTime date;
  final List<TransactionEntity> transactions;
}

/// Groups already-sorted [transactions] by calendar day, preserving the
/// incoming order both across groups and within each group (a `Map`'s
/// insertion order, which matches a date-sorted input exactly).
List<_DateGroup> _groupByDate(List<TransactionEntity> transactions) {
  final groups = <DateTime, List<TransactionEntity>>{};
  for (final transaction in transactions) {
    final day = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    groups.putIfAbsent(day, () => []).add(transaction);
  }
  return [
    for (final entry in groups.entries)
      _DateGroup(date: entry.key, transactions: entry.value),
  ];
}
