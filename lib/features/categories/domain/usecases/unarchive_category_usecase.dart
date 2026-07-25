import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/category_repository.dart';

class UnarchiveCategoryUseCase {
  const UnarchiveCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.unarchiveCategory(id);
  }
}
