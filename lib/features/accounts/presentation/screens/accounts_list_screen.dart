import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_skeleton_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/account_currency_summary.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/account_type.dart';
import '../providers/account_controller.dart';
import '../providers/account_providers.dart';
import '../utils/account_type_label.dart';
import '../widgets/account_card.dart';

enum _AccountSort { custom, highest, lowest, name, type, currency }

class AccountsListScreen extends ConsumerStatefulWidget {
  const AccountsListScreen({super.key});

  @override
  ConsumerState<AccountsListScreen> createState() => _AccountsListScreenState();
}

class _AccountsListScreenState extends ConsumerState<AccountsListScreen> {
  String? _currencyCode;
  AccountType? _type;
  _AccountSort _sort = _AccountSort.custom;

  Future<void> _delete(AccountEntity account) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.deleteAccountTitle,
      message: l10n.deleteAccountMessage(account.name),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed || !mounted) return;
    final controller = ref.read(accountControllerProvider.notifier);
    if (!await controller.deleteAccount(account.id) && mounted) {
      AppSnackbar.showError(
        context,
        controller.failure?.message ?? l10n.deleteAccountFailedMessage,
      );
    }
  }

  Future<void> _archive(AccountEntity account) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(accountControllerProvider.notifier);
    final success = account.isArchived
        ? await controller.unarchiveAccount(account.id)
        : await controller.archiveAccount(account.id);
    if (!success && mounted) {
      AppSnackbar.showError(
        context,
        controller.failure?.message ?? l10n.updateAccountFailedMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showArchived = ref.watch(showArchivedAccountsProvider);
    final accountsAsync = ref.watch(accountsProvider(showArchived));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountsTitle),
        actions: [
          PopupMenuButton<_AccountSort>(
            tooltip: 'Manage accounts',
            icon: const Icon(Icons.tune_rounded),
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _AccountSort.custom,
                child: Text('Custom order'),
              ),
              const PopupMenuItem(
                value: _AccountSort.highest,
                child: Text('Highest balance'),
              ),
              const PopupMenuItem(
                value: _AccountSort.lowest,
                child: Text('Lowest balance'),
              ),
              const PopupMenuItem(
                value: _AccountSort.name,
                child: Text('Account name'),
              ),
              const PopupMenuItem(
                value: _AccountSort.type,
                child: Text('Account type'),
              ),
              const PopupMenuItem(
                value: _AccountSort.currency,
                child: Text('Currency'),
              ),
            ],
          ),
          IconButton(
            tooltip: showArchived
                ? l10n.hideArchivedTooltip
                : l10n.showArchivedTooltip,
            icon: Icon(
              Icons.inventory_2_outlined,
              color: showArchived
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () =>
                ref.read(showArchivedAccountsProvider.notifier).toggle(),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: accountsAsync.when(
          loading: () => const AppSkeletonList(),
          error: (error, _) => ErrorView(message: '$error'),
          data: (accounts) => _buildContent(context, l10n, accounts),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('accounts-fab'),
        heroTag: 'accounts-fab',
        tooltip: l10n.addAccountButton,
        onPressed: () => context.push(AppRoutes.accountNew),
        icon: const Icon(Icons.account_balance_wallet_outlined),
        label: Text(l10n.addAccountButton),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    List<AccountEntity> accounts,
  ) {
    if (accounts.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.noAccountsYetTitle,
        message: l10n.noAccountsYetMessage,
        action: FilledButton.icon(
          onPressed: () => context.push(AppRoutes.accountNew),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.addAccountButton),
        ),
      );
    }
    final allSummaries = buildAccountCurrencySummaries(accounts);
    final selected = allSummaries.firstWhere(
      (summary) => summary.currencyCode == _currencyCode,
      orElse: () => allSummaries.first,
    );
    final visible = accounts
        .where(
          (account) =>
              (_currencyCode == null ||
                  account.currencyCode == _currencyCode) &&
              (_type == null || account.type == _type),
        )
        .toList();
    _sortAccounts(visible);
    final visibleGroups = buildAccountCurrencySummaries(visible);
    final availableTypes = AccountType.values
        .where((type) => accounts.any((account) => account.type == type))
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 860 ? 2 : 1;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            112,
          ),
          children: [
            _AccountSummary(summary: selected),
            const SizedBox(height: AppSpacing.md),
            if (allSummaries.length > 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final summary in allSummaries)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(summary.currencyCode),
                          selected:
                              selected.currencyCode == summary.currencyCode,
                          onSelected: (_) => setState(
                            () => _currencyCode = summary.currencyCode,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _type == null,
                    onSelected: (_) => setState(() => _type = null),
                  ),
                  for (final type in availableTypes)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(type.localizedLabel(l10n)),
                        selected: _type == type,
                        onSelected: (_) => setState(() => _type = type),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (visible.isEmpty)
              EmptyState(
                icon: Icons.filter_list_off_outlined,
                title: 'No matching accounts',
                message: 'Choose another account type or currency filter.',
                action: TextButton(
                  onPressed: () => setState(() {
                    _type = null;
                    _currencyCode = null;
                  }),
                  child: const Text('Clear filters'),
                ),
              )
            else
              for (final group in visibleGroups) ...[
                _CurrencyHeader(summary: group),
                const SizedBox(height: AppSpacing.sm),
                _AccountGrid(
                  columns: columns,
                  accounts: group.accounts,
                  summary: group,
                  onEdit: _edit,
                  onArchive: _archive,
                  onDelete: _delete,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
          ],
        );
      },
    );
  }

  void _sortAccounts(List<AccountEntity> accounts) {
    switch (_sort) {
      case _AccountSort.custom:
        accounts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _AccountSort.highest:
        accounts.sort((a, b) => b.balance.compareTo(a.balance));
      case _AccountSort.lowest:
        accounts.sort((a, b) => a.balance.compareTo(b.balance));
      case _AccountSort.name:
        accounts.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _AccountSort.type:
        accounts.sort((a, b) => a.type.index.compareTo(b.type.index));
      case _AccountSort.currency:
        accounts.sort((a, b) => a.currencyCode.compareTo(b.currencyCode));
    }
  }

  void _edit(AccountEntity account) =>
      context.push(AppRoutes.accountEditPath(account.id), extra: account);
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.summary});
  final AccountCurrencySummary summary;
  @override
  Widget build(BuildContext context) {
    final currency = SupportedCurrencies.byCode(summary.currencyCode);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net worth',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.format(summary.netWorth, currency),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Assets',
                    value: CurrencyFormatter.format(summary.assets, currency),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Liabilities',
                    value: CurrencyFormatter.format(
                      -summary.liabilities,
                      currency,
                    ),
                    negative: summary.liabilities > 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.negative = false,
  });
  final String label;
  final String value;
  final bool negative;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: negative ? Theme.of(context).colorScheme.error : null,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

