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
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../accounts/domain/entities/account_entity.dart';
import '../../../accounts/presentation/widgets/account_card.dart';
import '../../../budget/domain/entities/budget_progress.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../budget/presentation/widgets/budget_progress_tile.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../financial_insights/domain/entities/financial_insight.dart';
import '../../../financial_insights/presentation/providers/financial_insight_providers.dart';
import '../../../financial_insights/presentation/widgets/financial_insight_card.dart';
import '../../../reports/domain/entities/monthly_trend_point.dart';
import '../../../reports/presentation/providers/report_providers.dart';
import '../../../reports/presentation/widgets/category_pie_chart.dart';
import '../../../reports/presentation/widgets/income_expense_trend_chart.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../../transactions/presentation/providers/transaction_controller.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../../domain/entities/category_spending.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/category_spending_bar.dart';
import '../widgets/stat_card.dart';

/// Dashboard data is deliberately shared with the compact layout below. Only
/// the arrangement changes at wider breakpoints; all totals, transactions,
/// budgets, account cards, and smart-money insight data remain exactly the
/// same Riverpod-backed values used by the mobile dashboard.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const double _wideLayoutBreakpoint = 760;

  String? _selectedCurrencyCode;

  Future<void> _confirmDeleteTransaction(
    BuildContext context,
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
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final financialInsightsAsync = ref.watch(financialInsightsProvider);
    final trendAsync = ref.watch(monthlyTrendProvider);
    final month = DateTime.now();
    final budgetProgress =
        ref
            .watch(
              budgetProgressForMonthProvider(DateTime(month.year, month.month)),
            )
            .value ??
        const <BudgetProgress>[];
    final l10n = AppLocalizations.of(context)!;
    final usesWideLayout =
        MediaQuery.sizeOf(context).width >= _wideLayoutBreakpoint;

    return Scaffold(
      // The desktop dashboard owns its more detailed inline header. Phones
      // retain the existing AppBar, including the two established shortcuts.
      appBar: usesWideLayout
          ? null
          : AppBar(
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
      body: summaryAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => ErrorView(message: '$error'),
        data: (summary) {
          if (!summary.hasAnyAccounts) {
            return ResponsiveCenter(
              child: EmptyState(
                icon: Icons.dashboard_customize_outlined,
                title: l10n.welcomeToCashly,
                message: l10n.addFirstAccountMessage,
                action: FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.accounts),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addAccountButton),
                ),
              ),
            );
          }

          final currencies = summary.totalBalanceByCurrency.keys.toList()
            ..sort();
          final selectedCurrencyCode =
              currencies.contains(_selectedCurrencyCode)
              ? _selectedCurrencyCode!
              : currencies.first;
          final categoriesById = {
            for (final category in summary.categories) category.id: category,
          };
          final accountsById = {
            for (final account in summary.accounts) account.id: account,
          };

          return usesWideLayout
              ? _WideDashboard(
                  month: month,
                  currencies: currencies,
                  selectedCurrencyCode: selectedCurrencyCode,
                  onSelectedCurrencyChanged: (currencyCode) {
                    setState(() => _selectedCurrencyCode = currencyCode);
                  },
                  summary: summary,
                  financialInsights:
                      financialInsightsAsync.value ??
                      const <FinancialInsight>[],
                  trendPoints: trendAsync.value ?? const <MonthlyTrendPoint>[],
                  budgetProgress: budgetProgress,
                  categoriesById: categoriesById,
                  accountsById: accountsById,
                  onDeleteTransaction: (transaction) =>
                      _confirmDeleteTransaction(context, transaction),
                )
              : ResponsiveCenter(
                  child: _CompactDashboard(
                    month: month,
                    currencies: currencies,
                    summary: summary,
                    financialInsights:
                        financialInsightsAsync.value ??
                        const <FinancialInsight>[],
                    budgetProgress: budgetProgress,
                    categoriesById: categoriesById,
                    accountsById: accountsById,
                    onDeleteTransaction: (transaction) =>
                        _confirmDeleteTransaction(context, transaction),
                  ),
                );
        },
      ),
    );
  }
}

class _WideDashboard extends StatelessWidget {
  const _WideDashboard({
    required this.month,
    required this.currencies,
    required this.selectedCurrencyCode,
    required this.onSelectedCurrencyChanged,
    required this.summary,
    required this.financialInsights,
    required this.trendPoints,
    required this.budgetProgress,
    required this.categoriesById,
    required this.accountsById,
    required this.onDeleteTransaction,
  });

