import 'package:flutter/material.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/entities/financial_insight_message.dart';
import '../../domain/entities/smart_money_score.dart';

/// An explainable, balance-led check-in that stays useful on every layout.
///
/// The monthly score is deliberately the visual focus. Today and week remain
/// compact companion checks, while every number in the detail sheet comes
/// from the same persisted calculation that produced the score.
class FinancialInsightCard extends StatelessWidget {
  const FinancialInsightCard({super.key, required this.insight});

  final FinancialInsight insight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final currency = SupportedCurrencies.byCode(insight.currencyCode);
    final monthlyStatus = _statusFor(
      insight.monthScore,
      colors,
      l10n,
      calculation: insight.monthlyScoreCalculation,
    );
    final calculation = insight.monthlyScoreCalculation;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .62)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              monthlyStatus.color.withValues(alpha: .10),
              colors.surface,
              colors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(
                currencyCode: insight.currencyCode,
                color: monthlyStatus.color,
              ),
              const SizedBox(height: AppSpacing.md),
              _MonthlyScoreHero(
                score: insight.monthScore,
                status: monthlyStatus,
                hasReliableBaseline: calculation?.isReliable ?? false,
                onWhyPressed: () => _showScoreBreakdown(context, insight),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ScoreStrip(
                scores: [
                  insight.todayScore,
                  insight.weekScore,
                  insight.monthScore,
                ],
                calculation: calculation,
              ),
              const SizedBox(height: AppSpacing.md),
              _ScoreMetrics(
                insight: insight,
                currency: currency,
                scoreColor: monthlyStatus.color,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _formatFinancialInsightMessage(insight.headline, l10n),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatFinancialInsightMessage(insight.explanation, l10n),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (insight.scoreReasons.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.smartMoneyScoreWhatIsShapingLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: monthlyStatus.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final reason in insight.scoreReasons.take(2))
                  _ReasonLine(
                    reason: _formatFinancialInsightMessage(reason, l10n),
                    color: monthlyStatus.color,
                  ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.smartMoneyScorePracticalNextStepLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: monthlyStatus.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final action in insight.actions.take(2))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        AppSymbols.checkCircle,
                        size: 19,
                        color: monthlyStatus.color,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.onSurface,
                                  height: 1.35,
                                ),
                            children: [
                              TextSpan(
                                text:
                                    '${_formatFinancialInsightMessage(action.title, l10n)}. ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: _formatFinancialInsightMessage(
                                  action.detail,
                                  l10n,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.currencyCode, required this.color});

  final String currencyCode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: .14),
          foregroundColor: color,
          child: const Icon(AppSymbols.autoAwesome),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.smartMoneyScoreCardTitle,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                l10n.smartMoneyScoreCardSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _CurrencyPill(currencyCode: currencyCode, color: color),
      ],
    );
  }
}

class _MonthlyScoreHero extends StatelessWidget {
  const _MonthlyScoreHero({
    required this.score,
    required this.status,
    required this.hasReliableBaseline,
    required this.onWhyPressed,
  });

