import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/analytics_logger.dart';
import '../../domain/entities/category_type.dart';
import 'category_providers.dart';

/// Drives the loading/error state for every category *mutation* (create,
/// update, archive, unarchive, delete, reorder). The list itself comes
/// from [categoriesProvider], which updates on its own as Firestore
/// changes.
class CategoryController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Failure? get failure => switch (state) {
    AsyncError(:final error) when error is Failure => error,
    _ => null,
  };

  Future<bool> createCategory({
    required String name,
    required CategoryType type,
    required AppIconKey icon,
    required AppColorKey color,
  }) async {
    final success = await _run(
      () => ref
          .read(createCategoryUseCaseProvider)
          .call(name: name, type: type, icon: icon, color: color),
    );
    if (success) {
      logAnalyticsEvent(() => ref.read(analyticsProvider), 'category_created', {
        'category_type': type.name,
      });
    }
    return success;
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    required CategoryType type,
    required AppIconKey icon,
    required AppColorKey color,
  }) {
    return _run(
      () => ref
          .read(updateCategoryUseCaseProvider)
          .call(id: id, name: name, type: type, icon: icon, color: color),
    );
  }

  Future<bool> archiveCategory(String id) {
    return _run(() => ref.read(archiveCategoryUseCaseProvider).call(id));
  }

  Future<bool> unarchiveCategory(String id) {
    return _run(() => ref.read(unarchiveCategoryUseCaseProvider).call(id));
  }

  Future<bool> deleteCategory(String id) {
    return _run(() => ref.read(deleteCategoryUseCaseProvider).call(id));
  }

  Future<bool> reorderCategories(List<String> orderedIds) {
    return _run(
      () => ref.read(reorderCategoriesUseCaseProvider).call(orderedIds),
    );
  }

  Future<bool> _run<R>(Future<Either<Failure, R>> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    return result.match(
      (failure) {
        state = AsyncError<void>(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}

final categoryControllerProvider =
    AsyncNotifierProvider.autoDispose<CategoryController, void>(
      CategoryController.new,
    );
