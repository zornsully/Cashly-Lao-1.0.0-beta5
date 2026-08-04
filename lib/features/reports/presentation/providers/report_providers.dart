import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../accounts/domain/entities/account_entity.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../dashboard/domain/usecases/compute_category_spending_usecase.dart';
import '../../../exchange_rates/presentation/providers/exchange_rate_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_filter.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../../transactions/domain/usecases/filter_transactions_usecase.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/converted_monthly_totals.dart';
import '../../domain/entities/expense_watch_item.dart';
import '../../domain/entities/monthly_report.dart';
import '../../domain/entities/monthly_trend_point.dart';
import '../../domain/entities/report_filter.dart';
import '../../domain/entities/report_insights.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/usecases/build_monthly_report_usecase.dart';
import '../../domain/usecases/build_monthly_trend_usecase.dart';
import '../../domain/usecases/compute_report_insights_usecase.dart';
import '../../domain/usecases/convert_report_totals_usecase.dart';
import '../../domain/usecases/detect_expense_watch_usecase.dart';
import '../../domain/usecases/export_report_to_csv_usecase.dart';
import '../../domain/usecases/export_transactions_to_csv_usecase.dart';

final exportReportToCsvUseCaseProvider = Provider<ExportReportToCsvUseCase>((
  ref,
) {
  return const ExportReportToCsvUseCase();
});

final exportTransactionsToCsvUseCaseProvider =
    Provider<ExportTransactionsToCsvUseCase>((ref) {
      return const ExportTransactionsToCsvUseCase();
    });

/// How many months (inclusive of the selected one) the Income vs Expense
/// trend chart covers.
const int trendMonthCount = 6;

/// How many trailing periods Expense Watch's "large"/"rising" heuristics
/// average over — see `DetectExpenseWatchUseCase`.
const int expenseWatchTrailingPeriodCount = 3;

/// The month the Reports screen is currently showing, truncated to its
/// first day. Persists for the app session, browsed independently of
/// Transactions'/Budget's/Dashboard's own month state — Reports is a
/// historical deep-dive, not tied to "now."
class SelectedReportMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }

  /// Moves the report's calendar anchor without changing the selected
  /// preset. Date based presets retain their local calendar semantics.
  void move(ReportPeriod period, int direction) {
    assert(direction == -1 || direction == 1);
    state = switch (period) {
      ReportPeriod.today => state.add(Duration(days: direction)),
      ReportPeriod.week => state.add(Duration(days: 7 * direction)),
      ReportPeriod.month || ReportPeriod.custom =>
        DateTime(state.year, state.month + direction, state.day),
      ReportPeriod.year => DateTime(state.year + direction, state.month, state.day),
    };
  }
}

final selectedReportMonthProvider =
    NotifierProvider<SelectedReportMonth, DateTime>(SelectedReportMonth.new);

/// Reports' current date-range/account/category/type filter. Lives
/// per-screen (autoDispose) so it always resets when the user leaves and
/// comes back — same reasoning as Transactions' own filter provider.
class ReportFilterNotifier extends Notifier<ReportFilter> {
  @override
  ReportFilter build() => const ReportFilter();

  void setCustomRange(DateTime? start, DateTime? endExclusive) {
    state = ReportFilter(
      period: start != null && endExclusive != null
          ? ReportPeriod.custom
          : ReportPeriod.month,
      customRangeStart: start,
      customRangeEndExclusive: endExclusive,
      accountId: state.accountId,
      categoryId: state.categoryId,
      type: state.type,
    );
  }

  void setPeriod(ReportPeriod period) {
    state = ReportFilter(
      period: period,
      customRangeStart: period == ReportPeriod.custom
          ? state.customRangeStart
          : null,
      customRangeEndExclusive: period == ReportPeriod.custom
          ? state.customRangeEndExclusive
          : null,
      accountId: state.accountId,
      categoryId: state.categoryId,
      currencyCode: state.currencyCode,
      type: state.type,
    );
  }

  void shiftCustomRange(int direction) {
    assert(direction == -1 || direction == 1);
    if (!state.hasCustomRange) return;
    final length = state.customRangeEndExclusive!.difference(
      state.customRangeStart!,
    );
    state = ReportFilter(
      period: ReportPeriod.custom,
      customRangeStart: state.customRangeStart!.add(length * direction),
      customRangeEndExclusive: state.customRangeEndExclusive!.add(
        length * direction,
      ),
      accountId: state.accountId,
      categoryId: state.categoryId,
      currencyCode: state.currencyCode,
      type: state.type,
    );
  }

  void setAccountId(String? accountId) {
    state = ReportFilter(
      period: state.period,
      customRangeStart: state.customRangeStart,
      customRangeEndExclusive: state.customRangeEndExclusive,
      accountId: accountId,
      categoryId: state.categoryId,
      currencyCode: state.currencyCode,
      type: state.type,
    );
  }

