import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/categories/presentation/providers/category_providers.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_motion.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../providers/budget_alert_providers.dart';
import '../providers/fcm_message_providers.dart';
import '../providers/fcm_token_registration_providers.dart';
import '../providers/goal_reminder_providers.dart';
import '../providers/presence_providers.dart';
import '../utils/platform_capabilities.dart';
import '../widgets/sync_status_banner.dart';
import 'app_routes.dart';

/// The authenticated application's responsive navigation shell. Mobile keeps
/// the familiar bottom navigation, while tablet and desktop use a persistent
/// application sidebar without changing a branch's data or navigation state.
class HomeShellScreen extends ConsumerWidget {
  const HomeShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const double _tabletBreakpoint = 760;
  static const double _expandedSidebarBreakpoint = 1180;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Seeds the curated starter categories right at login â€” not only once
    // the user happens to open the Categories tab â€” so they (and later,
    // Transactions) always have categories to pick from immediately.
    ref.watch(ensureDefaultCategoriesProvider);
    final l10n = AppLocalizations.of(context)!;
    // Finance data and Firestore sync work on every target. This only starts
    // the Android-native local-alert/FCM bridge where its plugins exist.
    if (AppPlatformCapabilities.supportsCurrentNotificationBridge) {
      watchBudgetAndBalanceAlerts(ref, l10n);
      watchGoalReminders(ref, l10n);
      watchFcmTokenRegistration(ref);
      watchPresenceHeartbeat(ref);
      watchPushNotifications(ref, l10n);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final usesSidebar = constraints.maxWidth >= _tabletBreakpoint;
        final expandedSidebar =
            constraints.maxWidth >= _expandedSidebarBreakpoint;
        final content = _ShellContent(navigationShell: navigationShell);

        return Scaffold(
          body: usesSidebar
              ? Row(
                  children: [
                    _ApplicationSidebar(
                      navigationShell: navigationShell,
                      expanded: expandedSidebar,
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: usesSidebar
              ? null
              : _MobileNavigationBar(
                  navigationShell: navigationShell,
                  l10n: l10n,
                ),
        );
      },
    );
  }
}

/// Keeps the routed branches alive while providing the same subtle branch
/// transition in both compact and wide shells.
class _ShellContent extends StatelessWidget {
  const _ShellContent({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // This sits above every branch's own AppBar and reserves the status
        // bar inset once, rather than asking every feature screen to know
        // whether it lives inside the desktop shell.
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
    );
  }
}

class _MobileNavigationBar extends StatelessWidget {
  const _MobileNavigationBar({
    required this.navigationShell,
    required this.l10n,
  });

  final StatefulNavigationShell navigationShell;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      // With 6 destinations, showing every label at once gets cramped on
      // narrow phones â€” only the active tab's label is shown, matching
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
    );
  }
}

class _ApplicationSidebar extends ConsumerWidget {
  const _ApplicationSidebar({
    required this.navigationShell,
    required this.expanded,
  });

  final StatefulNavigationShell navigationShell;
  final bool expanded;

