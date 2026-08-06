import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/analytics_logger.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../accounts/domain/entities/account_entity.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../budget/presentation/widgets/budget_progress_tile.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../domain/entities/converted_monthly_totals.dart';
import '../../domain/entities/expense_watch_item.dart';
import '../../domain/entities/monthly_report.dart';
import '../../domain/entities/report_filter.dart';
import '../../domain/entities/report_insights.dart';
import '../../domain/entities/report_period.dart';
import '../providers/report_providers.dart';
import '../widgets/account_pie_chart.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/income_expense_trend_chart.dart';

String _weekRangeLabel(DateTime anchor) {
  final start = anchor.subtract(Duration(days: anchor.weekday - 1));
  final end = start.add(const Duration(days: 6));
  return '${DateFormat.MMMd().format(start)} – ${DateFormat.yMMMd().format(end)}';
}

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _exportCsv(
    BuildContext context,
    WidgetRef ref,
    MonthlyReport report,
    Map<String, AccountEntity> accountsById,
    Map<String, CategoryEntity> categoriesById,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final monthLabel =
        '${report.month.year}-${report.month.month.toString().padLeft(2, '0')}';
    final csv = ref.read(exportTransactionsToCsvUseCaseProvider)(
      transactions: report.transactions,
      accountsById: accountsById,
      categoriesById: categoriesById,
    );
    final fileName = 'Cashly-Lao-Transactions-$monthLabel.csv';

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(csv),
              name: fileName,
              mimeType: 'text/csv',
            ),
          ],
          // XFile.fromData's own `name` isn't reliably used as the actual
          // shared filename (confirmed on-device: without this, Android's
          // share sheet showed a random UUID.csv instead) — this is what
          // share_plus's own docs call out as the fix for exactly that.
          fileNameOverrides: [fileName],
          subject: l10n.exportReportSubject(monthLabel),
        ),
      );
      logAnalyticsEvent(() => ref.read(analyticsProvider), 'csv_exported');
    } catch (_) {
      if (!context.mounted) return;
      AppSnackbar.showError(context, l10n.exportReportFailedMessage);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final month = ref.watch(selectedReportMonthProvider);
    final reportAsync = ref.watch(monthlyReportProvider);
    final trendAsync = ref.watch(monthlyTrendProvider);
    final convertedTotals = ref.watch(convertedMonthlyTotalsProvider);
    final insights = ref.watch(reportInsightsProvider);
    final expenseWatchItems = ref.watch(expenseWatchProvider);
    final filter = ref.watch(reportFilterProvider);
    final report = reportAsync.value;
    final accountsById = <String, AccountEntity>{
      for (final account in ref.watch(accountsProvider(true)).value ?? [])
        account.id: account,
    };
    final categoriesById = <String, CategoryEntity>{
      for (final category
          in ref
                  .watch(
                    categoriesProvider((type: null, includeArchived: true)),
                  )
                  .value ??
              [])
        category.id: category,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
        actions: [
          Badge(
            isLabelVisible: filter.isActive,
            smallSize: 8,
            child: IconButton(
              icon: const Icon(AppSymbols.tune),
              tooltip: l10n.reportFilterTooltip,
              onPressed: () => AppBottomSheet.show(
                context,
                isScrollControlled: true,
                builder: (context) => const _ReportFilterSheet(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(AppSymbols.iosShare),
            tooltip: l10n.exportReportTooltip,
            onPressed: report != null && report.hasAnyActivity
                ? () => _exportCsv(
                    context,
                    ref,
                    report,
                    accountsById,
                    categoriesById,
                  )
                : null,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: _ReportPeriodHeader(
            anchor: month,
            filter: filter,
            onPrevious: () {
              if (filter.hasCustomRange) {
                ref.read(reportFilterProvider.notifier).shiftCustomRange(-1);
              } else {
                ref
                    .read(selectedReportMonthProvider.notifier)
                    .move(filter.period, -1);
              }
            },
            onNext: () {
              if (filter.hasCustomRange) {
                ref.read(reportFilterProvider.notifier).shiftCustomRange(1);
              } else {
                ref
                    .read(selectedReportMonthProvider.notifier)
                    .move(filter.period, 1);
              }
            },
            onPeriodSelected: (period) {
              if (period == ReportPeriod.custom) {
                AppBottomSheet.show(
                  context,
                  isScrollControlled: true,
                  builder: (context) => const _ReportFilterSheet(),
                );
              } else {
                ref.read(reportFilterProvider.notifier).setPeriod(period);
              }
            },
          ),
        ),
      ),
      body: ResponsiveCenter(
        child: reportAsync.when(
          loading: () => const AppLoadingIndicator(),
          error: (error, _) => ErrorView(message: '$error'),
          data: (report) {
            if (!report.hasAnyActivity) {
              return EmptyState(
                icon: AppSymbols.insertChartOutlined,
                title: l10n.nothingToReportYetTitle,
                message: l10n.nothingToReportYetMessage,
              );
            }

            final currencies = report.currencies.toList()..sort();

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                if (currencies.length > 1)
                  AnimatedSwitcher(
                    duration: AppMotion.normal,
                    switchInCurve: AppMotion.enter,
                    switchOutCurve: AppMotion.exit,
                    child: convertedTotals == null
                        ? const SizedBox.shrink(key: ValueKey('empty'))
                        : Padding(
                            key: const ValueKey('data'),
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.lg,
                            ),
                            child: _ConvertedTotalsCard(
                              totals: convertedTotals,
                            ),
                          ),
                  ),
                for (final currencyCode in currencies) ...[
                  _MonthlySummaryCard(
                    currencyCode: currencyCode,
                    report: report,
                    accountsById: accountsById,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (insights != null)
                    _InsightsRow(
                      currencyCode: currencyCode,
                      insights: insights,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _SectionHeader(title: l10n.incomeExpenseTrendSectionTitle),
                trendAsync.when(
                  loading: () => const AppLoadingIndicator(),
                  error: (error, _) => ErrorView(message: '$error'),
                  data: (points) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: IncomeExpenseTrendChart(
                        points: points,
                        currency: SupportedCurrencies.byCode(
                          currencies.isNotEmpty
                              ? currencies.first
                              : SupportedCurrencies.fallback.code,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (report.spendingByCategory.values.any(
                  (s) => s.isNotEmpty,
                )) ...[
                  _SectionHeader(title: l10n.spendingByCategorySectionTitle),
                  for (final currencyCode in currencies)
                    if (report.spendingByCategory[currencyCode]?.isNotEmpty ??
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
                              CategoryPieChart(
                                spending:
                                    report.spendingByCategory[currencyCode]!,
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
                if (report.accountBreakdown.values.any(
                  (s) => s.isNotEmpty,
                )) ...[
                  _SectionHeader(title: l10n.accountBreakdownSectionTitle),
                  for (final currencyCode in currencies)
                    if (report.accountBreakdown[currencyCode]?.isNotEmpty ??
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
                              AccountPieChart(
                                spending:
                                    report.accountBreakdown[currencyCode]!,
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
                if (expenseWatchItems.isNotEmpty) ...[
                  _SectionHeader(title: l10n.expenseWatchSectionTitle),
                  for (final item in expenseWatchItems)
                    _ExpenseWatchTile(item: item, accountsById: accountsById),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (report.budgetProgress.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.budgetVsActualSectionTitle,
                    onSeeAll: () => context.go(AppRoutes.budget),
                  ),
                  for (final progress in report.budgetProgress)
                    BudgetProgressTile(
                      progress: progress,
                      onTap: () => context.push(
                        AppRoutes.budgetEditPath(progress.budget.id),
                        extra: progress.budget,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (report.transactions.isNotEmpty) ...[
                  _SectionHeader(title: l10n.transactionsTitle),
                  for (final transaction in report.transactions)
                    _ReportTransactionTile(
                      transaction: transaction,
                      account: accountsById[transaction.accountId],
                      category: categoriesById[transaction.categoryId],
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({
    required this.currencyCode,
    required this.report,
    required this.accountsById,
  });

  final String currencyCode;
  final MonthlyReport report;
  final Map<String, AccountEntity> accountsById;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currency = SupportedCurrencies.byCode(currencyCode);
    final income = report.totalIncomeByCurrency[currencyCode] ?? 0;
    final expense = report.totalExpenseByCurrency[currencyCode] ?? 0;
    final net = report.netByCurrency[currencyCode] ?? 0;
    final savings = net > 0 ? net : 0.0;
    final transactionCount = report.transactions
        .where(
          (transaction) =>
              accountsById[transaction.accountId]?.currencyCode == currencyCode,
        )
        .length;
    final semanticColors = AppSemanticColors.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currencyCode,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _SummaryFigure(
                    label: l10n.incomeLabel,
                    amount: income,
                    currency: currency,
                    color: semanticColors.positiveForeground,
                  ),
                ),
                Expanded(
                  child: _SummaryFigure(
                    label: l10n.expenseLabel,
                    amount: expense,
                    currency: currency,
                    color: semanticColors.negativeForeground,
                  ),
                ),
                Expanded(
                  child: _SummaryFigure(
                    label: l10n.netLabel,
                    amount: net,
                    currency: currency,
                    color: net < 0
                        ? semanticColors.negativeForeground
                        : semanticColors.primaryForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Savings ${CurrencyFormatter.format(savings, currency)} · '
              '$transactionCount transaction${transactionCount == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A converted-total figure spanning every currency in the report, shown
/// only alongside — never instead of — the currency-exact
/// [_MonthlySummaryCard]s below it. Clearly labeled as approximate, with
/// the rates' fetch date and the required data-source attribution, so it's
/// never mistaken for a live or precise conversion.
/// The period selector is intentionally owned by the Reports screen instead
/// of individual cards so a range change refreshes every derived section
/// from the same Riverpod data source.
class _ReportPeriodHeader extends StatelessWidget {
  const _ReportPeriodHeader({
    required this.anchor,
    required this.filter,
    required this.onPrevious,
    required this.onNext,
    required this.onPeriodSelected,
  });

  final DateTime anchor;
  final ReportFilter filter;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<ReportPeriod> onPeriodSelected;

  String get _rangeLabel {
    if (filter.hasCustomRange) {
      return '${DateFormat.MMMd().format(filter.customRangeStart!)} – '
          '${DateFormat.yMMMd().format(filter.customRangeEndExclusive!.subtract(const Duration(days: 1)))}';
    }
    return switch (filter.period) {
      ReportPeriod.today => DateFormat.yMMMd().format(anchor),
      ReportPeriod.week => _weekRangeLabel(anchor),
      ReportPeriod.month => DateFormat.yMMMM().format(anchor),
      ReportPeriod.year => DateFormat.y().format(anchor),
      ReportPeriod.custom => 'Choose a custom range',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppSymbols.chevronLeft),
            tooltip: 'Previous period',
            onPressed: onPrevious,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<ReportPeriod>(
                    value: filter.period,
                    isDense: true,
                    alignment: Alignment.center,
                    items: [
                      for (final period in ReportPeriod.values)
                        DropdownMenuItem(
                          value: period,
                          child: Text(period.label),
                        ),
                    ],
                    onChanged: (period) {
                      if (period != null) onPeriodSelected(period);
                    },
                  ),
                ),
                Text(
                  _rangeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(AppSymbols.chevronRight),
            tooltip: 'Next period',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _ConvertedTotalsCard extends StatelessWidget {
  const _ConvertedTotalsCard({required this.totals});

  final ConvertedMonthlyTotals totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currency = SupportedCurrencies.byCode(totals.currencyCode);
    final semanticColors = AppSemanticColors.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  AppSymbols.currencyExchange,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.convertedTotalsCardTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.convertedTotalsCaption(totals.currencyCode),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _SummaryFigure(
                    label: l10n.incomeLabel,
                    amount: totals.totalIncome,
                    currency: currency,
                    color: semanticColors.positiveForeground,
                  ),
                ),
                Expanded(
                  child: _SummaryFigure(
                    label: l10n.expenseLabel,
                    amount: totals.totalExpense,
                    currency: currency,
                    color: semanticColors.negativeForeground,
                  ),
                ),
                Expanded(
                  child: _SummaryFigure(
                    label: l10n.netLabel,
                    amount: totals.net,
                    currency: currency,
                    color: totals.net < 0
                        ? semanticColors.negativeForeground
                        : semanticColors.primaryForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.convertedTotalsRatesAsOf(
                DateFormat.yMMMd().format(totals.ratesAsOfUtc.toLocal()),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (totals.isPartial) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    AppSymbols.warningAmberRounded,
                    size: 14,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.convertedTotalsPartialWarning(
                        totals.excludedCurrencyCodes.join(', '),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryFigure extends StatelessWidget {
  const _SummaryFigure({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  final String label;
  final double amount;
  final AppCurrency currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.format(amount, currency),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
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
              child: Text(AppLocalizations.of(context)!.seeAllButton),
            ),
        ],
      ),
    );
  }
}

/// Savings rate, average daily spend, top category, and month-over-month
/// change for one currency — whichever of the four `ReportInsights` has
/// data for. Omits itself entirely rather than showing an empty grid when
/// none apply (e.g. a period with no income yet).
class _InsightsRow extends StatelessWidget {
  const _InsightsRow({required this.currencyCode, required this.insights});

  final String currencyCode;
  final ReportInsights insights;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semanticColors = AppSemanticColors.of(context);
    final currency = SupportedCurrencies.byCode(currencyCode);

    final savingsRate = insights.savingsRatePercentByCurrency[currencyCode];
    final averageDaily = insights.averageDailySpendByCurrency[currencyCode];
    final topCategory = insights.topCategoryByCurrency[currencyCode];
    final change = insights.expenseChangePercentByCurrency[currencyCode];

    final cards = <Widget>[
      if (savingsRate != null)
        _InsightCard(
          label: l10n.savingsRateLabel,
          value: '${savingsRate.toStringAsFixed(0)}%',
          color: savingsRate < 0
              ? semanticColors.negativeForeground
              : semanticColors.positiveForeground,
          icon: AppSymbols.savings,
        ),
      if (averageDaily != null)
        _InsightCard(
          label: l10n.averageDailySpendLabel,
          value: CurrencyFormatter.format(averageDaily, currency),
          color: theme.colorScheme.primary,
          icon: AppSymbols.calendarMonth,
        ),
      if (topCategory != null)
        _InsightCard(
          label: l10n.topSpendingCategoryLabel,
          value: topCategory.category.name,
          color: topCategory.category.color.color,
          icon: topCategory.category.icon.icon,
        ),
      if (change != null)
        _InsightCard(
          label: l10n.spendingChangeLabel,
          value: '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
          color: change > 0
              ? semanticColors.negativeForeground
              : semanticColors.positiveForeground,
          icon: change > 0 ? AppSymbols.trendingUp : AppSymbols.trendingDown,
        ),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.0,
          children: cards,
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
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

/// One flagged spending pattern from `expenseWatchProvider` — see
/// `DetectExpenseWatchUseCase` and `ExpenseWatchItem` for what each variant
/// means. [accountsById] resolves the currency for the [LargeExpenseWatchItem]/
/// [RepeatedExpenseWatchItem] variants, which are tied to real transactions;
/// [RisingCategoryWatchItem] already carries its own currency code.
class _ExpenseWatchTile extends StatelessWidget {
  const _ExpenseWatchTile({required this.item, required this.accountsById});

  final ExpenseWatchItem item;
  final Map<String, AccountEntity> accountsById;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final IconData icon;
    final Color color;
    final String message;

    switch (item) {
      case LargeExpenseWatchItem(
        :final transaction,
        :final category,
        :final categoryAverageAmount,
      ):
        final currency = SupportedCurrencies.byCode(
          accountsById[transaction.accountId]?.currencyCode ??
              SupportedCurrencies.fallback.code,
        );
        icon = category.icon.icon;
        color = category.color.color;
        message = l10n.largeExpenseWatchMessage(
          CurrencyFormatter.format(transaction.amount, currency),
          category.name,
          CurrencyFormatter.format(categoryAverageAmount, currency),
        );
      case RepeatedExpenseWatchItem(
        :final transactions,
        :final category,
        :final amount,
      ):
        final currency = SupportedCurrencies.byCode(
          accountsById[transactions.first.accountId]?.currencyCode ??
              SupportedCurrencies.fallback.code,
        );
        icon = category.icon.icon;
        color = category.color.color;
        message = l10n.repeatedExpenseWatchMessage(
          transactions.length.toString(),
          CurrencyFormatter.format(amount, currency),
          category.name,
        );
      case RisingCategoryWatchItem(:final category, :final percentIncrease):
        icon = category.icon.icon;
        color = theme.colorScheme.tertiary;
        message = l10n.risingCategoryWatchMessage(
          category.name,
          percentIncrease.round().toString(),
        );
    }

    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// A read-only row for Reports' detailed transaction list — deliberately
/// simpler than Transactions' own `TransactionTile`, which carries edit/
/// duplicate/delete actions that don't belong on an analysis screen (data
/// changes still happen from the Transactions tab, not from here).
class _ReportTransactionTile extends StatelessWidget {
  const _ReportTransactionTile({
    required this.transaction,
    this.account,
    this.category,
  });

  final TransactionEntity transaction;
  final AccountEntity? account;
  final CategoryEntity? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isTransfer = transaction.type == TransactionType.transfer;
    final isIncome = transaction.type == TransactionType.income;
    final semanticColors = AppSemanticColors.of(context);

    final color = isTransfer
        ? theme.colorScheme.primary
        : category?.color.color ?? theme.colorScheme.outline;
    final icon = isTransfer
        ? AppSymbols.currencyExchange
        : category?.icon.icon ?? AppSymbols.helpOutline;
    final title = isTransfer
        ? l10n.transferLabel
        : category?.name ?? l10n.uncategorizedLabel;
    final amountColor = isTransfer
        ? theme.colorScheme.onSurface
        : isIncome
        ? semanticColors.positiveForeground
        : semanticColors.negativeForeground;
    final sign = isTransfer
        ? ''
        : isIncome
        ? '+'
        : '-';
    final currency = SupportedCurrencies.byCode(
      account?.currencyCode ?? SupportedCurrencies.fallback.code,
    );
    final subtitleParts = [
      account?.name ?? l10n.unknownAccountLabel,
      if (transaction.note.isNotEmpty) transaction.note,
    ];

    return AppCard(
      onTap: () => context.push(
        AppRoutes.transactionEditPath(transaction.id),
        extra: transaction,
      ),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitleParts.join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${CurrencyFormatter.format(transaction.amount, currency)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                DateFormat.MMMd().format(transaction.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportFilterSheet extends ConsumerWidget {
  const _ReportFilterSheet();

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    ref
        .read(reportFilterProvider.notifier)
        .setCustomRange(
          DateTime(picked.start.year, picked.start.month, picked.start.day),
          DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
          ).add(const Duration(days: 1)),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filter = ref.watch(reportFilterProvider);
    final notifier = ref.read(reportFilterProvider.notifier);
    final accounts = ref.watch(accountsProvider(true)).value ?? [];
    final categories =
        ref
            .watch(categoriesProvider((type: null, includeArchived: true)))
            .value ??
        [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.reportFilterSheetTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (filter.isActive)
              TextButton(
                onPressed: notifier.clear,
                child: Text(l10n.clearFiltersButton),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.dateRangeFilterLabel, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                filter.hasCustomRange
                    ? '${DateFormat.yMMMd().format(filter.customRangeStart!)} - '
                          '${DateFormat.yMMMd().format(filter.customRangeEndExclusive!.subtract(const Duration(days: 1)))}'
                    : l10n.customDateRangeUnsetMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (filter.hasCustomRange)
              IconButton(
                icon: const Icon(AppSymbols.close),
                tooltip: l10n.clearDateRangeTooltip,
                onPressed: () => notifier.setCustomRange(null, null),
              )
            else
              TextButton(
                onPressed: () => _pickDateRange(context, ref),
                child: Text(l10n.chooseDateRangeButton),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.typeFilterLabel, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: Text(l10n.allTypesLabel),
              selected: filter.type == null,
              onSelected: (_) => notifier.setType(null),
            ),
            ChoiceChip(
              label: Text(l10n.incomeLabel),
              selected: filter.type == TransactionType.income,
              onSelected: (_) => notifier.setType(TransactionType.income),
            ),
            ChoiceChip(
              label: Text(l10n.expenseLabel),
              selected: filter.type == TransactionType.expense,
              onSelected: (_) => notifier.setType(TransactionType.expense),
            ),
            ChoiceChip(
              label: Text(l10n.transferLabel),
              selected: filter.type == TransactionType.transfer,
              onSelected: (_) => notifier.setType(TransactionType.transfer),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownButtonFormField<String?>(
          initialValue: filter.accountId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.accountFilterLabel),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.allAccountsLabel)),
            for (final account in accounts)
              DropdownMenuItem(
                value: account.id,
                child: Text(account.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: notifier.setAccountId,
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String?>(
          initialValue: filter.currencyCode,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.currencyLabel),
          items: [
            const DropdownMenuItem(value: null, child: Text('All currencies')),
            for (final currencyCode
                in (accounts
                    .map((account) => account.currencyCode)
                    .toSet()
                    .toList()
                  ..sort()))
              DropdownMenuItem(value: currencyCode, child: Text(currencyCode)),
          ],
          onChanged: notifier.setCurrencyCode,
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String?>(
          initialValue: filter.categoryId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.categoryFilterLabel),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.allCategoriesLabel)),
            for (final category in categories)
              DropdownMenuItem(
                value: category.id,
                child: Text(category.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: notifier.setCategoryId,
        ),
      ],
    );
  }
}
