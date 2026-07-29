import 'package:flutter/material.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/financial_insight.dart';
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
    final colors = Theme.of(context).colorScheme;
    final currency = SupportedCurrencies.byCode(insight.currencyCode);
    final monthlyStatus = _statusFor(
      insight.monthScore,
      colors,
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
                insight.headline,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                insight.explanation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (insight.scoreReasons.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'What is shaping this month',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: monthlyStatus.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final reason in insight.scoreReasons.take(2))
                  _ReasonLine(reason: reason, color: monthlyStatus.color),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                'A practical next step',
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
                        Icons.check_circle_outline_rounded,
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
                                text: '${action.title}. ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(text: action.detail),
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
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: .14),
          foregroundColor: color,
          child: const Icon(Icons.auto_awesome_rounded),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cashly Smart Money Score',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'Balance movement leads. Habits provide the context.',
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
                        'MONTHLY SCORE · / 150',
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
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('Why this score?'),
              ),
              Text(
                hasReliableBaseline
                    ? 'Compared with your month opening balance'
                    : 'Using a neutral baseline until enough data is available',
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
    final colors = Theme.of(context).colorScheme;
    final status = _statusFor(score, colors, calculation: calculation);
    final isMonth = score.period == FinancialWindowKind.month;
    return Tooltip(
      message: score.reasons.join('\n'),
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
              _periodLabel(score.period),
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
    final colors = Theme.of(context).colorScheme;
    final calculation = insight.monthlyScoreCalculation;
    final budget = _budgetSummary(insight.budgets);
    final openingBalance = calculation == null || !calculation.isReliable
        ? null
        : calculation.currentBalance - calculation.balanceChange;
    final previousChange = insight.month.expenseChangePercent;
    final metrics = <_MetricItem>[
      _MetricItem(
        label: 'Opening balance',
        value: openingBalance == null
            ? 'Not enough data'
            : CurrencyFormatter.format(openingBalance, currency),
        icon: Icons.flag_outlined,
      ),
      _MetricItem(
        label: 'Current balance',
        value: CurrencyFormatter.format(
          calculation?.currentBalance ?? insight.totalBalance,
          currency,
        ),
        icon: Icons.account_balance_wallet_outlined,
      ),
      _MetricItem(
        label: 'Balance change',
        value: calculation == null || !calculation.isReliable
            ? '—'
            : '${_signedAmount(calculation.balanceChange, currency)} (${_signedPercent(calculation.balanceChangePercentage)})',
        icon: calculation != null && calculation.balanceChange < 0
            ? Icons.south_east_rounded
            : Icons.north_east_rounded,
        color: calculation == null || calculation.balanceChange == 0
            ? null
            : calculation.balanceChange > 0
            ? Colors.teal
            : colors.error,
      ),
      _MetricItem(
        label: 'Income',
        value: CurrencyFormatter.format(insight.month.income, currency),
        icon: Icons.add_chart_rounded,
        color: Colors.teal,
      ),
      _MetricItem(
        label: 'Expenses',
        value: CurrencyFormatter.format(insight.month.expense, currency),
        icon: Icons.shopping_bag_outlined,
        color: colors.error,
      ),
      _MetricItem(
        label: 'Net cash flow',
        value: _signedAmount(
          calculation?.netCashFlow ??
              (insight.month.income - insight.month.expense),
          currency,
        ),
        icon: Icons.waterfall_chart_rounded,
        color:
            (calculation?.netCashFlow ??
                    (insight.month.income - insight.month.expense)) >=
                0
            ? Colors.teal
            : colors.error,
      ),
      _MetricItem(
        label: 'Budget performance',
        value: budget.label,
        icon: Icons.pie_chart_outline_rounded,
        color: budget.color ?? scoreColor,
      ),
      _MetricItem(
        label: 'Compared with last month',
        value: previousChange == null
            ? 'No comparison yet'
            : '${_signedPercent(previousChange)} expenses',
        icon: Icons.compare_arrows_rounded,
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
            child: Icon(Icons.circle, size: 6, color: color),
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
    final colors = Theme.of(context).colorScheme;
    final currency = SupportedCurrencies.byCode(insight.currencyCode);
    final calculation = insight.monthlyScoreCalculation;
    final status = _statusFor(
      insight.monthScore,
      colors,
      calculation: calculation,
    );
    final budget = _budgetSummary(insight.budgets);
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
                      'Why this score?',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'The monthly score is calculated from the same synced financial data shown in your dashboard. Balance movement is always the main factor.',
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
                      'Cashly needs a reliable month opening balance before it can give a full comparison. The score stays neutral rather than guessing.',
                )
              else ...[
                _BreakdownSection(
                  title: 'Balance movement',
                  rows: [
                    _BreakdownRow(
                      label: 'Opening balance',
                      value: CurrencyFormatter.format(
                        calculation.currentBalance - calculation.balanceChange,
                        currency,
                      ),
                    ),
                    _BreakdownRow(
                      label: 'Current balance',
                      value: CurrencyFormatter.format(
                        calculation.currentBalance,
                        currency,
                      ),
                    ),
                    _BreakdownRow(
                      label: 'Balance change',
                      value:
                          '${_signedAmount(calculation.balanceChange, currency)} (${_signedPercent(calculation.balanceChangePercentage)})',
                      color: calculation.balanceChange >= 0
                          ? Colors.teal
                          : colors.error,
                    ),
                    _BreakdownRow(
                      label: 'Balance-growth contribution',
                      value:
                          '${_signedPoints(calculation.balanceChangePercentage)} points',
                      color: status.color,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _BreakdownSection(
                title: 'This month’s financial activity',
                rows: [
                  _BreakdownRow(
                    label: 'Income',
                    value: CurrencyFormatter.format(
                      insight.month.income,
                      currency,
                    ),
                    supporting: _impactDescription(
                      breakdown?.incomeExpenseImpact,
                      positive: 'Income is ahead of expenses.',
                      negative: 'Expenses are ahead of income.',
                      neutral:
                          'Income and expenses are currently even or unavailable.',
                    ),
                  ),
                  _BreakdownRow(
                    label: 'Expenses',
                    value: CurrencyFormatter.format(
                      insight.month.expense,
                      currency,
                    ),
                  ),
                  _BreakdownRow(
                    label: 'Net cash flow / savings',
                    value: _signedAmount(
                      calculation?.netCashFlow ??
                          insight.month.income - insight.month.expense,
                      currency,
                    ),
                    supporting: _impactDescription(
                      breakdown?.savingsImpact,
                      positive: 'Positive cash flow supports the score.',
                      negative:
                          'Negative cash flow lowers the behaviour modifier slightly.',
                      neutral: 'No cash-flow modifier was applied.',
                    ),
                  ),
                  _BreakdownRow(
                    label: 'Budget performance',
                    value: budget.label,
                    supporting: _impactDescription(
                      breakdown?.budgetImpact,
                      positive: 'Current budgets remain on track.',
                      negative: 'Budget room is tight or a budget is exceeded.',
                      neutral: 'No active budget modifier was applied.',
                    ),
                  ),
                  _BreakdownRow(
                    label: 'Previous-period comparison',
                    value: _expenseComparisonLabel(insight.month),
                    supporting: _impactDescription(
                      breakdown?.spendingTrendImpact,
                      positive: 'Spending is lower than the comparable period.',
                      negative:
                          'Spending is notably higher than the comparable period.',
                      neutral:
                          'There is not enough comparable spending data yet.',
                    ),
                  ),
                  _BreakdownRow(
                    label: 'Overdue bills',
                    value: 'Not included yet',
                    supporting:
                        'No verified bill or reminder record is available, so no bill penalty was added.',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _BreakdownSection(
                title: 'Formula',
                rows: [
                  const _BreakdownRow(label: 'Starting score', value: '100'),
                  _BreakdownRow(
                    label: 'Balance-growth contribution',
                    value: calculation == null || !calculation.isReliable
                        ? 'Neutral until a baseline is available'
                        : _signedPoints(calculation.balanceChangePercentage),
                  ),
                  _BreakdownRow(
                    label: 'Behaviour modifier',
                    value: calculation == null
                        ? '0 points'
                        : '${_signedPoints(calculation.financialBehaviourModifier.toDouble())} points (capped at ±10)',
                  ),
                  _BreakdownRow(
                    label: 'Final monthly score',
                    value: '${insight.monthScore.value} / 150',
                    color: status.color,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Monthly score = clamp(0–150, 100 + balance change % + financial behaviour modifier).',
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
          Icon(Icons.info_outline_rounded, color: colors.primary),
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
  ColorScheme colors, {
  SmartMoneyScoreCalculation? calculation,
}) {
  if (score.period == FinancialWindowKind.month) {
    if (calculation != null && !calculation.isReliable) {
      return _ScoreStatus(label: 'Not enough data', color: colors.primary);
    }
    return switch (score.value) {
      >= 120 => const _ScoreStatus(
        label: 'Excellent Growth',
        color: Colors.teal,
      ),
      >= 105 => const _ScoreStatus(label: 'Growing', color: Colors.green),
      >= 95 => _ScoreStatus(label: 'Stable', color: colors.primary),
      >= 75 => _ScoreStatus(label: 'Declining', color: Colors.orange),
      _ => _ScoreStatus(label: 'Needs Attention', color: colors.error),
    };
  }

  return switch (score.value) {
    >= 80 => const _ScoreStatus(label: 'Excellent', color: Colors.teal),
    >= 65 => _ScoreStatus(label: 'Good', color: colors.primary),
    >= 50 => const _ScoreStatus(label: 'Fair', color: Colors.orange),
    >= 30 => const _ScoreStatus(label: 'Needs Attention', color: Colors.orange),
    _ => _ScoreStatus(label: 'High Risk', color: colors.error),
  };
}

_BudgetSummary _budgetSummary(List<FinancialBudgetStatus> budgets) {
  if (budgets.isEmpty) return const _BudgetSummary(label: 'No budgets set');
  final overBudget = budgets.where((budget) => budget.usage >= 1).length;
  if (overBudget > 0) {
    return _BudgetSummary(
      label: '$overBudget budget${overBudget == 1 ? '' : 's'} over',
      color: Colors.red,
    );
  }
  final nearBudget = budgets.where((budget) => budget.usage >= .85).length;
  if (nearBudget > 0) {
    return _BudgetSummary(
      label: '$nearBudget nearly full',
      color: Colors.orange,
    );
  }
  return const _BudgetSummary(label: 'On track', color: Colors.teal);
}

String _periodLabel(FinancialWindowKind period) => switch (period) {
  FinancialWindowKind.today => 'Today',
  FinancialWindowKind.week => 'Week',
  FinancialWindowKind.month => 'Month',
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

String _expenseComparisonLabel(FinancialSpendingWindow month) {
  final change = month.expenseChangePercent;
  if (change == null) return 'No comparison yet';
  return '${_signedPercent(change)} expenses';
}
