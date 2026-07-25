import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/savings_goal_repository.dart';

class ArchiveSavingsGoalUseCase {
  const ArchiveSavingsGoalUseCase(this._repository);

  final SavingsGoalRepository _repository;

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.archiveGoal(id);
  }
}
