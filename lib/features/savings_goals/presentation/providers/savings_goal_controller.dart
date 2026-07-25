import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/analytics_logger.dart';
import '../../domain/entities/goal_contribution_frequency.dart';
import '../../domain/entities/savings_goal_entity.dart';
import 'savings_goal_providers.dart';

/// Drives the loading/error state for every savings-goal *mutation*
/// (create, update, archive, unarchive, delete, contribute). The list/
/// progress itself comes from `savingsGoalProgressProvider`, which updates
/// on its own as Firestore changes.
class SavingsGoalController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Failure? get failure => switch (state) {
    AsyncError(:final error) when error is Failure => error,
    _ => null,
  };

  Future<bool> createGoal({
    required String name,
    required double targetAmount,
    required String accountId,
    required AppIconKey icon,
    required AppColorKey color,
    double? autoContributionAmount,
    GoalContributionFrequency? autoContributionFrequency,
  }) async {
    final success = await _run(
      () => ref
          .read(createSavingsGoalUseCaseProvider)
          .call(
            name: name,
            targetAmount: targetAmount,
            accountId: accountId,
            icon: icon,
            color: color,
            autoContributionAmount: autoContributionAmount,
            autoContributionFrequency: autoContributionFrequency,
          ),
    );
    if (success) {
      logAnalyticsEvent(
        () => ref.read(analyticsProvider),
        'savings_goal_created',
        {'has_auto_contribution': autoContributionAmount != null},
      );
    }
    return success;
  }

  Future<bool> updateGoal({
    required String id,
    required String name,
    required double targetAmount,
    required AppIconKey icon,
    required AppColorKey color,
    double? autoContributionAmount,
    GoalContributionFrequency? autoContributionFrequency,
  }) {
    return _run(
      () => ref
          .read(updateSavingsGoalUseCaseProvider)
          .call(
            id: id,
            name: name,
            targetAmount: targetAmount,
            icon: icon,
            color: color,
            autoContributionAmount: autoContributionAmount,
            autoContributionFrequency: autoContributionFrequency,
          ),
    );
  }

  Future<bool> archiveGoal(String id) {
    return _run(() => ref.read(archiveSavingsGoalUseCaseProvider).call(id));
  }

  Future<bool> unarchiveGoal(String id) {
    return _run(() => ref.read(unarchiveSavingsGoalUseCaseProvider).call(id));
  }

  Future<bool> deleteGoal(String id) {
    return _run(() => ref.read(deleteSavingsGoalUseCaseProvider).call(id));
  }

  Future<bool> contribute({
    required SavingsGoalEntity goal,
    required String sourceAccountId,
    required double amount,
    String note = '',
  }) {
    return _run(
      () => ref
          .read(contributeToGoalUseCaseProvider)
          .call(
            goal: goal,
            sourceAccountId: sourceAccountId,
            amount: amount,
            note: note,
          ),
    );
  }

  Future<bool> _run<R>(Future<Either<Failure, R>> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    // This controller is `.autoDispose` and, unlike the form screen (whose
    // Save button watches it for its loading state), the Detail screen's
    // archive/unarchive/delete menu actions never `ref.watch` it — so
    // nothing keeps it alive once the mutated goal's own data changes out
    // from under it (e.g. delete making `savingsGoalProgressByIdProvider`
    // resolve to null and swap the screen to an error view). If that
    // happens mid-flight, the controller is disposed before this
    // continuation resumes, and writing to `state` would throw ("Ref used
    // after dispose") instead of this ever returning true/false — which,
    // for delete, silently prevented the screen's `context.pop()` from
    // ever running. `action()`'s own result (already known at this point)
    // is still the correct success/failure to report either way; only the
    // now-moot `state` echo needs the `ref.mounted` guard.
    return result.match(
      (failure) {
        if (ref.mounted) state = AsyncError<void>(failure, StackTrace.current);
        return false;
      },
      (_) {
        if (ref.mounted) state = const AsyncData(null);
        return true;
      },
    );
  }
}

final savingsGoalControllerProvider =
    AsyncNotifierProvider.autoDispose<SavingsGoalController, void>(
      SavingsGoalController.new,
    );
