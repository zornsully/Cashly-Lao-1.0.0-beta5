import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_symbols.dart';
import 'app_routes.dart';

/// Gives authenticated routes that live outside the tab shell the same fixed
/// desktop navigation as Dashboard, Accounts, Transactions, Budget and
/// Categories. Compact screens keep the route's existing mobile scaffold.
class DesktopPageFrame extends StatelessWidget {
  const DesktopPageFrame({
    required this.activeRoute,
    required this.child,
    super.key,
  });

  final String activeRoute;
  final Widget child;

  static const _desktopBreakpoint = 1200.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _desktopBreakpoint) return child;
        return Scaffold(
          body: Row(
            children: [
              _DesktopRouteSidebar(activeRoute: activeRoute),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopRouteSidebar extends StatelessWidget {
  const _DesktopRouteSidebar({required this.activeRoute});

  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 240,
      child: Material(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : scheme.surfaceContainerHigh,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/logo/cashly_mark.png',
                        width: 34,
                        height: 34,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Cashly Lao',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    _RouteDestination(
                      route: AppRoutes.dashboard,
                      label: 'Dashboard',
                      icon: AppSymbols.dashboard,
                      activeRoute: activeRoute,
                    ),
                    _RouteDestination(
                      route: AppRoutes.transactions,
                      label: 'Transactions',
                      icon: AppSymbols.receiptLong,
                      activeRoute: activeRoute,
                    ),
                    _RouteDestination(
                      route: AppRoutes.accounts,
                      label: 'Accounts',
                      icon: AppSymbols.accountBalanceWallet,
                      activeRoute: activeRoute,
                    ),
                    _RouteDestination(
                      route: AppRoutes.budget,
                      label: 'Budget',
                      icon: AppSymbols.pieChart,
                      activeRoute: activeRoute,
                    ),
                    _RouteDestination(
                      route: AppRoutes.categories,
                      label: 'Categories',
                      icon: AppSymbols.category,
                      activeRoute: activeRoute,
                    ),
                    const SizedBox(height: 12),
                    _RouteDestination(
                      route: AppRoutes.reports,
                      label: 'Reports',
                      icon: AppSymbols.barChart,
                      activeRoute: activeRoute,
                    ),
                    _RouteDestination(
                      route: AppRoutes.savingsGoals,
                      label: 'Savings goals',
                      icon: AppSymbols.savings,
                      activeRoute: activeRoute,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(10),
                child: _RouteDestination(
                  route: AppRoutes.settings,
                  label: 'Settings',
                  icon: AppSymbols.settings,
                  activeRoute: activeRoute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteDestination extends StatelessWidget {
  const _RouteDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeRoute,
  });

  final String route;
  final String label;
  final IconData icon;
  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    final selected = route == activeRoute;
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(route),
          child: SizedBox(
            height: 46,
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 24,
                  color: selected ? scheme.primary : Colors.transparent,
                ),
                const SizedBox(width: 13),
                Icon(icon, color: foreground, size: 21),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
