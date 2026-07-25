import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/goal_contribution_frequency.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/repositories/savings_goal_repository.dart';
import '../datasources/savings_goal_remote_datasource.dart';

class SavingsGoalRepositoryImpl
    with RepositoryGuard
    implements SavingsGoalRepository {
  const SavingsGoalRepositoryImpl(this._remoteDataSource);

  final SavingsGoalRemoteDataSource _remoteDataSource;

  @override
  Stream<List<SavingsGoalEntity>> watchGoals({bool includeArchived = false}) {
    return _remoteDataSource.watchGoals().map(
      (goals) => includeArchived
          ? goals
          : goals.where((goal) => !goal.isArchived).toList(),
    );
  }

  @override
  Future<Either<Failure, SavingsGoalEntity>> createGoal({
    required String name,
    required double targetAmount,
    required String accountId,
    required AppIconKey icon,
    required AppColorKey color,
    double? autoContributionAmount,
    GoalContributionFrequency? autoContributionFrequency,
  }) {
    return guard(
      () => _remoteDataSource.createGoal(
        name: name,
        targetAmount: targetAmount,
        accountId: accountId,
        icon: icon,
        color: color,
        autoContributionAmount: autoContributionAmount,
        autoContributionFrequency: autoContributionFrequency,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> updateGoal({
    required String id,
    required String name,
    required double targetAmount,
    required AppIconKey icon,
    required AppColorKey color,
    double? autoContributionAmount,
    GoalContributionFrequency? autoContributionFrequency,
  }) {
    return guardUnit(
      () => _remoteDataSource.updateGoal(
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

  @override
  Future<Either<Failure, Unit>> archiveGoal(String id) {
    return guardUnit(() => _remoteDataSource.archiveGoal(id));
  }

  @override
  Future<Either<Failure, Unit>> unarchiveGoal(String id) {
    return guardUnit(() => _remoteDataSource.unarchiveGoal(id));
  }

  @override
  Future<Either<Failure, Unit>> deleteGoal(String id) {
    return guardUnit(() => _remoteDataSource.deleteGoal(id));
  }

  @override
  Future<Either<Failure, Unit>> recordContribution({
    required String goalId,
    required DateTime contributedAt,
  }) {
    return guardUnit(
      () => _remoteDataSource.recordContribution(
        goalId: goalId,
        contributedAt: contributedAt,
      ),
    );
  }
}
