import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/category_repository.dart';

class ReorderCategoriesUseCase {
  const ReorderCategoriesUseCase(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, Unit>> call(List<String> orderedIds) {
    return _repository.reorderCategories(orderedIds);
  }
}
