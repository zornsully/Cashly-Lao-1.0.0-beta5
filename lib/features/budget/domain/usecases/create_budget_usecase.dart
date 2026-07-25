import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/budget_entity.dart';
import '../repositories/budget_repository.dart';

class CreateBudgetUseCase {
  const CreateBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<Either<Failure, BudgetEntity>> call({
    required String categoryId,
    required DateTime month,
    required double limitAmount,
    required String currencyCode,
  }) {
    return _repository.createBudget(
      categoryId: categoryId,
      month: month,
      limitAmount: limitAmount,
      currencyCode: currencyCode,
    );
  }
}
