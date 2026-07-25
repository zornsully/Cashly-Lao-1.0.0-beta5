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
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../accounts/presentation/widgets/account_card.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../budget/presentation/widgets/budget_progress_tile.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/providers/transaction_controller.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/category_spending_bar.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _confirmDeleteTransaction(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final month = DateTime.now();
    final budgetProgress =
        ref
            .watch(
              budgetProgressForMonthProvider(DateTime(month.year, month.month)),
            )
            .value ??
        const [];
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(AppSymbols.savings),
            tooltip: l10n.savingsGoalsTooltip,
            onPressed: () => context.push(AppRoutes.savingsGoals),
          ),
          IconButton(
            icon: const Icon(Icons.insert_chart_outlined),
            tooltip: l10n.reportsTooltip,
            onPressed: () => context.push(AppRoutes.reports),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: summaryAsync.when(
          loading: () => const AppLoadingIndicator(),
          error: (error, _) => ErrorView(message: '$error'),
          data: (summary) {
            if (!summary.hasAnyAccounts) {
              return EmptyState(
                icon: Icons.dashboard_customize_outlined,
                title: l10n.welcomeToCashly,
                message: l10n.addFirstAccountMessage,
                action: FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.accounts),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addAccountButton),
                ),
              );
            }

            final currencies = summary.totalBalanceByCurrency.keys.toList()
              ..sort();
            final categoriesById = {
              for (final category in summary.categories) category.id: category,
            };
            final accountsById = {
              for (final account in summary.accounts) account.id: account,
            };

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                Text(
                  DateFormat.yMMMM().format(month),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final currencyCode in currencies) ...[
                  _CurrencyOverview(
                    currencyCode: currencyCode,
                    summary: summary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _SectionHeader(
                  title: l10n.recentTransactionsTitle,
                  onSeeAll: () => context.go(AppRoutes.transactions),
                ),
                if (!summary.hasAnyTransactionsThisMonth)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Text(l10n.noTransactionsThisMonth),
                  )
                else
                  for (final transaction in summary.recentTransactions)
                    TransactionTile(
                      transaction: transaction,
                      category: categoriesById[transaction.categoryId],
                      account: accountsById[transaction.accountId],
                      toAccount: accountsById[transaction.toAccountId],
                      onTap: () => context.push(
                        AppRoutes.transactionEditPath(transaction.id),
                        extra: transaction,
                      ),
                      onDelete: () =>
                          _confirmDeleteTransaction(context, ref, transaction),
                    ),
                const SizedBox(height: AppSpacing.lg),
                if (summary.spendingByCategory.values.any(
                  (s) => s.isNotEmpty,
                )) ...[
                  _SectionHeader(title: l10n.spendingByCategoryTitle),
                  for (final currencyCode in currencies)
                    if (summary.spendingByCategory[currencyCode]?.isNotEmpty ??
                        false)
                      Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (currencies.length > 1) ...[
                                Text(
                                  currencyCode,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                              for (final spending
                                  in summary.spendingByCategory[currencyCode]!)
                                CategorySpendingBar(
                                  spending: spending,
                                  currency: SupportedCurrencies.byCode(
                                    currencyCode,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (budgetProgress.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.budgetsTitle,
                    onSeeAll: () => context.go(AppRoutes.budget),
                  ),
                  for (final progress in budgetProgress)
                    BudgetProgressTile(
                      progress: progress,
                      onTap: () => context.push(
                        AppRoutes.budgetEditPath(progress.budget.id),
                        extra: progress.budget,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _SectionHeader(
                  title: l10n.accountBalancesTitle,
                  onSeeAll: () => context.go(AppRoutes.accounts),
                ),
                for (final account in summary.accounts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AccountCard(
                      account: account,
                      onTap: () => context.push(
                        AppRoutes.accountEditPath(account.id),
                        extra: account,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CurrencyOverview extends StatelessWidget {
  const _CurrencyOverview({required this.currencyCode, required this.summary});

  final String currencyCode;
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final currency = SupportedCurrencies.byCode(currencyCode);
    final balance = summary.totalBalanceByCurrency[currencyCode] ?? 0;
    final income = summary.totalIncomeByCurrency[currencyCode] ?? 0;
    final expense = summary.totalExpenseByCurrency[currencyCode] ?? 0;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatCard(
          label: l10n.totalBalanceLabel(currencyCode),
          amount: balance,
          currency: currency,
          icon: AppSymbols.accountBalanceWallet,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: l10n.incomeMonthLabel,
                amount: income,
                currency: currency,
                icon: Icons.arrow_downward,
                color: AppSemanticColors.of(context).positiveForeground,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatCard(
                label: l10n.expenseMonthLabel,
                amount: expense,
                currency: currency,
                icon: Icons.arrow_upward,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(AppLocalizations.of(context)!.seeAll),
            ),
        ],
      ),
    );
  }
}