  final DateTime month;
  final List<String> currencies;
  final String selectedCurrencyCode;
  final ValueChanged<String> onSelectedCurrencyChanged;
  final DashboardSummary summary;
  final List<FinancialInsight> financialInsights;
  final List<MonthlyTrendPoint> trendPoints;
  final List<BudgetProgress> budgetProgress;
  final Map<String, CategoryEntity> categoriesById;
  final Map<String, AccountEntity> accountsById;
  final ValueChanged<TransactionEntity> onDeleteTransaction;

  @override
  Widget build(BuildContext context) {
    final selectedCurrency = SupportedCurrencies.byCode(selectedCurrencyCode);
    final balance = summary.totalBalanceByCurrency[selectedCurrencyCode] ?? 0;
    final income = summary.totalIncomeByCurrency[selectedCurrencyCode] ?? 0;
    final expense = summary.totalExpenseByCurrency[selectedCurrencyCode] ?? 0;
    final net = income - expense;
    final otherCurrencies = currencies
        .where((currencyCode) => currencyCode != selectedCurrencyCode)
        .toList(growable: false);
    final otherCurrencyCode = otherCurrencies.isEmpty
        ? null
        : otherCurrencies.first;
    final otherBalance = otherCurrencyCode == null
        ? null
        : CurrencyFormatter.format(
            summary.totalBalanceByCurrency[otherCurrencyCode] ?? 0,
            SupportedCurrencies.byCode(otherCurrencyCode),
          );
    final selectedInsights = financialInsights
        .where((insight) => insight.currencyCode == selectedCurrencyCode)
        .toList(growable: false);
    final semanticColors = AppSemanticColors.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          children: [
            _DashboardDesktopHeader(
              month: month,
              currencies: currencies,
              selectedCurrencyCode: selectedCurrencyCode,
              onSelectedCurrencyChanged: onSelectedCurrencyChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            _QuickActions(
              onAddIncome: () => context.push(
                AppRoutes.transactionNew,
                extra: TransactionType.income,
              ),
              onAddExpense: () => context.push(
                AppRoutes.transactionNew,
                extra: TransactionType.expense,
              ),
              onTransferMoney: () => context.push(
                AppRoutes.transactionNew,
                extra: TransactionType.transfer,
              ),
              onCreateBudget: () => context.push(AppRoutes.budgetNew),
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                // The sidebar intentionally consumes desktop width, so this
                // uses the actual content constraint rather than the whole
                // window. That preserves two-card tablet rows and gives
                // desktop users four cards as soon as their content area can
                // comfortably support them.
                final columns = constraints.maxWidth >= 960
                    ? 4
                    : constraints.maxWidth >= 500
                    ? 2
                    : 1;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: columns == 4 ? 1.55 : 1.78,
                  children: [
                    _DashboardMetricCard(
                      label: 'Total balance',
                      amount: balance,
                      currency: selectedCurrency,
                      icon: AppSymbols.accountBalanceWallet,
                      color: Theme.of(context).colorScheme.primary,
                      caption: 'Live across active accounts',
                      secondaryValue: otherBalance == null
                          ? null
                          : 'Also $otherCurrencyCode $otherBalance',
                    ),
                    _DashboardMetricCard(
                      label: 'Monthly income',
                      amount: income,
                      currency: selectedCurrency,
                      icon: Icons.arrow_downward_rounded,
                      color: semanticColors.positiveForeground,
                      caption: 'This calendar month',
                    ),
                    _DashboardMetricCard(
                      label: 'Monthly expenses',
                      amount: expense,
                      currency: selectedCurrency,
                      icon: Icons.arrow_upward_rounded,
                      color: semanticColors.negativeForeground,
                      caption: 'This calendar month',
                    ),
                    _DashboardMetricCard(
                      label: 'Net cash flow',
                      amount: net,
                      currency: selectedCurrency,
                      icon: net < 0
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      color: net < 0
                          ? semanticColors.negativeForeground
                          : semanticColors.positiveForeground,
                      caption: 'Income minus expenses',
                    ),
                  ],
                );
              },
            ),
            if (selectedInsights.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              for (final insight in selectedInsights) ...[
                FinancialInsightCard(insight: insight),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final showsTwoColumns = constraints.maxWidth >= 980;
                final trend = _TrendPanel(
                  points: trendPoints,
                  currency: selectedCurrency,
                );
                final recentTransactions = _RecentTransactionsPanel(
                  summary: summary,
                  categoriesById: categoriesById,
                  accountsById: accountsById,
                  onDeleteTransaction: onDeleteTransaction,
                );
                final categorySpending = _CategorySpendingPanel(
                  spending:
                      summary.spendingByCategory[selectedCurrencyCode] ??
                      const <CategorySpending>[],
                  currency: selectedCurrency,
                );
                final budgets = _BudgetsPanel(budgetProgress: budgetProgress);

                if (!showsTwoColumns) {
                  return Column(
                    children: [
                      trend,
                      const SizedBox(height: AppSpacing.md),
                      categorySpending,
                      const SizedBox(height: AppSpacing.md),
                      recentTransactions,
                      const SizedBox(height: AppSpacing.md),
                      budgets,
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: trend),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(flex: 5, child: categorySpending),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: recentTransactions),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(flex: 5, child: budgets),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _AccountsPanel(accounts: summary.accounts),
          ],
        ),
      ),
    );
  }
}

