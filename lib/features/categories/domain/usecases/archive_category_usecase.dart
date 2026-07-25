import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/category_repository.dart';

class ArchiveCategoryUseCase {
  const ArchiveCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.archiveCategory(id);
  }
}
