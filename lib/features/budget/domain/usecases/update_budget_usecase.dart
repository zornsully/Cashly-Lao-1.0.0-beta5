import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/budget_repository.dart';

class UpdateBudgetUseCase {
  const UpdateBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String id,
    required double limitAmount,
    required String currencyCode,
  }) {
    return _repository.updateBudget(
      id: id,
      limitAmount: limitAmount,
      currencyCode: currencyCode,
    );
  }
}
