import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/category_type.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/archive_category_usecase.dart';
import '../../domain/usecases/create_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/ensure_default_categories_usecase.dart';
import '../../domain/usecases/reorder_categories_usecase.dart';
import '../../domain/usecases/unarchive_category_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';

final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>((
  ref,
) {
  return FirestoreCategoryRemoteDataSource(
    firestore: ref.watch(firestoreProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(categoryRemoteDataSourceProvider));
});

/// Query parameters for [categoriesProvider]. A record gets structural
/// equality for free, which is exactly what a Riverpod `family` key needs.
typedef CategoriesQuery = ({CategoryType? type, bool includeArchived});

final categoriesProvider =
    StreamProvider.family<List<CategoryEntity>, CategoriesQuery>((ref, query) {
      return ref
          .watch(categoryRepositoryProvider)
          .watchCategories(
            type: query.type,
            includeArchived: query.includeArchived,
          );
    });

/// Whether the categories list is currently showing archived categories
/// too. Lives per-screen (autoDispose) so it resets to "hidden" each time
/// the user returns to the Categories tab.
class ShowArchivedCategories extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final showArchivedCategoriesProvider =
    NotifierProvider.autoDispose<ShowArchivedCategories, bool>(
      ShowArchivedCategories.new,
    );

/// Seeds the curated default categories the first time an authenticated
/// user reaches Categories, and is a safe no-op afterward. Re-runs
/// automatically whenever the signed-in user changes (login/logout/switch
/// account within the same app session), since it watches
/// [authStateChangesProvider].
final ensureDefaultCategoriesProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return;

  final result = await ref.read(ensureDefaultCategoriesUseCaseProvider).call();

  // Swallowed on failure: seeding is best-effort convenience, not a
  // blocking requirement — the user can always add categories manually,
  // and this provider has no BuildContext to show an error with anyway.
  result.match((_) {}, (_) {});
});

final ensureDefaultCategoriesUseCaseProvider =
    Provider<EnsureDefaultCategoriesUseCase>((ref) {
      return EnsureDefaultCategoriesUseCase(
        ref.watch(categoryRepositoryProvider),
      );
    });

final createCategoryUseCaseProvider = Provider<CreateCategoryUseCase>((ref) {
  return CreateCategoryUseCase(ref.watch(categoryRepositoryProvider));
});

final updateCategoryUseCaseProvider = Provider<UpdateCategoryUseCase>((ref) {
  return UpdateCategoryUseCase(ref.watch(categoryRepositoryProvider));
});

final archiveCategoryUseCaseProvider = Provider<ArchiveCategoryUseCase>((ref) {
  return ArchiveCategoryUseCase(ref.watch(categoryRepositoryProvider));
});

final unarchiveCategoryUseCaseProvider = Provider<UnarchiveCategoryUseCase>((
  ref,
) {
  return UnarchiveCategoryUseCase(ref.watch(categoryRepositoryProvider));
});

final deleteCategoryUseCaseProvider = Provider<DeleteCategoryUseCase>((ref) {
  return DeleteCategoryUseCase(ref.watch(categoryRepositoryProvider));
});

final reorderCategoriesUseCaseProvider = Provider<ReorderCategoriesUseCase>((
  ref,
) {
  return ReorderCategoriesUseCase(ref.watch(categoryRepositoryProvider));
});
