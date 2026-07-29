import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/analytics_logger.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/month_selector_header.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../budget/presentation/widgets/budget_progress_tile.dart';
import '../../domain/entities/converted_monthly_totals.dart';
import '../../domain/entities/monthly_report.dart';
import '../providers/report_providers.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/income_expense_trend_chart.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _exportCsv(
    BuildContext context,
    WidgetRef ref,
    MonthlyReport report,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final monthLabel =
        '${report.month.year}-${report.month.month.toString().padLeft(2, '0')}';
    final csv = ref.read(exportReportToCsvUseCaseProvider)(report);
    final fileName = 'cashly-report-$monthLabel.csv';

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
    final report = reportAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.exportReportTooltip,
            onPressed: report != null && report.hasAnyActivity
                ? () => _exportCsv(context, ref, report)
                : null,
          ),
        ],
        bottom: MonthSelectorHeader(
          month: month,
          onPrevious: () =>
              ref.read(selectedReportMonthProvider.notifier).previousMonth(),
          onNext: () =>
              ref.read(selectedReportMonthProvider.notifier).nextMonth(),
        ),
      ),
      body: ResponsiveCenter(
        child: reportAsync.when(
          loading: () => const AppLoadingIndicator(),
          error: (error, _) => ErrorView(message: '$error'),
          data: (report) {
            if (!report.hasAnyActivity) {
              return EmptyState(
                icon: Icons.insert_chart_outlined,
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
                if (report.budgetProgress.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.budgetVsActualSectionTitle,
                    onSeeAll: () => context.go(AppRoutes.budget),
                  ),
                  for (final progress in report.budgetProgress)
                    BudgetProgressTile(progress: progress),
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
  const _MonthlySummaryCard({required this.currencyCode, required this.report});

  final String currencyCode;
  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currency = SupportedCurrencies.byCode(currencyCode);
    final income = report.totalIncomeByCurrency[currencyCode] ?? 0;
    final expense = report.totalExpenseByCurrency[currencyCode] ?? 0;
    final net = report.netByCurrency[currencyCode] ?? 0;
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
                  Icons.currency_exchange,
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
