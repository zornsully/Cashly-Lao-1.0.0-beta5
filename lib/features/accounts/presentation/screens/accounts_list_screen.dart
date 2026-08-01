import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_skeleton_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/account_entity.dart';
import '../providers/account_controller.dart';
import '../providers/account_providers.dart';
import '../widgets/account_card.dart';

class AccountsListScreen extends ConsumerWidget {
  const AccountsListScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AccountEntity account,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.deleteAccountTitle,
      message: l10n.deleteAccountMessage(account.name),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
    );

    if (!confirmed || !context.mounted) return;

    final success = await ref
        .read(accountControllerProvider.notifier)
        .deleteAccount(account.id);

    if (!context.mounted) return;
    if (!success) {
      final message =
          ref.read(accountControllerProvider.notifier).failure?.message ??
          l10n.deleteAccountFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  Future<void> _toggleArchived(
    BuildContext context,
    WidgetRef ref,
    AccountEntity account,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(accountControllerProvider.notifier);
    final success = account.isArchived
        ? await notifier.unarchiveAccount(account.id)
        : await notifier.archiveAccount(account.id);

    if (!context.mounted) return;
    if (!success) {
      final message =
          notifier.failure?.message ?? l10n.updateAccountFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final showArchived = ref.watch(showArchivedAccountsProvider);
    final accountsAsync = ref.watch(accountsProvider(showArchived));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountsTitle),
        actions: [
          IconButton(
            tooltip: showArchived
                ? l10n.hideArchivedTooltip
                : l10n.showArchivedTooltip,
            icon: Icon(
              AppSymbols.archive,
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
          data: (accounts) {
            if (accounts.isEmpty) {
              // Note: with showArchived == true the query returns archived
              // *and* active accounts, so an empty result here always means
              // there are no accounts at all yet — never "no archived ones".
              return EmptyState(
                icon: AppSymbols.accountBalanceWallet,
                title: l10n.noAccountsYetTitle,
                message: l10n.noAccountsYetMessage,
                action: FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.accountNew),
                  icon: const Icon(AppSymbols.addRounded),
                  label: Text(l10n.addAccountButton),
                ),
              );
            }

            final totalsByCurrency = _totalBalanceByCurrency(accounts);

            Widget buildCard(AccountEntity account) {
              final currencyTotal = totalsByCurrency[account.currencyCode];
              return AccountCard(
                account: account,
                percentOfTotalBalance:
                    (currencyTotal == null || currencyTotal <= 0)
                    ? null
                    : account.balance / currencyTotal,
                onTap: () => context.push(
                  AppRoutes.accountEditPath(account.id),
                  extra: account,
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'archive':
                        _toggleArchived(context, ref, account);
                      case 'delete':
                        _confirmDelete(context, ref, account);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(
                        account.isArchived
                            ? l10n.unarchiveMenuItem
                            : l10n.archiveMenuItem,
                      ),
                    ),
                    PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                // Content width (not window width) drives the column count,
                // same reasoning as Dashboard's Quick Actions grid — one
                // implementation serves phones, tablets, and desktop.
                final columns = (constraints.maxWidth / 360).floor().clamp(
                  1,
                  3,
                );
                if (columns == 1) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    itemCount: accounts.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => buildCard(accounts[index]),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xxl,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 3.4,
                  ),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) => buildCard(accounts[index]),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // The navigation shell keeps every tab's branch mounted at once
        // (so state survives switching tabs), which means every tab's own
        // FAB coexists in the same Element subtree simultaneously. Without
        // an explicit tag, all of them share Flutter's implicit default
        // FAB hero tag, and Hero's own duplicate-tag check throws the
        // moment any hero flight scans that subtree. These add-flows are
        // unrelated screens, not meant to morph into each other, so opting
        // out entirely is correct, not just a workaround. The same key
        // also gives integration tests an unambiguous way to find this
        // exact FAB when another branch's identical-icon FAB is also
        // mounted (see integration_test/app_flow_test.dart).
        key: const ValueKey('accounts-fab'),
        heroTag: 'accounts-fab',
        onPressed: () => context.push(AppRoutes.accountNew),
        child: const Icon(AppSymbols.addRounded),
      ),
    );
  }
}

/// Sums every visible account's balance per currency (never mixed across
/// currencies — see `CLAUDE.md`'s Coding Standards), so each card can show
/// its own share of the total. Archived accounts are included exactly when
/// they're already part of [accounts] — this mirrors whatever the screen
/// is currently showing rather than a second, independent definition of
/// "total."
Map<String, double> _totalBalanceByCurrency(List<AccountEntity> accounts) {
  final totals = <String, double>{};
  for (final account in accounts) {
    totals.update(
      account.currencyCode,
      (value) => value + account.balance,
      ifAbsent: () => account.balance,
    );
  }
  return totals;
}
