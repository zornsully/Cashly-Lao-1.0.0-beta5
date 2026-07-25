import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:cashly_lao/features/categories/data/models/category_model.dart';
import 'package:cashly_lao/features/categories/data/repositories/category_repository_impl.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryRemoteDataSource extends Mock
    implements CategoryRemoteDataSource {}

void main() {
  late _MockCategoryRemoteDataSource dataSource;
  late CategoryRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(AppIconKey.other);
    registerFallbackValue(AppColorKey.grey);
  });

  setUp(() {
    dataSource = _MockCategoryRemoteDataSource();
    repository = CategoryRepositoryImpl(dataSource);
  });

  CategoryModel category({
    required String id,
    required CategoryType type,
    required bool isArchived,
  }) {
    return CategoryModel(
      id: id,
      name: 'Category $id',
      type: type,
      icon: AppIconKey.other,
      color: AppColorKey.grey,
      isDefault: false,
      isArchived: isArchived,
      sortOrder: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  group('watchCategories', () {
    final all = [
      category(id: '1', type: CategoryType.income, isArchived: false),
      category(id: '2', type: CategoryType.expense, isArchived: false),
      category(id: '3', type: CategoryType.expense, isArchived: true),
    ];

    test('filters archived out by default', () {
      when(
        () => dataSource.watchCategories(),
      ).thenAnswer((_) => Stream.value(all));

      expect(
        repository.watchCategories(),
        emits(predicate<List<dynamic>>((c) => c.length == 2)),
      );
    });

    test('filters by type when provided', () {
      when(
        () => dataSource.watchCategories(),
      ).thenAnswer((_) => Stream.value(all));

      expect(
        repository.watchCategories(type: CategoryType.expense),
        emits(
          predicate<List<dynamic>>((c) => c.length == 1 && c.first.id == '2'),
        ),
      );
    });

    test('includes archived when includeArchived is true', () {
      when(
        () => dataSource.watchCategories(),
      ).thenAnswer((_) => Stream.value(all));

      expect(
        repository.watchCategories(
          type: CategoryType.expense,
          includeArchived: true,
        ),
        emits(predicate<List<dynamic>>((c) => c.length == 2)),
      );
    });
  });

  test('deleteCategory maps ServerException to Left(ServerFailure)', () async {
    when(
      () => dataSource.deleteCategory('1'),
    ).thenThrow(const ServerException("Default categories can't be deleted."));

    final result = await repository.deleteCategory('1');

    expect(
      result,
      const Left<Failure, Unit>(
        ServerFailure("Default categories can't be deleted."),
      ),
    );
  });

  test('reorderCategories returns Right(unit) on success', () async {
    when(
      () => dataSource.reorderCategories(['1', '2']),
    ).thenAnswer((_) async {});

    final result = await repository.reorderCategories(['1', '2']);

    expect(result, const Right<Failure, Unit>(unit));
  });
}
