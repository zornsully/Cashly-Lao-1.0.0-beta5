import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../entities/goal_contribution_frequency.dart';
import '../entities/savings_goal_entity.dart';
import '../repositories/savings_goal_repository.dart';

class CreateSavingsGoalUseCase {
  const CreateSavingsGoalUseCase(this._repository);

  final SavingsGoalRepository _repository;

  Future<Either<Failure, SavingsGoalEntity>> call({
    required String name,
    required double targetAmount,
    required String accountId,
    required AppIconKey icon,
    required AppColorKey color,
    double? autoContributionAmount,
    GoalContributionFrequency? autoContributionFrequency,
  }) {
    return _repository.createGoal(
      name: name,
      targetAmount: targetAmount,
      accountId: accountId,
      icon: icon,
      color: color,
      autoContributionAmount: autoContributionAmount,
      autoContributionFrequency: autoContributionFrequency,
    );
  }
}
