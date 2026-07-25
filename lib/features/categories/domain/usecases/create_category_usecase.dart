import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../entities/category_entity.dart';
import '../entities/category_type.dart';
import '../repositories/category_repository.dart';

class CreateCategoryUseCase {
  const CreateCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, CategoryEntity>> call({
    required String name,
    required CategoryType type,
    required AppIconKey icon,
    required AppColorKey color,
  }) {
    return _repository.createCategory(
      name: name,
      type: type,
      icon: icon,
      color: color,
    );
  }
}
