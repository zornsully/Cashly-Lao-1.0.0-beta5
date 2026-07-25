import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/datasources/budget_remote_datasource.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/budget_progress.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/usecases/build_budget_progress_usecase.dart';
import '../../domain/usecases/create_budget_usecase.dart';
import '../../domain/usecases/delete_budget_usecase.dart';
import '../../domain/usecases/update_budget_usecase.dart';

final budgetRemoteDataSourceProvider = Provider<BudgetRemoteDataSource>((ref) {
  return FirestoreBudgetRemoteDataSource(
    firestore: ref.watch(firestoreProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(ref.watch(budgetRemoteDataSourceProvider));
});

/// The month currently shown by the Budget list, truncated to its first
/// day. Persists for the app session so switching tabs and coming back
/// doesn't reset the user's place — mirrors Transactions'
/// `selectedTransactionsMonthProvider`, but budgets are browsed
/// independently (a user might set next month's budget in advance).
class SelectedBudgetMonth extends Notifier<DateTime> {
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

final selectedBudgetMonthProvider =
    NotifierProvider<SelectedBudgetMonth, DateTime>(SelectedBudgetMonth.new);

/// Budgets for an arbitrary month, updating in real time as Firestore
/// changes. Shared by anything that needs a specific month's budgets
/// independent of the Budget tab's own browsing state (Dashboard's
/// `budgetProgressForMonthProvider(currentMonth)` call keys off this the
/// same way `transactionsForMonthProvider` is shared with Dashboard).
final budgetsForMonthProvider =
    StreamProvider.family<List<BudgetEntity>, DateTime>((ref, month) {
      return ref.watch(budgetRepositoryProvider).watchBudgetsForMonth(month);
    });

const _buildBudgetProgress = BuildBudgetProgressUseCase();

/// Combines [month]'s Budgets with Accounts, Categories, and Transactions
/// into progress (spent/remaining/overspent) per budget. Same
/// combine-multiple-providers pattern as `dashboardSummaryProvider` — see
/// that file for why this is a plain [Provider] rather than a
/// [StreamProvider].
final budgetProgressForMonthProvider =
    Provider.family<AsyncValue<List<BudgetProgress>>, DateTime>((ref, month) {
      final budgetsAsync = ref.watch(budgetsForMonthProvider(month));
      final transactionsAsync = ref.watch(transactionsForMonthProvider(month));
      final accountsAsync = ref.watch(accountsProvider(true));
      final categoriesAsync = ref.watch(
        categoriesProvider((type: null, includeArchived: true)),
      );

      for (final async in [
        budgetsAsync,
        transactionsAsync,
        accountsAsync,
        categoriesAsync,
      ]) {
        if (async.hasError) {
          return AsyncValue.error(async.error!, async.stackTrace!);
        }
      }

      final budgets = budgetsAsync.value;
      final transactions = transactionsAsync.value;
      final accounts = accountsAsync.value;
      final categories = categoriesAsync.value;
      if (budgets == null ||
          transactions == null ||
          accounts == null ||
          categories == null) {
        return const AsyncValue.loading();
      }

      return AsyncValue.data(
        _buildBudgetProgress(
          budgets: budgets,
          monthTransactions: transactions,
          accounts: accounts,
          categories: categories,
        ),
      );
    });

/// Progress for whatever month the Budget tab is currently browsing.
final budgetProgressProvider = Provider<AsyncValue<List<BudgetProgress>>>((
  ref,
) {
  final month = ref.watch(selectedBudgetMonthProvider);
  return ref.watch(budgetProgressForMonthProvider(month));
});

final createBudgetUseCaseProvider = Provider<CreateBudgetUseCase>((ref) {
  return CreateBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

final updateBudgetUseCaseProvider = Provider<UpdateBudgetUseCase>((ref) {
  return UpdateBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

final deleteBudgetUseCaseProvider = Provider<DeleteBudgetUseCase>((ref) {
  return DeleteBudgetUseCase(ref.watch(budgetRepositoryProvider));
});