class _CurrencyHeader extends StatelessWidget {
  const _CurrencyHeader({required this.summary});
  final AccountCurrencySummary summary;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          '${summary.currencyCode} Accounts · ${summary.accounts.length}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      Text(
        CurrencyFormatter.format(
          summary.netWorth,
          SupportedCurrencies.byCode(summary.currencyCode),
        ),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _AccountGrid extends StatelessWidget {
  const _AccountGrid({
    required this.columns,
    required this.accounts,
    required this.summary,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });
  final int columns;
  final List<AccountEntity> accounts;
  final AccountCurrencySummary summary;
  final ValueChanged<AccountEntity> onEdit;
  final ValueChanged<AccountEntity> onArchive;
  final ValueChanged<AccountEntity> onDelete;
  @override
  Widget build(BuildContext context) {
    final children = accounts
        .map(
          (account) => AccountCard(
            account: account,
            onTap: () => onEdit(account),
            percentOfTotalBalance: summary.assetShareFor(account),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit(account);
                  case 'archive':
                    onArchive(account);
                  case 'delete':
                    onDelete(account);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit account')),
                PopupMenuItem(
                  value: 'archive',
                  child: Text(account.isArchived ? 'Unarchive' : 'Archive'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        )
        .toList();
    return columns == 1
        ? Column(
            children: [
              for (final child in children)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: child,
                ),
            ],
          )
        : GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 3.35,
            children: children,
          );
  }
}
