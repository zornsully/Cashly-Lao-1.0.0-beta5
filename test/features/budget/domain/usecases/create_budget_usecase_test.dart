import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/budget/domain/entities/budget_entity.dart';
import 'package:cashly_lao/features/budget/domain/repositories/budget_repository.dart';
import 'package:cashly_lao/features/budget/domain/usecases/create_budget_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late _MockBudgetRepository repository;
  late CreateBudgetUseCase useCase;

  setUp(() {
    repository = _MockBudgetRepository();
    useCase = CreateBudgetUseCase(repository);
  });

  final budget = BudgetEntity(
    id: 'food_2026-03',
    categoryId: 'food',
    month: DateTime(2026, 3),
    limitAmount: 500000,
    currencyCode: 'LAK',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('delegates to the repository and returns the created budget', () async {
    when(
      () => repository.createBudget(
        categoryId: 'food',
        month: DateTime(2026, 3),
        limitAmount: 500000,
        currencyCode: 'LAK',
      ),
    ).thenAnswer((_) async => Right(budget));

    final result = await useCase(
      categoryId: 'food',
      month: DateTime(2026, 3),
      limitAmount: 500000,
      currencyCode: 'LAK',
    );

    expect(result, Right<Failure, BudgetEntity>(budget));
  });
}