class _DashboardDesktopHeader extends StatelessWidget {
  const _DashboardDesktopHeader({
    required this.month,
    required this.currencies,
    required this.selectedCurrencyCode,
    required this.onSelectedCurrencyChanged,
  });

  final DateTime month;
  final List<String> currencies;
  final String selectedCurrencyCode;
  final ValueChanged<String> onSelectedCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: AppSpacing.md,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboardTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'A clear view of your money this month.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _HeaderPill(
              icon: Icons.calendar_month_outlined,
              label: DateFormat.yMMMM().format(month),
            ),
            PopupMenuButton<String>(
              tooltip: 'Choose currency',
              onSelected: onSelectedCurrencyChanged,
              itemBuilder: (context) => [
                for (final currencyCode in currencies)
                  CheckedPopupMenuItem(
                    value: currencyCode,
                    checked: currencyCode == selectedCurrencyCode,
                    child: Text(currencyCode),
                  ),
              ],
              child: _HeaderPill(
                icon: Icons.currency_exchange_rounded,
                label: selectedCurrencyCode,
                showsDisclosure: currencies.length > 1,
              ),
            ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => _showNotifications(context),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            PopupMenuButton<_ProfileMenuAction>(
              tooltip: l10n.profileTitle,
              onSelected: (action) {
                switch (action) {
                  case _ProfileMenuAction.profile:
                    context.go(AppRoutes.profile);
                  case _ProfileMenuAction.settings:
                    context.push(AppRoutes.settings);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _ProfileMenuAction.profile,
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.profileTitle),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _ProfileMenuAction.settings,
                  child: Row(
                    children: [
                      const Icon(Icons.settings_outlined),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.settingsTitle),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: const Icon(Icons.person_rounded, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Notifications',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'You are all caught up.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ProfileMenuAction { profile, settings }

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
    this.showsDisclosure = false,
  });

  final IconData icon;
  final String label;
  final bool showsDisclosure;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (showsDisclosure) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onTransferMoney,
    required this.onCreateBudget,
  });

  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onTransferMoney;
  final VoidCallback onCreateBudget;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        FilledButton.icon(
          onPressed: onAddIncome,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add income'),
        ),
        OutlinedButton.icon(
          onPressed: onAddExpense,
          icon: const Icon(Icons.remove_rounded, size: 18),
          label: const Text('Add expense'),
        ),
        OutlinedButton.icon(
          onPressed: onTransferMoney,
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: const Text('Transfer money'),
        ),
        OutlinedButton.icon(
          onPressed: onCreateBudget,
          icon: const Icon(Icons.pie_chart_outline_rounded, size: 18),
          label: const Text('Create budget'),
        ),
      ],
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.color,
    required this.caption,
    this.secondaryValue,
  });

  final String label;
  final double amount;
  final AppCurrency currency;
  final IconData icon;
  final Color color;
  final String caption;
  final String? secondaryValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              CurrencyFormatter.format(amount, currency),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              secondaryValue ?? caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.child,
    this.onSeeAll,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (onSeeAll != null)
                  TextButton(onPressed: onSeeAll, child: Text(l10n.seeAll)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsPanel extends StatelessWidget {
  const _RecentTransactionsPanel({
    required this.summary,
    required this.categoriesById,
    required this.accountsById,
    required this.onDeleteTransaction,
  });

  final DashboardSummary summary;
  final Map<String, CategoryEntity> categoriesById;
  final Map<String, AccountEntity> accountsById;
  final ValueChanged<TransactionEntity> onDeleteTransaction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _DashboardPanel(
      title: l10n.recentTransactionsTitle,
      onSeeAll: () => context.go(AppRoutes.transactions),
      child: !summary.hasAnyTransactionsThisMonth
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                l10n.noTransactionsThisMonth,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
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
                    onDelete: () => onDeleteTransaction(transaction),
                  ),
              ],
            ),
    );
  }
}

