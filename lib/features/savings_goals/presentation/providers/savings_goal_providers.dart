import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/datasources/savings_goal_remote_datasource.dart';
import '../../data/repositories/savings_goal_repository_impl.dart';
import '../../domain/entities/goal_completion_estimate.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/entities/savings_goal_progress.dart';
import '../../domain/repositories/savings_goal_repository.dart';
import '../../domain/usecases/archive_savings_goal_usecase.dart';
import '../../domain/usecases/build_savings_goal_progress_usecase.dart';
import '../../domain/usecases/contribute_to_goal_usecase.dart';
import '../../domain/usecases/create_savings_goal_usecase.dart';
import '../../domain/usecases/delete_savings_goal_usecase.dart';
import '../../domain/usecases/estimate_goal_completion_usecase.dart';
import '../../domain/usecases/unarchive_savings_goal_usecase.dart';
import '../../domain/usecases/update_savings_goal_usecase.dart';

final savingsGoalRemoteDataSourceProvider =
    Provider<SavingsGoalRemoteDataSource>((ref) {
      return FirestoreSavingsGoalRemoteDataSource(
        firestore: ref.watch(firestoreProvider),
        firebaseAuth: ref.watch(firebaseAuthProvider),
      );
    });

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  return SavingsGoalRepositoryImpl(
    ref.watch(savingsGoalRemoteDataSourceProvider),
  );
});

/// Every savings goal for the signed-in user, live-updating from Firestore.
/// `includeArchived: true` is used by the "show archived" toggle on the
/// goals list — same convention as `accountsProvider`.
final savingsGoalsProvider =
    StreamProvider.family<List<SavingsGoalEntity>, bool>((
      ref,
      includeArchived,
    ) {
      return ref
          .watch(savingsGoalRepositoryProvider)
          .watchGoals(includeArchived: includeArchived);
    });

/// Whether the goals list is currently showing archived goals too. Lives
/// per-screen (autoDispose) so it always resets to "hidden" when the user
/// leaves and comes back — same convention as `ShowArchivedAccounts`. This
/// is also the only way to reach an archived goal's Detail screen again
/// (e.g. to unarchive it), since the list is otherwise the sole entry point.
class ShowArchivedGoals extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final showArchivedGoalsProvider =
    NotifierProvider.autoDispose<ShowArchivedGoals, bool>(
      ShowArchivedGoals.new,
    );

const _buildSavingsGoalProgress = BuildSavingsGoalProgressUseCase();

/// Combines goals with Accounts into progress (current/remaining/complete)
/// per goal. Accounts are always fetched with `includeArchived: true` — a
/// goal whose linked account was later archived should still show its real
/// progress rather than disappear; the Goal screens flag that state
/// separately instead of hiding the goal.
final savingsGoalProgressProvider =
    Provider.family<AsyncValue<List<SavingsGoalProgress>>, bool>((
      ref,
      includeArchived,
    ) {
      final goalsAsync = ref.watch(savingsGoalsProvider(includeArchived));
      final accountsAsync = ref.watch(accountsProvider(true));

      for (final async in [goalsAsync, accountsAsync]) {
        if (async.hasError) {
          return AsyncValue.error(async.error!, async.stackTrace!);
        }
      }

      final goals = goalsAsync.value;
      final accounts = accountsAsync.value;
      if (goals == null || accounts == null) {
        return const AsyncValue.loading();
      }

      return AsyncValue.data(
        _buildSavingsGoalProgress(goals: goals, accounts: accounts),
      );
    });

SavingsGoalProgress? _findProgressById(
  List<SavingsGoalProgress> progressList,
  String goalId,
) {
  for (final progress in progressList) {
    if (progress.goal.id == goalId) return progress;
  }
  return null;
}

/// A single goal's progress by id, derived from
/// [savingsGoalProgressProvider] rather than opening a second Firestore
/// listener — includes archived goals, since Detail should work for one too
/// (reached from the list only via the "show archived" toggle).
final savingsGoalProgressByIdProvider =
    Provider.family<AsyncValue<SavingsGoalProgress?>, String>((ref, goalId) {
      return ref
          .watch(savingsGoalProgressProvider(true))
          .whenData((progressList) => _findProgressById(progressList, goalId));
    });

