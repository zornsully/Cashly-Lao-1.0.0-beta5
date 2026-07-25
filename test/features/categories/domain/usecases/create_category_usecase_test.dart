import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/categories/domain/repositories/category_repository.dart';
import 'package:cashly_lao/features/categories/domain/usecases/create_category_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late _MockCategoryRepository repository;
  late CreateCategoryUseCase useCase;

  setUp(() {
    repository = _MockCategoryRepository();
    useCase = CreateCategoryUseCase(repository);
  });

  final category = CategoryEntity(
    id: 'cat-1',
    name: 'Freelance',
    type: CategoryType.income,
    icon: AppIconKey.work,
    color: AppColorKey.green,
    isDefault: false,
    isArchived: false,
    sortOrder: 0,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test(
    'delegates to the repository and returns the created category',
    () async {
      when(
        () => repository.createCategory(
          name: 'Freelance',
          type: CategoryType.income,
          icon: AppIconKey.work,
          color: AppColorKey.green,
        ),
      ).thenAnswer((_) async => Right(category));

      final result = await useCase(
        name: 'Freelance',
        type: CategoryType.income,
        icon: AppIconKey.work,
        color: AppColorKey.green,
      );

      expect(result, Right<Failure, CategoryEntity>(category));
    },
  );
}