  void _goToBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateChangesProvider).value;
    final displayName = user?.displayName?.trim();
    final profileLabel = (displayName?.isNotEmpty ?? false)
        ? displayName!
        : user?.email ?? l10n.profileTitle;
    final initial = profileLabel.isNotEmpty
        ? profileLabel.substring(0, 1).toUpperCase()
        : 'C';

    return SizedBox(
      width: expanded ? 244 : 76,
      child: ColoredBox(
        color: colorScheme.surfaceContainerHigh,
        child: SafeArea(
          right: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  expanded ? AppSpacing.md : AppSpacing.sm,
                  AppSpacing.sm,
                  expanded ? AppSpacing.md : AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: _SidebarBrand(expanded: expanded),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  children: [
                    _SidebarDestination(
                      expanded: expanded,
                      label: l10n.dashboardTitle,
                      icon: Icons.dashboard_outlined,
                      selected: navigationShell.currentIndex == 0,
                      onTap: () => _goToBranch(0),
                    ),
                    _SidebarDestination(
                      expanded: expanded,
                      label: l10n.transactionsTabLabel,
                      icon: Icons.receipt_long_outlined,
                      selected: navigationShell.currentIndex == 2,
                      onTap: () => _goToBranch(2),
                    ),
                    _SidebarDestination(
                      expanded: expanded,
                      label: l10n.accountsTitle,
                      icon: Icons.account_balance_wallet_outlined,
                      selected: navigationShell.currentIndex == 1,
                      onTap: () => _goToBranch(1),
                    ),
                    _SidebarDestination(
                      expanded: expanded,
                      label: l10n.budgetTitle,
                      icon: Icons.pie_chart_outline,
                      selected: navigationShell.currentIndex == 4,
                      onTap: () => _goToBranch(4),
                    ),
                    _SidebarDestination(
                      expanded: expanded,
                      label: l10n.categoriesTitle,
                      icon: Icons.category_outlined,
                      selected: navigationShell.currentIndex == 3,
                      onTap: () => _goToBranch(3),
                    ),
                    const _SidebarSectionDivider(),
                    _SidebarDestination(
                      expanded: expanded,
                      label: l10n.reportsTitle,
                      icon: Icons.bar_chart_rounded,
                      onTap: () => context.push(AppRoutes.reports),
                    ),
                    _SidebarDestination(
                      expanded: expanded,
                      label: l10n.savingsGoalsTitle,
                      icon: Icons.savings_outlined,
                      onTap: () => context.push(AppRoutes.savingsGoals),
                    ),
                    const _SidebarSectionDivider(),
                    _SidebarDestination(
                      expanded: expanded,
                      label: 'Recurring transactions',
                      icon: Icons.repeat_rounded,
                      enabled: false,
                      trailing: expanded ? const _ComingSoonPill() : null,
                    ),
                    _SidebarDestination(
                      expanded: expanded,
                      label: 'Bills & reminders',
                      icon: Icons.notifications_none_rounded,
                      enabled: false,
                      trailing: expanded ? const _ComingSoonPill() : null,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              _SidebarDestination(
                expanded: expanded,
                label: l10n.settingsTitle,
                icon: Icons.settings_outlined,
                onTap: () => context.push(AppRoutes.settings),
              ),
              _SidebarProfile(
                expanded: expanded,
                initial: initial,
                label: profileLabel,
                onTap: () => _goToBranch(5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mark = SizedBox(
      width: 36,
      height: 36,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Image.asset('assets/logo/cashly_mark.png', fit: BoxFit.cover),
      ),
    );

    if (!expanded) {
      return Tooltip(
        message: 'Cashly Lao',
        child: Center(child: mark),
      );
    }

    return Row(
      children: [
        mark,
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Cashly Lao',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({
    required this.expanded,
    required this.label,
    required this.icon,
    this.selected = false,
    this.enabled = true,
    this.onTap,
    this.trailing,
  });

  final bool expanded;
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = selected
        ? colorScheme.primary
        : enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.46);
    final content = Container(
      height: 46,
      margin: EdgeInsets.symmetric(
        horizontal: expanded ? AppSpacing.sm : AppSpacing.xs,
        vertical: 2,
      ),
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: expanded
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Icon(icon, size: 21, color: foreground),
          if (expanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            ?trailing,
          ],
        ],
      ),
    );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: content,
      ),
    );
    return expanded ? button : Tooltip(message: label, child: button);
  }
}

class _SidebarSectionDivider extends StatelessWidget {
  const _SidebarSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _ComingSoonPill extends StatelessWidget {
  const _ComingSoonPill();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        'Soon',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SidebarProfile extends StatelessWidget {
  const _SidebarProfile({
    required this.expanded,
    required this.initial,
    required this.label,
    required this.onTap,
  });

  final bool expanded;
  final String initial;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      child: Text(
        initial,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    final content = Container(
      height: 64,
      margin: EdgeInsets.fromLTRB(
        expanded ? AppSpacing.sm : AppSpacing.xs,
        AppSpacing.sm,
        expanded ? AppSpacing.sm : AppSpacing.xs,
        AppSpacing.sm,
      ),
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
      child: Row(
        mainAxisAlignment: expanded
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          avatar,
          if (expanded) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.more_horiz_rounded, color: colorScheme.onSurfaceVariant),
          ],
        ],
      ),
    );
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: content,
      ),
    );
    return expanded ? button : Tooltip(message: label, child: button);
  }
}
