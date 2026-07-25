import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../entities/goal_contribution_frequency.dart';
import '../repositories/savings_goal_repository.dart';

class UpdateSavingsGoalUseCase {
  const UpdateSavingsGoalUseCase(this._repository);

  final SavingsGoalRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String id,
    required String name,
    required double targetAmount,
    required AppIconKey icon,
    required AppColorKey color,
    double? autoContributionAmount,
    GoalContributionFrequency? autoContributionFrequency,
  }) {
    return _repository.updateGoal(
      id: id,
      name: name,
      targetAmount: targetAmount,
      icon: icon,
      color: color,
      autoContributionAmount: autoContributionAmount,
      autoContributionFrequency: autoContributionFrequency,
    );
  }
}
