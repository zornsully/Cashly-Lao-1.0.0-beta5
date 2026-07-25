import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/app_snackbar.dart';
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
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final month = ref.watch(selectedBudgetMonthProvider);
    final categoriesAsync = ref.watch(
      categoriesProvider((type: CategoryType.expense, includeArchived: false)),
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
                icon: Icons.category_outlined,
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

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xxl,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
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
                  },
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.color.color.withValues(alpha: 0.16),
          child: Icon(category.icon.icon, color: category.color.color),
        ),
        title: Text(category.name),
        subtitle: Text(l10n.noBudgetSetLabel),
        trailing: TextButton(
          onPressed: () => context.push(
            AppRoutes.budgetNew,
            extra: (category: category, month: month),
          ),
          child: Text(l10n.setBudgetButton),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        tileColor: theme.colorScheme.surfaceContainerHigh,
      ),
    );
  }
}