  void setCategoryId(String? categoryId) {
    state = ReportFilter(
      period: state.period,
      customRangeStart: state.customRangeStart,
      customRangeEndExclusive: state.customRangeEndExclusive,
      accountId: state.accountId,
      categoryId: categoryId,
      currencyCode: state.currencyCode,
      type: state.type,
    );
  }

  void setType(TransactionType? type) {
    state = ReportFilter(
      period: state.period,
      customRangeStart: state.customRangeStart,
      customRangeEndExclusive: state.customRangeEndExclusive,
      accountId: state.accountId,
      categoryId: state.categoryId,
      currencyCode: state.currencyCode,
      type: type,
    );
  }

  void setCurrencyCode(String? currencyCode) {
    state = ReportFilter(
      period: state.period,
      customRangeStart: state.customRangeStart,
      customRangeEndExclusive: state.customRangeEndExclusive,
      accountId: state.accountId,
      categoryId: state.categoryId,
      currencyCode: currencyCode,
      type: state.type,
    );
  }

  void clear() {
    state = const ReportFilter();
  }
}

final reportFilterProvider =
    NotifierProvider.autoDispose<ReportFilterNotifier, ReportFilter>(
      ReportFilterNotifier.new,
    );

/// The actual local-time calendar window a report covers. All downstream
/// providers share this exact helper so charts, totals, comparisons and
/// exports cannot disagree about which transaction belongs in a period.
({DateTime start, DateTime endExclusive}) _effectiveRange(
  DateTime month,
  ReportFilter filter,
) {
  final range = ReportDateRange.forPeriod(
    period: filter.period,
    anchor: month,
    customStart: filter.customRangeStart,
    customEndExclusive: filter.customRangeEndExclusive,
  );
  return (start: range.start, endExclusive: range.endExclusive);
}

/// The trailing window Expense Watch compares against: 3 calendar months
/// before the anchor month when browsing a plain month, or 3x the custom
/// range's own length when a custom range is active — calendar-month
/// arithmetic is used for the common case to match every other
/// month-based trailing window in this app (see `monthlyTrendProvider`),
/// rather than approximating "a month" as a fixed day count.
({DateTime start, DateTime endExclusive}) _trailingRange({
  required DateTime month,
  required ReportFilter filter,
  required DateTime effectiveStart,
}) {
  if (!filter.hasCustomRange) {
    final start = DateTime(
      month.year,
      month.month - expenseWatchTrailingPeriodCount,
    );
    return (start: start, endExclusive: effectiveStart);
  }
  final length = filter.customRangeEndExclusive!.difference(
    filter.customRangeStart!,
  );
  return (
    start: effectiveStart.subtract(length * expenseWatchTrailingPeriodCount),
    endExclusive: effectiveStart,
  );
}

const _filterTransactions = FilterTransactionsUseCase();

/// [rangeTransactions], narrowed by [filter]'s account/category/type
/// fields — reuses Transactions' own filtering usecase rather than
/// duplicating the same three `.where()` clauses; [filter]'s date range is
/// already applied by whichever provider fetched [rangeTransactions] in
/// the first place, so only a `TransactionFilter` carrying the
/// account/category/type fields is constructed here.
List<TransactionEntity> _applyAccountCategoryTypeFilter({
  required List<TransactionEntity> rangeTransactions,
  required ReportFilter filter,
  required List<AccountEntity> accounts,
  required List<CategoryEntity> categories,
}) {
  if (filter.accountId == null &&
      filter.categoryId == null &&
      filter.currencyCode == null &&
      filter.type == null) {
    return rangeTransactions;
  }
  final filtered = _filterTransactions(
    transactions: rangeTransactions,
    accounts: accounts,
    categories: categories,
    filter: TransactionFilter(
      accountId: filter.accountId,
      categoryId: filter.categoryId,
      type: filter.type,
    ),
  );
  if (filter.currencyCode == null) return filtered;
  final accountsById = {for (final account in accounts) account.id: account};
  return filtered
      .where(
        (transaction) =>
            accountsById[transaction.accountId]?.currencyCode ==
            filter.currencyCode,
      )
      .toList(growable: false);
}

const _buildMonthlyReport = BuildMonthlyReportUseCase();

