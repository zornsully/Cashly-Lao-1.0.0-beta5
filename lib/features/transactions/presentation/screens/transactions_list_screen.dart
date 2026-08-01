import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_currency.dart';
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
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_sort_option.dart';
import '../../domain/entities/transaction_type.dart';
import '../providers/transaction_controller.dart';
import '../providers/transaction_providers.dart';
import '../utils/transaction_sort_option_label.dart';
import '../widgets/transaction_tile.dart';

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen> {
  static const double _wideLayoutBreakpoint = 760;

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
    final usesWideLayout =
        MediaQuery.sizeOf(context).width >= _wideLayoutBreakpoint;

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
        bottom: MonthSelectorHeader(
          month: month,
          onPrevious: () => ref
              .read(selectedTransactionsMonthProvider.notifier)
              .previousMonth(),
          onNext: () =>
              ref.read(selectedTransactionsMonthProvider.notifier).nextMonth(),
        ),
      ),
      body: ResponsiveCenter(
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

            final list = ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return TransactionTile(
                  transaction: transaction,
                  category: categoriesById[transaction.categoryId],
                  account: accountsById[transaction.accountId],
                  toAccount: accountsById[transaction.toAccountId],
                  onTap: () => context.push(
                    AppRoutes.transactionEditPath(transaction.id),
                    extra: transaction,
                  ),
                  onDuplicate: () => context.push(
                    AppRoutes.transactionNew,
                    extra: transaction,
                  ),
                  onDelete: () => _confirmDelete(context, ref, transaction),
                );
              },
            );

            if (!usesWideLayout) return list;

            // Desktop gets an additional summary strip above the list — the
            // existing search/filter affordances in the AppBar already work
            // fine at any width, so this only adds what was actually
            // missing rather than duplicating a working search box.
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: _TransactionsSummaryRow(
                    transactions: transactions,
                    accountsById: accountsById,
                  ),
                ),
                Expanded(child: list),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // See the same fix's comment in accounts_list_screen.dart -- every
        // shell tab's FAB otherwise shares Flutter's implicit default hero
        // tag, since the shell keeps all branches mounted simultaneously.
        // The key gives integration tests an unambiguous target too.
        key: const ValueKey('transactions-fab'),
        heroTag: 'transactions-fab',
        onPressed: () => context.push(AppRoutes.transactionNew),
        child: const Icon(AppSymbols.addRounded),
      ),
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

/// Income/Expense/Net (per currency present, never summed across them —
/// see `CLAUDE.md`'s Coding Standards) plus a single overall transaction
/// count, computed from whatever the current filter/search/month already
/// narrowed [transactions] down to. Desktop-only companion to the list,
/// not a replacement for the currency-exact figures shown per row.
class _TransactionsSummaryRow extends StatelessWidget {
  const _TransactionsSummaryRow({
    required this.transactions,
    required this.accountsById,
  });

  final List<TransactionEntity> transactions;
  final Map<String, AccountEntity> accountsById;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final semanticColors = AppSemanticColors.of(context);
    final byCurrency = _summarizeByCurrency(transactions, accountsById);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final summary in byCurrency) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final currency = SupportedCurrencies.byCode(summary.currencyCode);
              final columns = constraints.maxWidth >= 640 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 2.0,
                children: [
                  _SummaryCard(
                    label: byCurrency.length > 1
                        ? '${l10n.incomeLabel} (${summary.currencyCode})'
                        : l10n.incomeLabel,
                    value: CurrencyFormatter.format(summary.income, currency),
                    color: semanticColors.positiveForeground,
                    icon: AppSymbols.arrowDownward,
                  ),
                  _SummaryCard(
                    label: byCurrency.length > 1
                        ? '${l10n.expenseLabel} (${summary.currencyCode})'
                        : l10n.expenseLabel,
                    value: CurrencyFormatter.format(summary.expense, currency),
                    color: semanticColors.negativeForeground,
                    icon: AppSymbols.arrowUpward,
                  ),
                  _SummaryCard(
                    label: byCurrency.length > 1
                        ? '${l10n.netLabel} (${summary.currencyCode})'
                        : l10n.netLabel,
                    value: CurrencyFormatter.format(summary.net, currency),
                    color: summary.net < 0
                        ? semanticColors.negativeForeground
                        : semanticColors.primaryForeground,
                    icon: summary.net < 0
                        ? AppSymbols.trendingDown
                        : AppSymbols.trendingUp,
                  ),
                  if (byCurrency.first == summary)
                    _SummaryCard(
                      label: l10n.transactionCountLabel,
                      value: '${transactions.length}',
                      color: Theme.of(context).colorScheme.primary,
                      icon: AppSymbols.receiptLong,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                ],
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
