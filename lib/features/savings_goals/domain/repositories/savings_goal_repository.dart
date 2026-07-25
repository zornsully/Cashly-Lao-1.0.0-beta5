import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../entities/goal_contribution_frequency.dart';
import '../entities/savings_goal_entity.dart';

abstract interface class SavingsGoalRepository {
  /// Emits every savings goal, updating in real time as Firestore's copy
  /// changes. Archived goals are filtered out unless [includeArchived] is
  /// true (same convention as `AccountRepository.watchAccounts`).
  Stream<List<SavingsGoalEntity>> watchGoals({bool includeArchived = false});

  /// Fails if [accountId] already backs another *active* goal — each
  /// account backs at most one active goal, since a goal's progress is
  /// simply that account's own balance (see `SavingsGoalProgress`).
  Future<Either<Failure, SavingsGoalEntity>> createGoal({
    required String name,
    required double targetAmount,
    required String accountId,
    required AppIconKey icon,
    required AppColorKey color,
    double? autoContributionAmount,
    GoalContributionFrequency? autoContributionFrequency,
  });

  /// The linked account can't be changed after creation (see [createGoal]).
  Future<Either<Failure, Unit>> updateGoal({
    required String id,
    required String name,
    required double targetAmount,
    required AppIconKey icon,
    required AppColorKey color,
    double? autoContributionAmount,
    GoalContributionFrequency? autoContributionFrequency,
  });

  Future<Either<Failure, Unit>> archiveGoal(String id);

  Future<Either<Failure, Unit>> unarchiveGoal(String id);

  Future<Either<Failure, Unit>> deleteGoal(String id);

  /// Records that a contribution just landed, so the next auto-contribution
  /// reminder is computed from this moment rather than the goal's original
  /// creation date. Never touches money — see `ContributeToGoalUseCase`,
  /// which calls this only after the actual transfer already succeeded.
  Future<Either<Failure, Unit>> recordContribution({
    required String goalId,
    required DateTime contributedAt,
  });
}
