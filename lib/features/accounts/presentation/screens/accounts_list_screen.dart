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
            icon: Icon(showArchived ? Icons.archive : Icons.archive_outlined),
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
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addAccountButton),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              itemCount: accounts.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final account = accounts[index];
                return AccountCard(
                  account: account,
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
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.accountNew),
        child: const Icon(Icons.add),
      ),
    );
  }
}
