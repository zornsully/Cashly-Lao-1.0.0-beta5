import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_skeleton_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/month_selector_header.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../l10n/app_localizations.dart';
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
              icon: const Icon(Icons.close),
              tooltip: l10n.closeSearchTooltip,
              onPressed: _stopSearching,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.searchTooltip,
              onPressed: () => setState(() => _isSearching = true),
            ),
            Badge(
              isLabelVisible: filter.isActive,
              smallSize: 8,
              child: IconButton(
                icon: const Icon(Icons.tune),
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
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addTransactionButton),
                ),
              );
            }

            return ListView.builder(
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
                  onDelete: () => _confirmDelete(context, ref, transaction),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.transactionNew),
        child: const Icon(Icons.add),
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
          decoration: InputDecoration(labelText: l10n.categoryFilterLabel),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(l10n.allCategoriesLabel),
            ),
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
