import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/budget_repository.dart';

class DeleteBudgetUseCase {
  const DeleteBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.deleteBudget(id);
  }
}