/// The full report for [selectedReportMonthProvider] and
/// [reportFilterProvider], combining Accounts, Categories, Transactions,
/// and Budgets. Same combine-multiple-providers pattern as
/// `dashboardSummaryProvider` and `budgetProgressForMonthProvider` — see
/// that file for why this is a plain [Provider] rather than a
/// [StreamProvider].
final monthlyReportProvider = Provider<AsyncValue<MonthlyReport>>((ref) {
  final month = ref.watch(selectedReportMonthProvider);
  final filter = ref.watch(reportFilterProvider);
  final range = _effectiveRange(month, filter);

  final accountsAsync = ref.watch(accountsProvider(true));
  final categoriesAsync = ref.watch(
    categoriesProvider((type: null, includeArchived: true)),
  );
  final budgetsAsync = ref.watch(budgetsForMonthProvider(month));
  final monthTransactionsAsync = ref.watch(transactionsForMonthProvider(month));
  final rangeTransactionsAsync = filter.period != ReportPeriod.month
      ? ref.watch(
          transactionsInRangeProvider((
            start: range.start,
            endExclusive: range.endExclusive,
          )),
        )
      : monthTransactionsAsync;

  for (final async in [
    accountsAsync,
    categoriesAsync,
    budgetsAsync,
    monthTransactionsAsync,
    rangeTransactionsAsync,
  ]) {
    if (async.hasError) {
      return AsyncValue.error(async.error!, async.stackTrace!);
    }
  }

  final accounts = accountsAsync.value;
  final categories = categoriesAsync.value;
  final budgets = budgetsAsync.value;
  final monthTransactions = monthTransactionsAsync.value;
  final rangeTransactions = rangeTransactionsAsync.value;
  if (accounts == null ||
      categories == null ||
      budgets == null ||
      monthTransactions == null ||
      rangeTransactions == null) {
    return const AsyncValue.loading();
  }

  final filteredTransactions = _applyAccountCategoryTypeFilter(
    rangeTransactions: rangeTransactions,
    filter: filter,
    accounts: accounts,
    categories: categories,
  );

  return AsyncValue.data(
    _buildMonthlyReport(
      month: month,
      accounts: accounts,
      transactions: filteredTransactions,
      monthTransactionsForBudgets: monthTransactions,
      categories: categories,
      budgets: budgets,
    ),
  );
});

const _buildMonthlyTrend = BuildMonthlyTrendUseCase();

/// The [trendMonthCount]-month Income vs Expense trend ending at
/// [selectedReportMonthProvider], narrowed by [reportFilterProvider]'s
/// account/category/type fields (never its custom date range — a trend
/// is inherently a multi-month overview with its own window).
final monthlyTrendProvider = Provider<AsyncValue<List<MonthlyTrendPoint>>>((
  ref,
) {
  final endMonth = ref.watch(selectedReportMonthProvider);
  final filter = ref.watch(reportFilterProvider);
  final rangeStart = DateTime(
    endMonth.year,
    endMonth.month - (trendMonthCount - 1),
  );
  final rangeEnd = DateTime(endMonth.year, endMonth.month + 1);

  final accountsAsync = ref.watch(accountsProvider(true));
  final categoriesAsync = ref.watch(
    categoriesProvider((type: null, includeArchived: true)),
  );
  final transactionsAsync = ref.watch(
    transactionsInRangeProvider((start: rangeStart, endExclusive: rangeEnd)),
  );

  for (final async in [accountsAsync, categoriesAsync, transactionsAsync]) {
    if (async.hasError) {
      return AsyncValue.error(async.error!, async.stackTrace!);
    }
  }

  final accounts = accountsAsync.value;
  final categories = categoriesAsync.value;
  final transactions = transactionsAsync.value;
  if (accounts == null || categories == null || transactions == null) {
    return const AsyncValue.loading();
  }

  final filteredTransactions = _applyAccountCategoryTypeFilter(
    rangeTransactions: transactions,
    filter: filter,
    accounts: accounts,
    categories: categories,
  );

  return AsyncValue.data(
    _buildMonthlyTrend(
      endMonth: endMonth,
      monthCount: trendMonthCount,
      transactions: filteredTransactions,
      accounts: accounts,
    ),
  );
});

const _computeCategorySpending = ComputeCategorySpendingUseCase();

/// Total expense by currency for the period immediately preceding the
/// current one (same length, same account/category/type filter) — the
/// baseline `reportInsightsProvider` compares against for its
/// month-over-month figure.
final _previousPeriodExpenseProvider =
    Provider<AsyncValue<Map<String, double>>>((ref) {
      final month = ref.watch(selectedReportMonthProvider);
      final filter = ref.watch(reportFilterProvider);
      final range = _effectiveRange(month, filter);
      final length = range.endExclusive.difference(range.start);
      final previousStart = range.start.subtract(length);

      final accountsAsync = ref.watch(accountsProvider(true));
      final categoriesAsync = ref.watch(
        categoriesProvider((type: null, includeArchived: true)),
      );
      final transactionsAsync = ref.watch(
        transactionsInRangeProvider((
          start: previousStart,
          endExclusive: range.start,
        )),
      );

      for (final async in [accountsAsync, categoriesAsync, transactionsAsync]) {
        if (async.hasError) {
          return AsyncValue.error(async.error!, async.stackTrace!);
        }
      }

      final accounts = accountsAsync.value;
      final categories = categoriesAsync.value;
      final transactions = transactionsAsync.value;
      if (accounts == null || categories == null || transactions == null) {
        return const AsyncValue.loading();
      }

      final filteredTransactions = _applyAccountCategoryTypeFilter(
        rangeTransactions: transactions,
        filter: filter,
        accounts: accounts,
        categories: categories,
      );

      return AsyncValue.data(
        _computeCategorySpending(
          transactions: filteredTransactions,
          accounts: accounts,
          categories: categories,
        ).totalExpenseByCurrency,
      );
    });

