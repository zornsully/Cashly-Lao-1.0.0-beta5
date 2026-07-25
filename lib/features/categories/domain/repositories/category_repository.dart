import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../entities/category_entity.dart';
import '../entities/category_type.dart';

abstract interface class CategoryRepository {
  /// Emits the user's categories every time Firestore's copy changes,
  /// optionally scoped to one [type] and/or including archived ones.
  Stream<List<CategoryEntity>> watchCategories({
    CategoryType? type,
    bool includeArchived = false,
  });

  /// Seeds the curated default categories the very first time this user
  /// reaches Categories, and is a no-op on every call after that (idempotent
  /// — safe to call on every login).
  Future<Either<Failure, Unit>> ensureDefaultCategories();

  Future<Either<Failure, CategoryEntity>> createCategory({
    required String name,
    required CategoryType type,
    required AppIconKey icon,
    required AppColorKey color,
  });

  Future<Either<Failure, Unit>> updateCategory({
    required String id,
    required String name,
    required CategoryType type,
    required AppIconKey icon,
    required AppColorKey color,
  });

  Future<Either<Failure, Unit>> archiveCategory(String id);

  Future<Either<Failure, Unit>> unarchiveCategory(String id);

  /// Fails for default categories — see [CategoryEntity.isDefault].
  Future<Either<Failure, Unit>> deleteCategory(String id);

  /// Persists a new relative order for [orderedIds] (same [CategoryType]),
  /// lowest index first.
  Future<Either<Failure, Unit>> reorderCategories(List<String> orderedIds);
}
