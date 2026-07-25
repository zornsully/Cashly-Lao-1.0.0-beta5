import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../entities/category_type.dart';
import '../repositories/category_repository.dart';

class UpdateCategoryUseCase {
  const UpdateCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String id,
    required String name,
    required CategoryType type,
    required AppIconKey icon,
    required AppColorKey color,
  }) {
    return _repository.updateCategory(
      id: id,
      name: name,
      type: type,
      icon: icon,
      color: color,
    );
  }
}
