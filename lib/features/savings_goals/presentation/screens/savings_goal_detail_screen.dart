import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/providers/transaction_controller.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../../domain/entities/goal_completion_estimate.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/entities/savings_goal_progress.dart';
import '../providers/savings_goal_controller.dart';
import '../providers/savings_goal_providers.dart';
import '../widgets/contribution_bottom_sheet.dart';
import '../widgets/goal_celebration_overlay.dart';
import '../widgets/goal_progress_ring.dart';

/// Reached by id (not `extra`), unlike every other edit-form-adjacent
/// screen in the app, because this one must keep watching live data
/// (progress, activity, completion estimate) rather than display a
/// snapshot passed in at navigation time.
class SavingsGoalDetailScreen extends ConsumerWidget {
  const SavingsGoalDetailScreen({required this.goalId, super.key});

  final String goalId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavingsGoalEntity goal,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.deleteGoalTitle,
      message: l10n.deleteGoalMessage,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
    );

    if (!confirmed || !context.mounted) return;

    final notifier = ref.read(savingsGoalControllerProvider.notifier);
    final success = await notifier.deleteGoal(goal.id);

    if (!context.mounted) return;
    if (success) {
      context.pop();
    } else {
      final message = notifier.failure?.message ?? l10n.deleteGoalFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  Future<void> _toggleArchived(
    BuildContext context,
    WidgetRef ref,
    SavingsGoalEntity goal,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(savingsGoalControllerProvider.notifier);
    final success = goal.isArchived
        ? await notifier.unarchiveGoal(goal.id)
        : await notifier.archiveGoal(goal.id);

    if (!context.mounted) return;
    if (!success) {
      final message = notifier.failure?.message ?? l10n.saveGoalFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

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

    final notifier = ref.read(transactionControllerProvider.notifier);
    final success = await notifier.deleteTransaction(transaction.id);

    if (!context.mounted) return;
    if (!success) {
      final message =
          notifier.failure?.message ?? l10n.deleteTransactionFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  Future<void> _openContributionSheet(
    BuildContext context,
    SavingsGoalEntity goal,
    AppCurrency currency, {
    double? prefillAmount,
  }) {
    return AppBottomSheet.show<bool>(
      context,
      isScrollControlled: true,
      builder: (context) => ContributionBottomSheet(
        goal: goal,
        currency: currency,
        prefillAmount: prefillAmount,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progressAsync = ref.watch(savingsGoalProgressByIdProvider(goalId));
    final loadedProgress = progressAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(loadedProgress?.goal.name ?? l10n.savingsGoalsTitle),
        actions: loadedProgress == null
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.goalFormEditTitle,
                  onPressed: () => context.push(
                    AppRoutes.savingsGoalEditPath(loadedProgress.goal.id),
                    extra: loadedProgress.goal,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'archive':
                        _toggleArchived(context, ref, loadedProgress.goal);
                      case 'delete':
                        _confirmDelete(context, ref, loadedProgress.goal);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(
                        loadedProgress.goal.isArchived
                            ? l10n.unarchiveMenuItem
                            : l10n.archiveMenuItem,
                      ),
                    ),
                    PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                  ],
                ),
              ],
      ),
      body: progressAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => ErrorView(message: '$error'),
        data: (progress) {
          if (progress == null) {
            return ErrorView(message: l10n.goalNotFoundMessage);
          }
          return GoalCelebrationOverlay(
            goalId: goalId,
            child: ResponsiveCenter(
              child: _DetailBody(
                progress: progress,
                onContribute: ({double? prefillAmount}) =>
                    _openContributionSheet(
                      context,
                      progress.goal,
                      SupportedCurrencies.byCode(progress.currencyCode),
                      prefillAmount: prefillAmount,
                    ),
                onDeleteTransaction: (transaction) =>
                    _confirmDeleteTransaction(context, ref, transaction),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.progress,
    required this.onContribute,
    required this.onDeleteTransaction,
  });

  final SavingsGoalProgress progress;
  final void Function({double? prefillAmount}) onContribute;
  final void Function(TransactionEntity transaction) onDeleteTransaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final goal = progress.goal;
    final currency = SupportedCurrencies.byCode(progress.currencyCode);
    final estimateAsync = ref.watch(goalCompletionEstimateProvider(progress));
    final activityAsync = ref.watch(goalAccountActivityProvider(goal));
    final accounts = ref.watch(accountsProvider(true)).value ?? [];
    final categories =
        ref
            .watch(categoriesProvider((type: null, includeArchived: true)))
            .value ??
        [];
    final accountsById = {for (final account in accounts) account.id: account};
    final categoriesById = {
      for (final category in categories) category.id: category,
    };
    final isDue = goal.isReminderDue(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        Center(
          child: GoalProgressRing(
            percentage: progress.percentageComplete,
            color: goal.color.color,
            isCompleted: progress.isCompleted,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyFormatter.format(progress.currentAmount, currency),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '/ ${CurrencyFormatter.format(goal.targetAmount, currency)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (progress.account.isArchived) ...[
          _InfoBanner(
            icon: Icons.archive_outlined,
            message: l10n.linkedAccountArchivedMessage,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        estimateAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (estimate) => Text(
            _formatEstimateMessage(l10n, estimate),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        if (isDue) ...[
          const SizedBox(height: AppSpacing.md),
          _InfoBanner(
            icon: Icons.notifications_active_outlined,
            message: l10n.contributionDueBannerMessage(
              CurrencyFormatter.format(goal.autoContributionAmount!, currency),
            ),
            action: TextButton(
              onPressed: () =>
                  onContribute(prefillAmount: goal.autoContributionAmount),
              child: Text(l10n.contributeButton),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () => onContribute(),
          icon: const Icon(Icons.add),
          label: Text(l10n.contributeButton),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.accountActivityTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        activityAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => ErrorView(message: '$error'),
          data: (transactions) {
            if (transactions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  l10n.noAccountActivityYetMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final transaction in transactions)
                  TransactionTile(
                    transaction: transaction,
                    category: categoriesById[transaction.categoryId],
                    account: accountsById[transaction.accountId],
                    toAccount: accountsById[transaction.toAccountId],
                    onTap: () => context.push(
                      AppRoutes.transactionEditPath(transaction.id),
                      extra: transaction,
                    ),
                    onDelete: () => onDeleteTransaction(transaction),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

String _formatEstimateMessage(
  AppLocalizations l10n,
  GoalCompletionEstimate estimate,
) {
  final dateText = estimate.estimatedDate == null
      ? null
      : DateFormat.yMMMd().format(estimate.estimatedDate!);
  return switch (estimate.basis) {
    GoalCompletionEstimateBasis.alreadyCompleted =>
      l10n.estimatedCompletionCompletedMessage,
    GoalCompletionEstimateBasis.scheduled =>
      l10n.estimatedCompletionScheduledMessage(dateText!),
    GoalCompletionEstimateBasis.trailingAverage =>
      l10n.estimatedCompletionTrailingAverageMessage(dateText!),
    GoalCompletionEstimateBasis.insufficientData =>
      l10n.estimatedCompletionInsufficientDataMessage,
  };
}
