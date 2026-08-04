import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_skeleton_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/month_selector_header.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/domain/entities/category_type.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/budget_progress.dart';
import '../providers/budget_controller.dart';
import '../providers/budget_providers.dart';
import '../widgets/budget_progress_tile.dart';

class BudgetsListScreen extends ConsumerWidget {
  const BudgetsListScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BudgetProgress progress,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.deleteBudgetTitle,
      message: l10n.deleteBudgetMessage(progress.category.name),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
    );

    if (!confirmed || !context.mounted) return;

    final success = await ref
        .read(budgetControllerProvider.notifier)
        .deleteBudget(progress.budget.id);

    if (!context.mounted) return;
    if (!success) {
      final message =
          ref.read(budgetControllerProvider.notifier).failure?.message ??
          l10n.deleteBudgetFailedMessage;
      AppSnackbar.showError(context, message);
    } else {
      AppSnackbar.showSuccess(context, 'Budget deleted.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final month = ref.watch(selectedBudgetMonthProvider);
    final categoriesAsync = ref.watch(
      categoriesProvider((type: CategoryType.expense, includeArchived: true)),
    );
    final progressAsync = ref.watch(budgetProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgetTitle),
        bottom: MonthSelectorHeader(
          month: month,
          onPrevious: () =>
              ref.read(selectedBudgetMonthProvider.notifier).previousMonth(),
          onNext: () =>
              ref.read(selectedBudgetMonthProvider.notifier).nextMonth(),
        ),
      ),
      body: ResponsiveCenter(
        child: categoriesAsync.when(
          loading: () => const AppSkeletonList(),
          error: (error, _) => ErrorView(message: '$error'),
          data: (categories) {
            if (categories.isEmpty) {
              return EmptyState(
                icon: AppSymbols.category,
                title: l10n.noExpenseCategoriesYetTitle,
                message: l10n.addExpenseCategoryFirstMessage,
              );
            }

            return progressAsync.when(
              loading: () => const AppSkeletonList(),
              error: (error, _) => ErrorView(message: '$error'),
              data: (progressList) {
                final progressByCategory = {
                  for (final progress in progressList)
                    progress.category.id: progress,
                };
                // Keep an archived category visible only while it still has
                // a budget, so every selected-month budget remains
                // editable/deletable without offering new budgets for
                // categories the user has retired.
                final visibleCategories = categories
                    .where(
                      (category) =>
                          !category.isArchived ||
                          progressByCategory.containsKey(category.id),
                    )
                    .toList();
                if (visibleCategories.isEmpty) {
                  return EmptyState(
                    icon: AppSymbols.savings,
                    title: 'No budgets for this month',
                    message: 'Add an expense category to set a monthly budget.',
                  );
                }

                Widget buildTile(int index) {
                  final category = visibleCategories[index];
                  final progress = progressByCategory[category.id];

                  if (progress != null) {
                    return BudgetProgressTile(
                      progress: progress,
                      onTap: () => context.push(
                        AppRoutes.budgetEditPath(progress.budget.id),
                        extra: progress.budget,
                      ),
                      onDelete: () => _confirmDelete(context, ref, progress),
                    );
                  }

                  return _NoBudgetTile(category: category, month: month);
                }

                return Column(
                  children: [
                    if (progressList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          0,
                        ),
                        child: _BudgetSummaryHeader(progressList: progressList),
                      ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Content width (not window width) drives the
                          // column count — same reasoning as Accounts' and
                          // Dashboard's own responsive grids.
                          final columns = (constraints.maxWidth / 360)
                              .floor()
                              .clamp(1, 3);
                          if (columns == 1) {
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.md,
                                AppSpacing.md,
                                AppSpacing.xxl,
                              ),
                              itemCount: visibleCategories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) => buildTile(index),
                            );
                          }
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.md,
                              AppSpacing.md,
                              AppSpacing.xxl,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: AppSpacing.sm,
                                  mainAxisSpacing: AppSpacing.sm,
                                  childAspectRatio: 2.2,
                                ),
                            itemCount: visibleCategories.length,
                            itemBuilder: (context, index) => buildTile(index),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NoBudgetTile extends StatelessWidget {
  const _NoBudgetTile({required this.category, required this.month});

  final CategoryEntity category;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: category.color.color.withValues(alpha: 0.16),
            child: Icon(
              category.icon.icon,
              color: category.color.color,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l10n.noBudgetSetLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: () => context.push(
              AppRoutes.budgetNew,
              extra: (category: category, month: month),
            ),
            child: Text(l10n.setBudgetButton),
          ),
        ],
      ),
    );
  }
}

/// This month's total budgeted/spent/remaining, per currency (never mixed
/// across currencies — see CLAUDE.md's Coding Standards), computed from
/// whatever budgets are currently shown.
class _BudgetSummaryHeader extends StatelessWidget {
  const _BudgetSummaryHeader({required this.progressList});

  final List<BudgetProgress> progressList;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final semanticColors = AppSemanticColors.of(context);
    final byCurrency = _summarizeByCurrency(progressList);
    final multiCurrency = byCurrency.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in byCurrency.entries) ...[
          Builder(
            builder: (context) {
              final currency = SupportedCurrencies.byCode(entry.key);
              final remaining = entry.value.budgeted - entry.value.spent;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 480 ? 3 : 1;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: columns == 1 ? 4.4 : 2.0,
                    children: [
                      _BudgetSummaryCard(
                        label: multiCurrency
                            ? '${l10n.budgetedTotalLabel} (${entry.key})'
                            : l10n.budgetedTotalLabel,
                        value: CurrencyFormatter.format(
                          entry.value.budgeted,
                          currency,
                        ),
                        color: Theme.of(context).colorScheme.primary,
                        icon: AppSymbols.savings,
                      ),
                      _BudgetSummaryCard(
                        label: multiCurrency
                            ? '${l10n.spentTotalLabel} (${entry.key})'
                            : l10n.spentTotalLabel,
                        value: CurrencyFormatter.format(
                          entry.value.spent,
                          currency,
                        ),
                        color: semanticColors.negativeForeground,
                        icon: AppSymbols.trendingUp,
                      ),
                      _BudgetSummaryCard(
                        label: multiCurrency
                            ? '${l10n.remainingTotalLabel} (${entry.key})'
                            : l10n.remainingTotalLabel,
                        value: CurrencyFormatter.format(remaining, currency),
                        color: remaining < 0
                            ? semanticColors.negativeForeground
                            : semanticColors.positiveForeground,
                        icon: AppSymbols.accountBalanceWallet,
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
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
    return AppCard(
      margin: EdgeInsets.zero,
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sums this month's budgeted/spent amounts per currency (never mixed
/// across currencies — see CLAUDE.md's Coding Standards).
Map<String, ({double budgeted, double spent})> _summarizeByCurrency(
  List<BudgetProgress> progressList,
) {
  final totals = <String, ({double budgeted, double spent})>{};
  for (final progress in progressList) {
    final code = progress.budget.currencyCode;
    final existing = totals[code] ?? (budgeted: 0.0, spent: 0.0);
    totals[code] = (
      budgeted: existing.budgeted + progress.budget.limitAmount,
      spent: existing.spent + progress.spentAmount,
    );
  }
  return totals;
}
