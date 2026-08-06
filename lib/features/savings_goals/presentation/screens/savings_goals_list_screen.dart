import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_skeleton_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/savings_goal_providers.dart';
import '../widgets/goal_card.dart';

/// Goal management (archive/unarchive/delete) lives on the Detail screen's
/// AppBar menu, not here — this list is tap-to-navigate only, same
/// separation of concerns as Budget's list vs its edit form.
class SavingsGoalsListScreen extends ConsumerWidget {
  const SavingsGoalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1200;
    final showArchived = ref.watch(showArchivedGoalsProvider);
    final progressAsync = ref.watch(savingsGoalProgressProvider(showArchived));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savingsGoalsTitle),
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
                ref.read(showArchivedGoalsProvider.notifier).toggle(),
          ),
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.savingsGoalNew),
                icon: const Icon(AppSymbols.addRounded),
                label: Text(l10n.addGoalButton),
              ),
            ),
        ],
      ),
      body: ResponsiveCenter(
        child: progressAsync.when(
          loading: () => const AppSkeletonList(),
          error: (error, _) => ErrorView(message: '$error'),
          data: (progressList) {
            if (progressList.isEmpty) {
              // With showArchived == true the query returns archived *and*
              // active goals, so an empty result here always means there
              // are no goals at all yet — never "no archived ones" (same
              // reasoning as AccountsListScreen's empty check).
              return EmptyState(
                icon: AppSymbols.savings,
                title: l10n.noSavingsGoalsYetTitle,
                message: l10n.noSavingsGoalsYetMessage,
                action: FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.savingsGoalNew),
                  icon: const Icon(AppSymbols.addRounded),
                  label: Text(l10n.addGoalButton),
                ),
              );
            }

            Widget buildCard(int index) {
              final progress = progressList[index];
              return GoalCard(
                progress: progress,
                onTap: () => context.push(
                  AppRoutes.savingsGoalDetailPath(progress.goal.id),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                // Content width (not window width) drives the column count,
                // same pattern already used by Accounts/Budgets/Dashboard —
                // one implementation serves phones, tablets, and desktop.
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
                    itemCount: progressList.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => buildCard(index),
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
                    // 2.2 (not a rounder-looking guess) was chosen after an
                    // actual widget-test run caught a real 1.2px overflow at
                    // a wider ratio — see the test file and TODO.md's own
                    // note on this.
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: progressList.length,
                  itemBuilder: (context, index) => buildCard(index),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              // See the same fix's comment in accounts_list_screen.dart -- every
              // shell tab's FAB otherwise shares Flutter's implicit default hero
              // tag, since the shell keeps all branches mounted simultaneously.
              // The key gives integration tests an unambiguous target too.
              key: const ValueKey('savings-goals-fab'),
              heroTag: 'savings-goals-fab',
              onPressed: () => context.push(AppRoutes.savingsGoalNew),
              child: const Icon(AppSymbols.addRounded),
            ),
    );
  }
}
