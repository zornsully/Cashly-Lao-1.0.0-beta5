import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/category_repository.dart';

class EnsureDefaultCategoriesUseCase {
  const EnsureDefaultCategoriesUseCase(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, Unit>> call() {
    return _repository.ensureDefaultCategories();
  }
}
