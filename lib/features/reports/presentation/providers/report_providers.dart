import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../exchange_rates/presentation/providers/exchange_rate_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/converted_monthly_totals.dart';
import '../../domain/entities/monthly_report.dart';
import '../../domain/entities/monthly_trend_point.dart';
import '../../domain/usecases/build_monthly_report_usecase.dart';
import '../../domain/usecases/build_monthly_trend_usecase.dart';
import '../../domain/usecases/convert_report_totals_usecase.dart';
import '../../domain/usecases/export_report_to_csv_usecase.dart';

final exportReportToCsvUseCaseProvider = Provider<ExportReportToCsvUseCase>((
  ref,
) {
  return const ExportReportToCsvUseCase();
});

/// How many months (inclusive of the selected one) the Income vs Expense
/// trend chart covers.
const int trendMonthCount = 6;

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
}

final selectedReportMonthProvider =
    NotifierProvider<SelectedReportMonth, DateTime>(SelectedReportMonth.new);

const _buildMonthlyReport = BuildMonthlyReportUseCase();

/// The full single-month report for [selectedReportMonthProvider],
/// combining Accounts, Categories, Transactions, and Budgets. Same
/// combine-multiple-providers pattern as `dashboardSummaryProvider` and
/// `budgetProgressForMonthProvider`.
final monthlyReportProvider = Provider<AsyncValue<MonthlyReport>>((ref) {
  final month = ref.watch(selectedReportMonthProvider);
  final accountsAsync = ref.watch(accountsProvider(true));
  final transactionsAsync = ref.watch(transactionsForMonthProvider(month));
  final categoriesAsync = ref.watch(
    categoriesProvider((type: null, includeArchived: true)),
  );
  final budgetsAsync = ref.watch(budgetsForMonthProvider(month));

  for (final async in [
    accountsAsync,
    transactionsAsync,
    categoriesAsync,
    budgetsAsync,
  ]) {
    if (async.hasError) {
      return AsyncValue.error(async.error!, async.stackTrace!);
    }
  }

  final accounts = accountsAsync.value;
  final transactions = transactionsAsync.value;
  final categories = categoriesAsync.value;
  final budgets = budgetsAsync.value;
  if (accounts == null ||
      transactions == null ||
      categories == null ||
      budgets == null) {
    return const AsyncValue.loading();
  }

  return AsyncValue.data(
    _buildMonthlyReport(
      month: month,
      accounts: accounts,
      monthTransactions: transactions,
      categories: categories,
      budgets: budgets,
    ),
  );
});

const _buildMonthlyTrend = BuildMonthlyTrendUseCase();

/// The [trendMonthCount]-month Income vs Expense trend ending at
/// [selectedReportMonthProvider].
final monthlyTrendProvider = Provider<AsyncValue<List<MonthlyTrendPoint>>>((
  ref,
) {
  final endMonth = ref.watch(selectedReportMonthProvider);
  final rangeStart = DateTime(
    endMonth.year,
    endMonth.month - (trendMonthCount - 1),
  );
  final rangeEnd = DateTime(endMonth.year, endMonth.month + 1);

  final accountsAsync = ref.watch(accountsProvider(true));
  final transactionsAsync = ref.watch(
    transactionsInRangeProvider((start: rangeStart, endExclusive: rangeEnd)),
  );

  if (accountsAsync.hasError) {
    return AsyncValue.error(accountsAsync.error!, accountsAsync.stackTrace!);
  }
  if (transactionsAsync.hasError) {
    return AsyncValue.error(
      transactionsAsync.error!,
      transactionsAsync.stackTrace!,
    );
  }

  final accounts = accountsAsync.value;
  final transactions = transactionsAsync.value;
  if (accounts == null || transactions == null) {
    return const AsyncValue.loading();
  }

  return AsyncValue.data(
    _buildMonthlyTrend(
      endMonth: endMonth,
      monthCount: trendMonthCount,
      transactions: transactions,
      accounts: accounts,
    ),
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