class _TrendPanel extends StatelessWidget {
  const _TrendPanel({required this.points, required this.currency});

  final List<MonthlyTrendPoint> points;
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Income & expenses',
      onSeeAll: () => context.push(AppRoutes.reports),
      child: points.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'Not enough activity to show a trend yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last 6 months',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                IncomeExpenseTrendChart(points: points, currency: currency),
              ],
            ),
    );
  }
}

class _CategorySpendingPanel extends StatelessWidget {
  const _CategorySpendingPanel({
    required this.spending,
    required this.currency,
  });

  final List<CategorySpending> spending;
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _DashboardPanel(
      title: l10n.spendingByCategoryTitle,
      child: spending.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No recorded expense categories this month.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryPieChart(spending: spending, currency: currency),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Category breakdown',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final item in spending)
                  CategorySpendingBar(spending: item, currency: currency),
              ],
            ),
    );
  }
}

class _BudgetsPanel extends StatelessWidget {
  const _BudgetsPanel({required this.budgetProgress});

  final List<BudgetProgress> budgetProgress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _DashboardPanel(
      title: l10n.budgetsTitle,
      onSeeAll: () => context.go(AppRoutes.budget),
      child: budgetProgress.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No active budgets this month.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
                for (final progress in budgetProgress)
                  BudgetProgressTile(
                    progress: progress,
                    onTap: () => context.push(
                      AppRoutes.budgetEditPath(progress.budget.id),
                      extra: progress.budget,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _AccountsPanel extends StatelessWidget {
  const _AccountsPanel({required this.accounts});

  final List<AccountEntity> accounts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _DashboardPanel(
      title: l10n.accountBalancesTitle,
      onSeeAll: () => context.go(AppRoutes.accounts),
      child: Column(
        children: [
          for (final account in accounts)
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
      ),
    );
  }
}

class _CompactDashboard extends StatelessWidget {
  const _CompactDashboard({
    required this.month,
    required this.currencies,
    required this.summary,
    required this.financialInsights,
    required this.budgetProgress,
    required this.categoriesById,
    required this.accountsById,
    required this.onDeleteTransaction,
  });

  final DateTime month;
  final List<String> currencies;
  final DashboardSummary summary;
  final List<FinancialInsight> financialInsights;
  final List<BudgetProgress> budgetProgress;
  final Map<String, CategoryEntity> categoriesById;
  final Map<String, AccountEntity> accountsById;
  final ValueChanged<TransactionEntity> onDeleteTransaction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          _CurrencyOverview(currencyCode: currencyCode, summary: summary),
          const SizedBox(height: AppSpacing.lg),
        ],
        for (final insight in financialInsights) ...[
          FinancialInsightCard(insight: insight),
          const SizedBox(height: AppSpacing.lg),
        ],
        _SectionHeader(
          title: l10n.recentTransactionsTitle,
          onSeeAll: () => context.go(AppRoutes.transactions),
        ),
        if (!summary.hasAnyTransactionsThisMonth)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
              onDelete: () => onDeleteTransaction(transaction),
            ),
        const SizedBox(height: AppSpacing.lg),
        if (summary.spendingByCategory.values.any(
          (spending) => spending.isNotEmpty,
        )) ...[
          _SectionHeader(title: l10n.spendingByCategoryTitle),
          for (final currencyCode in currencies)
            if (summary.spendingByCategory[currencyCode]?.isNotEmpty ?? false)
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
                          currency: SupportedCurrencies.byCode(currencyCode),
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
