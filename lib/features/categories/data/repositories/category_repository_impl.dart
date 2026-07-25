import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/category_type.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';

class CategoryRepositoryImpl
    with RepositoryGuard
    implements CategoryRepository {
  const CategoryRepositoryImpl(this._remoteDataSource);

  final CategoryRemoteDataSource _remoteDataSource;

  @override
  Stream<List<CategoryEntity>> watchCategories({
    CategoryType? type,
    bool includeArchived = false,
  }) {
    return _remoteDataSource.watchCategories().map(
      (categories) => categories
          .where((c) => type == null || c.type == type)
          .where((c) => includeArchived || !c.isArchived)
          .toList(),
    );
  }

  @override
  Future<Either<Failure, Unit>> ensureDefaultCategories() {
    return guardUnit(_remoteDataSource.ensureDefaultCategories);
  }

  @override
  Future<Either<Failure, CategoryEntity>> createCategory({
    required String name,
    required CategoryType type,
    required AppIconKey icon,
    required AppColorKey color,
  }) {
    return guard(
      () => _remoteDataSource.createCategory(
        name: name,
        type: type,
        icon: icon,
        color: color,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> updateCategory({
    required String id,
    required String name,
    required CategoryType type,
    required AppIconKey icon,
    required AppColorKey color,
  }) {
    return guardUnit(
      () => _remoteDataSource.updateCategory(
        id: id,
        name: name,
        type: type,
        icon: icon,
        color: color,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> archiveCategory(String id) {
    return guardUnit(() => _remoteDataSource.archiveCategory(id));
  }

  @override
  Future<Either<Failure, Unit>> unarchiveCategory(String id) {
    return guardUnit(() => _remoteDataSource.unarchiveCategory(id));
  }

  @override
  Future<Either<Failure, Unit>> deleteCategory(String id) {
    return guardUnit(() => _remoteDataSource.deleteCategory(id));
  }

  @override
  Future<Either<Failure, Unit>> reorderCategories(List<String> orderedIds) {
    return guardUnit(() => _remoteDataSource.reorderCategories(orderedIds));
  }
}
