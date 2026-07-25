import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/categories/presentation/providers/category_providers.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_motion.dart';
import '../providers/budget_alert_providers.dart';
import '../providers/goal_reminder_providers.dart';
import '../widgets/sync_status_banner.dart';

/// The authenticated app's persistent bottom-navigation chrome. Each branch
/// keeps its own navigation stack and state (via [StatefulShellRoute]), so
/// switching tabs doesn't lose scroll position or in-progress state.
class HomeShellScreen extends ConsumerWidget {
  const HomeShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Seeds the curated starter categories right at login — not only once
    // the user happens to open the Categories tab — so they (and later,
    // Transactions) always have categories to pick from immediately.
    ref.watch(ensureDefaultCategoriesProvider);
    final l10n = AppLocalizations.of(context)!;
    watchBudgetAndBalanceAlerts(ref, l10n);
    watchGoalReminders(ref, l10n);

    return Scaffold(
      // StatefulShellRoute swaps branches instantly (an IndexedStack under
      // the hood) — this cross-fades the swap instead, while still relying
      // on the shell to preserve each branch's own navigator/scroll state.
      body: Column(
        children: [
          // Only this needs SafeArea: it's the first thing in the outer
          // shell's body, above every tab's own AppBar, so nothing else
          // here accounts for the status bar inset the way an AppBar
          // normally would.
          const SafeArea(bottom: false, child: SyncStatusBanner()),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.normal,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              child: KeyedSubtree(
                key: ValueKey(navigationShell.currentIndex),
                child: navigationShell,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        // With 6 destinations, showing every label at once gets cramped on
        // narrow phones — only the active tab's label is shown, matching
        // Material 3's guidance for higher destination counts.
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.dashboardTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.accountsTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.transactionsTabLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.category_outlined),
            selectedIcon: const Icon(Icons.category),
            label: l10n.categoriesTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: l10n.budgetTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profileTitle,
          ),
        ],
      ),
    );
  }
}