/// The date range shared by [goalAccountActivityProvider] and
/// [goalCompletionEstimateProvider] so they reuse one Firestore listener
/// instead of opening two — bounded to 12 months (or since the goal was
/// created, if more recent), since `watchTransactionsInRange` isn't
/// filtered server-side by account (see this feature's footprint notes).
///
/// Both endpoints are truncated to day granularity (never `DateTime.now()`
/// verbatim) so the returned record is `==`-stable across rebuilds within
/// the same day. `transactionsInRangeProvider` is a plain `StreamProvider
/// .family` (not `autoDispose`), keyed by this record — a millisecond-
/// precision `endExclusive` would mint a brand-new, never-disposed family
/// instance (and a brand-new Firestore listener) on every single rebuild
/// this provider triggers, leaking one live listener per emission instead
/// of reusing one, exactly the bug `report_providers.dart` avoids by
/// keying off the selected month rather than raw `now()`.
TransactionsRangeQuery _goalActivityRange(SavingsGoalEntity goal) {
  final today = DateTime.now();
  final startOfTomorrow = DateTime(today.year, today.month, today.day + 1);
  final twelveMonthsAgo = DateTime(today.year, today.month - 12, today.day);
  final start = goal.createdAt.isAfter(twelveMonthsAgo)
      ? goal.createdAt
      : twelveMonthsAgo;
  return (start: start, endExclusive: startOfTomorrow);
}

/// Every transaction touching the goal's linked account, as either
/// `accountId` or `toAccountId` — labeled "account activity" rather than
/// "contributions" because a direct income/expense transaction on that
/// account also moves the goal's progress (progress is the account's own
/// balance), so a transfers-only list would look inconsistent with a ring
/// that just changed with no matching row.
final goalAccountActivityProvider =
    Provider.family<AsyncValue<List<TransactionEntity>>, SavingsGoalEntity>((
      ref,
      goal,
    ) {
      return ref
          .watch(transactionsInRangeProvider(_goalActivityRange(goal)))
          .whenData(
            (transactions) => transactions
                .where(
                  (transaction) =>
                      transaction.accountId == goal.accountId ||
                      transaction.toAccountId == goal.accountId,
                )
                .toList(),
          );
    });

const _estimateGoalCompletion = EstimateGoalCompletionUseCase();

/// How soon [progress]'s goal is projected to be reached — see
/// `EstimateGoalCompletionUseCase` for the exact formula. Unlike
/// [goalAccountActivityProvider], only transfers *into* the account within
/// the trailing window count as "contribution pace."
final goalCompletionEstimateProvider =
    Provider.family<AsyncValue<GoalCompletionEstimate>, SavingsGoalProgress>((
      ref,
      progress,
    ) {
      final goal = progress.goal;
      return ref
          .watch(transactionsInRangeProvider(_goalActivityRange(goal)))
          .whenData((transactions) {
            final now = DateTime.now();
            final windowStart = now.subtract(
              const Duration(
                days: EstimateGoalCompletionUseCase.trailingWindowDays,
              ),
            );
            final recentContributions = transactions
                .where(
                  (transaction) =>
                      transaction.type == TransactionType.transfer &&
                      transaction.toAccountId == goal.accountId &&
                      !transaction.date.isBefore(windowStart),
                )
                .toList();
            return _estimateGoalCompletion(
              progress: progress,
              recentContributions: recentContributions,
              now: now,
            );
          });
    });

final createSavingsGoalUseCaseProvider = Provider<CreateSavingsGoalUseCase>((
  ref,
) {
  return CreateSavingsGoalUseCase(ref.watch(savingsGoalRepositoryProvider));
});

final updateSavingsGoalUseCaseProvider = Provider<UpdateSavingsGoalUseCase>((
  ref,
) {
  return UpdateSavingsGoalUseCase(ref.watch(savingsGoalRepositoryProvider));
});

final archiveSavingsGoalUseCaseProvider = Provider<ArchiveSavingsGoalUseCase>((
  ref,
) {
  return ArchiveSavingsGoalUseCase(ref.watch(savingsGoalRepositoryProvider));
});

final unarchiveSavingsGoalUseCaseProvider =
    Provider<UnarchiveSavingsGoalUseCase>((ref) {
      return UnarchiveSavingsGoalUseCase(
        ref.watch(savingsGoalRepositoryProvider),
      );
    });

final deleteSavingsGoalUseCaseProvider = Provider<DeleteSavingsGoalUseCase>((
  ref,
) {
  return DeleteSavingsGoalUseCase(ref.watch(savingsGoalRepositoryProvider));
});

final contributeToGoalUseCaseProvider = Provider<ContributeToGoalUseCase>((
  ref,
) {
  return ContributeToGoalUseCase(
    createTransaction: ref.watch(createTransactionUseCaseProvider),
    goalRepository: ref.watch(savingsGoalRepositoryProvider),
  );
});