  final FinancialPeriodScore score;
  final _ScoreStatus status;
  final bool hasReliableBaseline;
  final VoidCallback onWhyPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest.withValues(alpha: .66),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: .28)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: AppSpacing.sm,
        spacing: AppSpacing.md,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${score.value}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 128,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.smartMoneyScoreMonthlyHeroLabel(score.maximum),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    _StatusBadge(status: status),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onWhyPressed,
                icon: const Icon(AppSymbols.info, size: 18),
                label: Text(l10n.smartMoneyScoreWhyThisScore),
              ),
              Text(
                hasReliableBaseline
                    ? l10n.smartMoneyScoreComparedWithOpening
                    : l10n.smartMoneyScoreNeutralBaseline,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({required this.scores, required this.calculation});

  final List<FinancialPeriodScore> scores;
  final SmartMoneyScoreCalculation? calculation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Daily, weekly, and monthly score checks',
      child: Row(
        children: [
          for (var index = 0; index < scores.length; index++) ...[
            Expanded(
              child: _PeriodScoreTile(
                score: scores[index],
                calculation: scores[index].period == FinancialWindowKind.month
                    ? calculation
                    : null,
              ),
            ),
            if (index < scores.length - 1) const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _PeriodScoreTile extends StatelessWidget {
  const _PeriodScoreTile({required this.score, required this.calculation});

  final FinancialPeriodScore score;
  final SmartMoneyScoreCalculation? calculation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final status = _statusFor(score, colors, l10n, calculation: calculation);
    final isMonth = score.period == FinancialWindowKind.month;
    return Tooltip(
      message: score.reasons
          .map((reason) => _formatFinancialInsightMessage(reason, l10n))
          .join('\n'),
      child: Container(
        constraints: const BoxConstraints(minHeight: 82),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: isMonth ? .16 : .09),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: status.color.withValues(alpha: isMonth ? .38 : .18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _periodLabel(score.period, l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${score.value}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              isMonth ? '/ 150' : '/ 100',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreMetrics extends StatelessWidget {
  const _ScoreMetrics({
    required this.insight,
    required this.currency,
    required this.scoreColor,
  });

  final FinancialInsight insight;
  final AppCurrency currency;
  final Color scoreColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final calculation = insight.monthlyScoreCalculation;
    final budget = _budgetSummary(insight.budgets, l10n);
    final openingBalance = calculation == null || !calculation.isReliable
        ? null
        : calculation.currentBalance - calculation.balanceChange;
    final previousChange = insight.month.expenseChangePercent;
    final metrics = <_MetricItem>[
      _MetricItem(
        label: l10n.smartMoneyScoreRowOpeningBalance,
        value: openingBalance == null
            ? l10n.smartMoneyScoreStatusNotEnoughData
            : CurrencyFormatter.format(openingBalance, currency),
        icon: AppSymbols.flag,
      ),
      _MetricItem(
        label: l10n.smartMoneyScoreRowCurrentBalance,
        value: CurrencyFormatter.format(
          calculation?.currentBalance ?? insight.totalBalance,
          currency,
        ),
        icon: AppSymbols.accountBalanceWallet,
      ),
      _MetricItem(
        label: l10n.smartMoneyScoreRowBalanceChange,
        value: calculation == null || !calculation.isReliable
            ? '—'
            : '${_signedAmount(calculation.balanceChange, currency)} (${_signedPercent(calculation.balanceChangePercentage)})',
        icon: calculation != null && calculation.balanceChange < 0
            ? AppSymbols.southEast
            : AppSymbols.northEast,
        color: calculation == null || calculation.balanceChange == 0
            ? null
            : calculation.balanceChange > 0
            ? Colors.teal
            : colors.error,
      ),
      _MetricItem(
        label: l10n.smartMoneyScoreRowIncome,
        value: CurrencyFormatter.format(insight.month.income, currency),
        icon: AppSymbols.addChart,
        color: Colors.teal,
      ),
      _MetricItem(
        label: l10n.smartMoneyScoreRowExpenses,
        value: CurrencyFormatter.format(insight.month.expense, currency),
        icon: AppSymbols.shoppingBag,
        color: colors.error,
      ),
      _MetricItem(
        label: l10n.smartMoneyScoreMetricNetCashFlow,
        value: _signedAmount(
          calculation?.netCashFlow ??
              (insight.month.income - insight.month.expense),
          currency,
        ),
        icon: AppSymbols.waterfallChart,
        color:
            (calculation?.netCashFlow ??
                    (insight.month.income - insight.month.expense)) >=
                0
            ? Colors.teal
            : colors.error,
      ),
      _MetricItem(
        label: l10n.smartMoneyScoreRowBudgetPerformance,
        value: budget.label,
        icon: AppSymbols.pieChart,
        color: budget.color ?? scoreColor,
      ),
      _MetricItem(
        label: l10n.smartMoneyScoreMetricComparedLastMonth,
        value: previousChange == null
            ? l10n.smartMoneyScoreValueNoComparisonYet
            : l10n.smartMoneyScoreMetricExpensesChange(
                _signedPercent(previousChange),
              ),
        icon: AppSymbols.compareArrows,
        color: previousChange == null
            ? null
            : previousChange <= 0
            ? Colors.teal
            : Colors.orange.shade800,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 580 ? 4 : 2;
        final tileWidth =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: tileWidth,
                child: _MetricTile(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _MetricItem metric;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = metric.color ?? colors.onSurfaceVariant;
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .36),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(metric.icon, size: 15, color: tone),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            metric.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _ScoreStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: status.color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill({required this.currencyCode, required this.color});

  final String currencyCode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        currencyCode,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReasonLine extends StatelessWidget {
  const _ReasonLine({required this.reason, required this.color});

  final String reason;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Icon(AppSymbols.circle, size: 6, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(reason, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

Future<void> _showScoreBreakdown(
  BuildContext context,
  FinancialInsight insight,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ScoreBreakdownSheet(insight: insight),
  );
}

class _ScoreBreakdownSheet extends StatelessWidget {
  const _ScoreBreakdownSheet({required this.insight});

  final FinancialInsight insight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final currency = SupportedCurrencies.byCode(insight.currencyCode);
    final calculation = insight.monthlyScoreCalculation;
    final status = _statusFor(
      insight.monthScore,
      colors,
      l10n,
      calculation: calculation,
    );
    final budget = _budgetSummary(insight.budgets, l10n);
    final breakdown = calculation?.behaviourBreakdown;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .84,
          maxWidth: 720,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.smartMoneyScoreWhyThisScore,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.smartMoneyScoreBreakdownSheetDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (calculation == null || !calculation.isReliable)
                _BreakdownNotice(
                  message:
                      calculation?.unavailableReason ??
                      l10n.smartMoneyScoreBreakdownUnavailableFallback,
                )
              else ...[
                _BreakdownSection(
                  title: l10n.smartMoneyScoreSectionBalanceMovement,
                  rows: [
                    _BreakdownRow(
                      label: l10n.smartMoneyScoreRowOpeningBalance,
                      value: CurrencyFormatter.format(
                        calculation.currentBalance - calculation.balanceChange,
                        currency,
                      ),
                    ),
                    _BreakdownRow(
                      label: l10n.smartMoneyScoreRowCurrentBalance,
                      value: CurrencyFormatter.format(
                        calculation.currentBalance,
                        currency,
                      ),
                    ),
                    _BreakdownRow(
                      label: l10n.smartMoneyScoreRowBalanceChange,
                      value:
                          '${_signedAmount(calculation.balanceChange, currency)} (${_signedPercent(calculation.balanceChangePercentage)})',
                      color: calculation.balanceChange >= 0
                          ? Colors.teal
                          : colors.error,
                    ),
                    _BreakdownRow(
                      label: l10n.smartMoneyScoreRowBalanceGrowthContribution,
                      value:
                          '${_signedPoints(calculation.balanceChangePercentage)} points',
                      color: status.color,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _BreakdownSection(
                title: l10n.smartMoneyScoreSectionMonthActivity,
                rows: [
                  _BreakdownRow(
                    label: l10n.smartMoneyScoreRowIncome,
                    value: CurrencyFormatter.format(
                      insight.month.income,
                      currency,
                    ),
                    supporting: _impactDescription(
                      breakdown?.incomeExpenseImpact,
                      positive: l10n.smartMoneyScoreImpactIncomePositive,
                      negative: l10n.smartMoneyScoreImpactIncomeNegative,
                      neutral: l10n.smartMoneyScoreImpactIncomeNeutral,
                    ),
                  ),
                  _BreakdownRow(
                    label: l10n.smartMoneyScoreRowExpenses,
                    value: CurrencyFormatter.format(
                      insight.month.expense,
                      currency,
                    ),
                  ),
                  _BreakdownRow(
                    label: l10n.smartMoneyScoreRowNetCashFlowSavings,
                    value: _signedAmount(
                      calculation?.netCashFlow ??
                          insight.month.income - insight.month.expense,
                      currency,
                    ),
                    supporting: _impactDescription(
                      breakdown?.savingsImpact,
                      positive: l10n.smartMoneyScoreImpactSavingsPositive,
                      negative: l10n.smartMoneyScoreImpactSavingsNegative,
                      neutral: l10n.smartMoneyScoreImpactSavingsNeutral,
                    ),
                  ),
                  _BreakdownRow(
                    label: l10n.smartMoneyScoreRowBudgetPerformance,
                    value: budget.label,
                    supporting: _impactDescription(
                      breakdown?.budgetImpact,
                      positive: l10n.smartMoneyScoreImpactBudgetPositive,
                      negative: l10n.smartMoneyScoreImpactBudgetNegative,
                      neutral: l10n.smartMoneyScoreImpactBudgetNeutral,
                    ),
                  ),
                  _BreakdownRow(
                    label: l10n.smartMoneyScoreRowPreviousPeriodComparison,
                    value: _expenseComparisonLabel(insight.month, l10n),
                    supporting: _impactDescription(
                      breakdown?.spendingTrendImpact,
                      positive: l10n.smartMoneyScoreImpactTrendPositive,
                      negative: l10n.smartMoneyScoreImpactTrendNegative,
                      neutral: l10n.smartMoneyScoreImpactTrendNeutral,
                    ),
                  ),
                  _BreakdownRow(
                    label: l10n.smartMoneyScoreRowOverdueBills,
                    value: l10n.smartMoneyScoreValueNotIncludedYet,
                    supporting: l10n.smartMoneyScoreImpactBillsSupporting,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _BreakdownSection(
                title: l10n.smartMoneyScoreSectionFormula,
                rows: [
                  _BreakdownRow(
                    label: l10n.smartMoneyScoreRowStartingScore,
                    value: '100',
                  ),
                  _BreakdownRow(
                    label: l10n.smartMoneyScoreRowBalanceGrowthContribution,
                    value: calculation == null || !calculation.isReliable
                        ? l10n.smartMoneyScoreValueNeutralUntilBaseline
                        : _signedPoints(calculation.balanceChangePercentage),
                  ),
                  _BreakdownRow(
                    label: l10n.smartMoneyScoreRowBehaviourModifier,
                    value: calculation == null
                        ? l10n.smartMoneyScorePointsSuffix('0')
                        : l10n.smartMoneyScoreValueBehaviourModifierPoints(
                            _signedPoints(
                              calculation.financialBehaviourModifier.toDouble(),
                            ),
                          ),
                  ),
                  _BreakdownRow(
                    label: l10n.smartMoneyScoreRowFinalMonthlyScore,
                    value:
                        '${insight.monthScore.value} / ${insight.monthScore.maximum}',
                    color: status.color,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.smartMoneyScoreFormulaFootnote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownNotice extends StatelessWidget {
  const _BreakdownNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppSymbols.info, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({required this.title, required this.rows});

  final String title;
  final List<_BreakdownRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var index = 0; index < rows.length; index++) ...[
            rows[index],
            if (index < rows.length - 1)
              Divider(color: colors.outlineVariant.withValues(alpha: .55)),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.supporting,
    this.color,
  });

  final String label;
  final String value;
  final String? supporting;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                if (supporting != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    supporting!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color ?? colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreStatus {
  const _ScoreStatus({required this.label, required this.color});

  final String label;
  final Color color;
}

class _BudgetSummary {
  const _BudgetSummary({required this.label, this.color});

  final String label;
  final Color? color;
}

_ScoreStatus _statusFor(
  FinancialPeriodScore score,
  ColorScheme colors,
  AppLocalizations l10n, {
  SmartMoneyScoreCalculation? calculation,
}) {
  if (score.period == FinancialWindowKind.month) {
    if (calculation != null && !calculation.isReliable) {
      return _ScoreStatus(
        label: l10n.smartMoneyScoreStatusNotEnoughData,
        color: colors.primary,
      );
    }
    return switch (score.value) {
      >= 120 => _ScoreStatus(
        label: l10n.smartMoneyScoreStatusExcellentGrowth,
        color: Colors.teal,
      ),
      >= 105 => _ScoreStatus(
        label: l10n.smartMoneyScoreStatusGrowing,
        color: Colors.green,
      ),
      >= 95 => _ScoreStatus(
        label: l10n.smartMoneyScoreStatusStable,
        color: colors.primary,
      ),
      >= 75 => _ScoreStatus(
        label: l10n.smartMoneyScoreStatusDeclining,
        color: Colors.orange,
      ),
      _ => _ScoreStatus(
        label: l10n.smartMoneyScoreStatusNeedsAttention,
        color: colors.error,
      ),
    };
  }

  return switch (score.value) {
    >= 80 => _ScoreStatus(
      label: l10n.smartMoneyScoreStatusExcellent,
      color: Colors.teal,
    ),
    >= 65 => _ScoreStatus(
      label: l10n.smartMoneyScoreStatusGood,
      color: colors.primary,
    ),
    >= 50 => _ScoreStatus(
      label: l10n.smartMoneyScoreStatusFair,
      color: Colors.orange,
    ),
    >= 30 => _ScoreStatus(
      label: l10n.smartMoneyScoreStatusNeedsAttention,
      color: Colors.orange,
    ),
    _ => _ScoreStatus(
      label: l10n.smartMoneyScoreStatusHighRisk,
      color: colors.error,
    ),
  };
}

_BudgetSummary _budgetSummary(
  List<FinancialBudgetStatus> budgets,
  AppLocalizations l10n,
) {
  if (budgets.isEmpty) {
    return _BudgetSummary(label: l10n.smartMoneyScoreBudgetNoneSet);
  }
  final overBudget = budgets.where((budget) => budget.usage >= 1).length;
  if (overBudget > 0) {
    return _BudgetSummary(
      label: l10n.smartMoneyScoreBudgetOverCount(overBudget),
      color: Colors.red,
    );
  }
  final nearBudget = budgets.where((budget) => budget.usage >= .85).length;
  if (nearBudget > 0) {
    return _BudgetSummary(
      label: l10n.smartMoneyScoreBudgetNearlyFullCount(nearBudget),
      color: Colors.orange,
    );
  }
  return _BudgetSummary(
    label: l10n.smartMoneyScoreBudgetOnTrack,
    color: Colors.teal,
  );
}

String _periodLabel(FinancialWindowKind period, AppLocalizations l10n) =>
    switch (period) {
      FinancialWindowKind.today => l10n.financialInsightPeriodToday,
      FinancialWindowKind.week => l10n.financialInsightPeriodWeek,
      FinancialWindowKind.month => l10n.financialInsightPeriodMonth,
    };

String _signedAmount(double amount, AppCurrency currency) {
  final prefix = amount > 0
      ? '+'
      : amount < 0
      ? '-'
      : '';
  return '$prefix${CurrencyFormatter.format(amount.abs(), currency)}';
}

String _signedPercent(double value) {
  final prefix = value > 0
      ? '+'
      : value < 0
      ? '-'
      : '';
  final absolute = value.abs();
  final digits = absolute < 10 && absolute != absolute.roundToDouble() ? 1 : 0;
  return '$prefix${absolute.toStringAsFixed(digits)}%';
}

String _signedPoints(double value) {
  final prefix = value > 0
      ? '+'
      : value < 0
      ? '-'
      : '';
  final absolute = value.abs();
  final digits = absolute != absolute.roundToDouble() ? 1 : 0;
  return '$prefix${absolute.toStringAsFixed(digits)}';
}

String _impactDescription(
  int? impact, {
  required String positive,
  required String negative,
  required String neutral,
}) {
  if (impact == null || impact == 0) return neutral;
  return impact > 0 ? '$positive (+$impact)' : '$negative ($impact)';
}

String _expenseComparisonLabel(
  FinancialSpendingWindow month,
  AppLocalizations l10n,
) {
  final change = month.expenseChangePercent;
  if (change == null) return l10n.smartMoneyScoreValueNoComparisonYet;
  return l10n.smartMoneyScoreMetricExpensesChange(_signedPercent(change));
}

/// Renders a domain-layer [FinancialInsightMessage] into localized display
/// text. [FinancialInsightMessageKey.literal] is the one deliberate
/// exception — it renders the persisted Smart Money Score calculation's
/// own (English-only, auditable) reason text verbatim; see this file's
/// `CLAUDE.md` Phase 2a/2b entries for why.
String _formatFinancialInsightMessage(
  FinancialInsightMessage message,
  AppLocalizations l10n,
) {
  final args = message.args;
  switch (message.key) {
    case FinancialInsightMessageKey.literal:
      return args['text']! as String;
    case FinancialInsightMessageKey.steadySpendingHeadline:
      return l10n.financialInsightMsgSteadySpendingHeadline;
    case FinancialInsightMessageKey.steadySpendingExplanation:
      return l10n.financialInsightMsgSteadySpendingExplanation;
    case FinancialInsightMessageKey.negativeBalanceHeadline:
      return l10n.financialInsightMsgNegativeBalanceHeadline;
    case FinancialInsightMessageKey.negativeBalanceExplanation:
      return l10n.financialInsightMsgNegativeBalanceExplanation(
        args['currency']! as String,
        args['amount']! as String,
      );
    case FinancialInsightMessageKey.planEssentialExpenseTitle:
      return l10n.financialInsightMsgPlanEssentialExpenseTitle;
    case FinancialInsightMessageKey.planEssentialExpenseDetail:
      return l10n.financialInsightMsgPlanEssentialExpenseDetail;
    case FinancialInsightMessageKey.categoryOverBudgetHeadline:
      return l10n.financialInsightMsgCategoryOverBudgetHeadline(
        args['category']! as String,
      );
    case FinancialInsightMessageKey.categoryOverBudgetExplanation:
      return l10n.financialInsightMsgCategoryOverBudgetExplanation(
        args['spent']! as String,
        args['limit']! as String,
      );
    case FinancialInsightMessageKey.pauseCategorySpendingTitle:
      return l10n.financialInsightMsgPauseCategorySpendingTitle(
        args['category']! as String,
      );
    case FinancialInsightMessageKey.pauseCategorySpendingDetail:
      return l10n.financialInsightMsgPauseCategorySpendingDetail;
    case FinancialInsightMessageKey.categoryNeedsRoomHeadline:
      return l10n.financialInsightMsgCategoryNeedsRoomHeadline(
        args['category']! as String,
      );
    case FinancialInsightMessageKey.categoryNeedsRoomExplanation:
      return l10n.financialInsightMsgCategoryNeedsRoomExplanation(
        args['percent']! as String,
        args['limit']! as String,
      );
    case FinancialInsightMessageKey.setRestOfMonthLimitTitle:
      return l10n.financialInsightMsgSetRestOfMonthLimitTitle(
        args['category']! as String,
      );
    case FinancialInsightMessageKey.setRestOfMonthLimitDetail:
      return l10n.financialInsightMsgSetRestOfMonthLimitDetail(
        args['remaining']! as String,
      );
    case FinancialInsightMessageKey.categoryHigherThanUsualHeadline:
      return l10n.financialInsightMsgCategoryHigherThanUsualHeadline(
        args['category']! as String,
      );
    case FinancialInsightMessageKey.categoryHigherThanUsualExplanation:
      return l10n.financialInsightMsgCategoryHigherThanUsualExplanation(
        args['changePercent']! as String,
      );
    case FinancialInsightMessageKey.reviewNextCategoryPurchaseTitle:
      return l10n.financialInsightMsgReviewNextCategoryPurchaseTitle(
        args['category']! as String,
      );
    case FinancialInsightMessageKey.reviewNextCategoryPurchaseDetail:
      return l10n.financialInsightMsgReviewNextCategoryPurchaseDetail;
    case FinancialInsightMessageKey.todaySpendingFasterHeadline:
      return l10n.financialInsightMsgTodaySpendingFasterHeadline;
    case FinancialInsightMessageKey.todaySpendingFasterExplanation:
      return l10n.financialInsightMsgTodaySpendingFasterExplanation;
    case FinancialInsightMessageKey.checkNextExpenseTitle:
      return l10n.financialInsightMsgCheckNextExpenseTitle;
    case FinancialInsightMessageKey.checkNextExpenseDetail:
      return l10n.financialInsightMsgCheckNextExpenseDetail;
    case FinancialInsightMessageKey.spendingAheadOfIncomeHeadline:
      return l10n.financialInsightMsgSpendingAheadOfIncomeHeadline;
    case FinancialInsightMessageKey.spendingAheadOfIncomeExplanation:
      return l10n.financialInsightMsgSpendingAheadOfIncomeExplanation;
    case FinancialInsightMessageKey.chooseLowPriorityExpenseTitle:
      return l10n.financialInsightMsgChooseLowPriorityExpenseTitle;
    case FinancialInsightMessageKey.chooseLowPriorityExpenseDetail:
      return l10n.financialInsightMsgChooseLowPriorityExpenseDetail;
    case FinancialInsightMessageKey.balanceZeroHeadline:
      return l10n.financialInsightMsgBalanceZeroHeadline;
    case FinancialInsightMessageKey.balanceThinHeadline:
      return l10n.financialInsightMsgBalanceThinHeadline;
    case FinancialInsightMessageKey.balanceLimitedHeadline:
      return l10n.financialInsightMsgBalanceLimitedHeadline;
    case FinancialInsightMessageKey.balanceSteadyHeadline:
      return l10n.financialInsightMsgBalanceSteadyHeadline;
    case FinancialInsightMessageKey.balanceZeroExplanation:
      return l10n.financialInsightMsgBalanceZeroExplanation(
        args['currency']! as String,
      );
    case FinancialInsightMessageKey.balanceThinExplanation:
      return l10n.financialInsightMsgBalanceThinExplanation(
        args['currency']! as String,
        args['days']! as int,
      );
    case FinancialInsightMessageKey.balanceLimitedExplanation:
      return l10n.financialInsightMsgBalanceLimitedExplanation(
        args['currency']! as String,
        args['days']! as int,
      );
    case FinancialInsightMessageKey.balanceSteadyExplanation:
      return l10n.financialInsightMsgBalanceSteadyExplanation;
    case FinancialInsightMessageKey.protectEssentialExpenseTitle:
      return l10n.financialInsightMsgProtectEssentialExpenseTitle;
    case FinancialInsightMessageKey.protectEssentialExpenseDetail:
      return l10n.financialInsightMsgProtectEssentialExpenseDetail;
    case FinancialInsightMessageKey.reserveNextDaysTitle:
      return l10n.financialInsightMsgReserveNextDaysTitle(args['days']! as int);
    case FinancialInsightMessageKey.reserveNextDaysDetail:
      return l10n.financialInsightMsgReserveNextDaysDetail;
    case FinancialInsightMessageKey.setShortRestOfWeekLimitTitle:
      return l10n.financialInsightMsgSetShortRestOfWeekLimitTitle;
    case FinancialInsightMessageKey.setShortRestOfWeekLimitDetail:
      return l10n.financialInsightMsgSetShortRestOfWeekLimitDetail;
    case FinancialInsightMessageKey.keepExpenseIntentionalTitle:
      return l10n.financialInsightMsgKeepExpenseIntentionalTitle;
    case FinancialInsightMessageKey.keepExpenseIntentionalBalanceDetail:
      return l10n.financialInsightMsgKeepExpenseIntentionalBalanceDetail;
    case FinancialInsightMessageKey.keepExpenseIntentionalPaceDetail:
      return l10n.financialInsightMsgKeepExpenseIntentionalPaceDetail;
    case FinancialInsightMessageKey.onboardingHeadline:
      return l10n.financialInsightMsgOnboardingHeadline;
    case FinancialInsightMessageKey.onboardingExplanation:
      return l10n.financialInsightMsgOnboardingExplanation;
    case FinancialInsightMessageKey.logNextExpenseTitle:
      return l10n.financialInsightMsgLogNextExpenseTitle;
    case FinancialInsightMessageKey.logNextExpenseDetail:
      return l10n.financialInsightMsgLogNextExpenseDetail;
    case FinancialInsightMessageKey.notEnoughActivityTodayReason:
      return l10n.financialInsightMsgNotEnoughActivityTodayReason;
    case FinancialInsightMessageKey.notEnoughActivityWeekReason:
      return l10n.financialInsightMsgNotEnoughActivityWeekReason;
    case FinancialInsightMessageKey.notEnoughActivityMonthReason:
      return l10n.financialInsightMsgNotEnoughActivityMonthReason;
    case FinancialInsightMessageKey.balanceImpactNegativeReason:
      return l10n.financialInsightMsgBalanceImpactNegativeReason(
        args['currency']! as String,
      );
    case FinancialInsightMessageKey.balanceImpactEmptyReason:
      return l10n.financialInsightMsgBalanceImpactEmptyReason(
        args['currency']! as String,
      );
    case FinancialInsightMessageKey.balanceImpactLowReason:
      return l10n.financialInsightMsgBalanceImpactLowReason(
        args['currency']! as String,
        args['days']! as int,
      );
    case FinancialInsightMessageKey.balanceImpactHealthyReason:
      return l10n.financialInsightMsgBalanceImpactHealthyReason(
        args['currency']! as String,
      );
    case FinancialInsightMessageKey.categoryOverBudgetReasonToday:
      return l10n.financialInsightMsgCategoryOverBudgetReasonToday(
        args['category']! as String,
      );
    case FinancialInsightMessageKey.categoryNearBudgetReasonToday:
      return l10n.financialInsightMsgCategoryNearBudgetReasonToday(
        args['category']! as String,
      );
    case FinancialInsightMessageKey.todaySpikeReason:
      return l10n.financialInsightMsgTodaySpikeReason;
    case FinancialInsightMessageKey.todayComparableIncreaseReason:
      return l10n.financialInsightMsgTodayComparableIncreaseReason(
        args['changePercent']! as String,
      );
    case FinancialInsightMessageKey.noActivityTodayReason:
      return l10n.financialInsightMsgNoActivityTodayReason;
    case FinancialInsightMessageKey.incomeCoversTodayReason:
      return l10n.financialInsightMsgIncomeCoversTodayReason;
    case FinancialInsightMessageKey.categoryOverBudgetReasonWeek:
      return l10n.financialInsightMsgCategoryOverBudgetReasonWeek(
        args['category']! as String,
      );
    case FinancialInsightMessageKey.categoryNearBudgetReasonWeek:
      return l10n.financialInsightMsgCategoryNearBudgetReasonWeek(
        args['category']! as String,
      );
    case FinancialInsightMessageKey.categoryPacedBudgetReasonWeek:
      return l10n.financialInsightMsgCategoryPacedBudgetReasonWeek(
        args['category']! as String,
      );
    case FinancialInsightMessageKey.weeklyCategorySpikeReason:
      return l10n.financialInsightMsgWeeklyCategorySpikeReason(
        args['category']! as String,
        args['changePercent']! as String,
      );
    case FinancialInsightMessageKey.weekComparableIncreaseReason:
      return l10n.financialInsightMsgWeekComparableIncreaseReason(
        args['changePercent']! as String,
      );
    case FinancialInsightMessageKey.weekComparableDecreaseReason:
      return l10n.financialInsightMsgWeekComparableDecreaseReason;
    case FinancialInsightMessageKey.categoryOverBudgetReasonMonth:
      return l10n.financialInsightMsgCategoryOverBudgetReasonMonth(
        args['category']! as String,
        args['percent']! as String,
      );
    case FinancialInsightMessageKey.categoryNearBudgetReasonMonth:
      return l10n.financialInsightMsgCategoryNearBudgetReasonMonth(
        args['category']! as String,
        args['remaining']! as String,
      );
    case FinancialInsightMessageKey.categoryPacedBudgetReasonMonth:
      return l10n.financialInsightMsgCategoryPacedBudgetReasonMonth(
        args['category']! as String,
      );
    case FinancialInsightMessageKey.spendingOverIncomeReasonMonth:
      return l10n.financialInsightMsgSpendingOverIncomeReasonMonth(
        args['expense']! as String,
        args['income']! as String,
      );
    case FinancialInsightMessageKey.incomeCoversMonthReason:
      return l10n.financialInsightMsgIncomeCoversMonthReason;
    case FinancialInsightMessageKey.monthComparableIncreaseReason:
      return l10n.financialInsightMsgMonthComparableIncreaseReason(
        args['changePercent']! as String,
      );
    case FinancialInsightMessageKey.monthComparableDecreaseReason:
      return l10n.financialInsightMsgMonthComparableDecreaseReason;
    case FinancialInsightMessageKey.steadyReasonToday:
      return l10n.financialInsightMsgSteadyReasonToday;
    case FinancialInsightMessageKey.steadyReasonWeek:
      return l10n.financialInsightMsgSteadyReasonWeek;
    case FinancialInsightMessageKey.steadyReasonMonth:
      return l10n.financialInsightMsgSteadyReasonMonth;
    case FinancialInsightMessageKey.shortHorizonNoActiveAccountToday:
      return l10n.financialInsightMsgShortHorizonNoActiveAccountToday;
    case FinancialInsightMessageKey.shortHorizonNoActiveAccountWeek:
      return l10n.financialInsightMsgShortHorizonNoActiveAccountWeek;
    case FinancialInsightMessageKey.shortHorizonCrossCurrencyToday:
      return l10n.financialInsightMsgShortHorizonCrossCurrencyToday;
    case FinancialInsightMessageKey.shortHorizonCrossCurrencyWeek:
      return l10n.financialInsightMsgShortHorizonCrossCurrencyWeek;
    case FinancialInsightMessageKey.shortHorizonAccountAddedToday:
      return l10n.financialInsightMsgShortHorizonAccountAddedToday;
    case FinancialInsightMessageKey.shortHorizonAccountAddedWeek:
      return l10n.financialInsightMsgShortHorizonAccountAddedWeek;
    case FinancialInsightMessageKey.shortHorizonUnverifiableToday:
      return l10n.financialInsightMsgShortHorizonUnverifiableToday;
    case FinancialInsightMessageKey.shortHorizonUnverifiableWeek:
      return l10n.financialInsightMsgShortHorizonUnverifiableWeek;
    case FinancialInsightMessageKey.shortHorizonZeroOpeningToday:
      return l10n.financialInsightMsgShortHorizonZeroOpeningToday;
    case FinancialInsightMessageKey.shortHorizonZeroOpeningWeek:
      return l10n.financialInsightMsgShortHorizonZeroOpeningWeek;
    case FinancialInsightMessageKey.shortHorizonIncreasedToday:
      return l10n.financialInsightMsgShortHorizonIncreasedToday(
        args['percent']! as String,
        args['points']! as String,
      );
    case FinancialInsightMessageKey.shortHorizonIncreasedWeek:
      return l10n.financialInsightMsgShortHorizonIncreasedWeek(
        args['percent']! as String,
        args['points']! as String,
      );
    case FinancialInsightMessageKey.shortHorizonDecreasedToday:
      return l10n.financialInsightMsgShortHorizonDecreasedToday(
        args['percent']! as String,
        args['points']! as String,
      );
    case FinancialInsightMessageKey.shortHorizonDecreasedWeek:
      return l10n.financialInsightMsgShortHorizonDecreasedWeek(
        args['percent']! as String,
        args['points']! as String,
      );
    case FinancialInsightMessageKey.shortHorizonStayedLevelToday:
      return l10n.financialInsightMsgShortHorizonStayedLevelToday(
        args['points']! as String,
      );
    case FinancialInsightMessageKey.shortHorizonStayedLevelWeek:
      return l10n.financialInsightMsgShortHorizonStayedLevelWeek(
        args['points']! as String,
      );
  }
}