const _computeReportInsights = ComputeReportInsightsUseCase();

/// Derived at-a-glance figures for [monthlyReportProvider]: savings rate,
/// average daily spend, top category, and month-over-month change.
/// Resolves to `null` while any dependency is loading or has failed —
/// callers should just omit the insights UI rather than block the rest of
/// Reports on it, same convention as `convertedMonthlyTotalsProvider`.
final reportInsightsProvider = Provider<ReportInsights?>((ref) {
  final report = ref.watch(monthlyReportProvider).value;
  if (report == null) return null;

  final month = ref.watch(selectedReportMonthProvider);
  final filter = ref.watch(reportFilterProvider);
  final range = _effectiveRange(month, filter);
  final periodDays = range.endExclusive.difference(range.start).inDays;

  final previousExpense = ref.watch(_previousPeriodExpenseProvider).value;
  if (previousExpense == null) return null;

  return _computeReportInsights(
    report: report,
    periodDays: periodDays,
    previousPeriodExpenseByCurrency: previousExpense,
  );
});

const _detectExpenseWatch = DetectExpenseWatchUseCase();

/// Spending patterns worth a user's attention for the current report —
/// see `DetectExpenseWatchUseCase`. Resolves to an empty list (never an
/// error state of its own) while any dependency is loading or failed, so
/// a slow trailing-window fetch never blocks the rest of Reports.
final expenseWatchProvider = Provider<List<ExpenseWatchItem>>((ref) {
  final report = ref.watch(monthlyReportProvider).value;
  if (report == null) return const [];

  final month = ref.watch(selectedReportMonthProvider);
  final filter = ref.watch(reportFilterProvider);
  final range = _effectiveRange(month, filter);
  final trailingRange = _trailingRange(
    month: month,
    filter: filter,
    effectiveStart: range.start,
  );

  final accountsAsync = ref.watch(accountsProvider(true));
  final categoriesAsync = ref.watch(
    categoriesProvider((type: null, includeArchived: true)),
  );
  final trailingTransactionsAsync = ref.watch(
    transactionsInRangeProvider((
      start: trailingRange.start,
      endExclusive: trailingRange.endExclusive,
    )),
  );

  final accounts = accountsAsync.value;
  final categories = categoriesAsync.value;
  final trailingTransactions = trailingTransactionsAsync.value;
  if (accounts == null || categories == null || trailingTransactions == null) {
    return const [];
  }

  final filteredTrailingTransactions = _applyAccountCategoryTypeFilter(
    rangeTransactions: trailingTransactions,
    filter: filter,
    accounts: accounts,
    categories: categories,
  );

  return _detectExpenseWatch(
    currentPeriodTransactions: report.transactions,
    trailingTransactions: filteredTrailingTransactions,
    trailingPeriodCount: expenseWatchTrailingPeriodCount,
    accounts: accounts,
    categories: categories,
  );
});

const _convertReportTotals = ConvertReportTotalsUseCase();

/// A single converted total across every currency in [monthlyReportProvider],
/// in the user's default currency — only meaningful (and only fetched) when
/// the report actually spans more than one currency; a single-currency
/// month would just duplicate its own `_MonthlySummaryCard`. Resolves to
/// `null` while loading, on a single-currency report, or if rates can't be
/// fetched — callers should treat all three the same way: don't show the
/// rollup card, never block the rest of Reports on it.
final convertedMonthlyTotalsProvider = Provider<ConvertedMonthlyTotals?>((ref) {
  final report = ref.watch(monthlyReportProvider).value;
  if (report == null || report.currencies.length < 2) return null;

  final targetCurrencyCode = ref
      .watch(userPreferencesProvider)
      .value
      ?.defaultCurrencyCode;
  if (targetCurrencyCode == null) return null;

  final ratesResult = ref.watch(latestExchangeRatesProvider).value;
  if (ratesResult == null) return null;

  return ratesResult.fold(
    (failure) => null,
    (rates) => _convertReportTotals(
      report: report,
      rates: rates,
      targetCurrencyCode: targetCurrencyCode,
    ),
  );
});
