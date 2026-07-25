import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/usecases/build_dashboard_summary_usecase.dart';

/// The Dashboard always summarizes the real current calendar month,
/// independent of whatever month the user has navigated to on the
/// Transactions tab (that's a separate, user-driven browsing state).
final _dashboardMonthProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

const _buildDashboardSummary = BuildDashboardSummaryUseCase();

/// Combines Accounts, Categories, and this month's Transactions into a
/// single [DashboardSummary], recomputing whenever any of them changes.
/// A plain [Provider] (not [StreamProvider]) because the combination itself
/// is synchronous — the async part is entirely in the three dependencies.
final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final accountsAsync = ref.watch(accountsProvider(false));
  final month = ref.watch(_dashboardMonthProvider);
  final transactionsAsync = ref.watch(transactionsForMonthProvider(month));
  final categoriesAsync = ref.watch(
    categoriesProvider((type: null, includeArchived: false)),
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
  if (categoriesAsync.hasError) {
    return AsyncValue.error(
      categoriesAsync.error!,
      categoriesAsync.stackTrace!,
    );
  }

  final accounts = accountsAsync.value;
  final transactions = transactionsAsync.value;
  final categories = categoriesAsync.value;
  if (accounts == null || transactions == null || categories == null) {
    return const AsyncValue.loading();
  }

  return AsyncValue.data(
    _buildDashboardSummary(
      accounts: accounts,
      monthTransactions: transactions,
      categories: categories,
    ),
  );
});
