import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/budget/data/datasources/budget_remote_datasource.dart';
import 'package:cashly_lao/features/budget/data/models/budget_model.dart';
import 'package:cashly_lao/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockBudgetRemoteDataSource extends Mock
    implements BudgetRemoteDataSource {}

void main() {
  late _MockBudgetRemoteDataSource dataSource;
  late BudgetRepositoryImpl repository;

  setUp(() {
    dataSource = _MockBudgetRemoteDataSource();
    repository = BudgetRepositoryImpl(dataSource);
  });

  final budget = BudgetModel(
    id: 'food_2026-03',
    categoryId: 'food',
    month: DateTime(2026, 3),
    limitAmount: 500000,
    currencyCode: 'LAK',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('createBudget returns Right(budget) on success', () async {
    when(
      () => dataSource.createBudget(
        categoryId: any(named: 'categoryId'),
        month: any(named: 'month'),
        limitAmount: any(named: 'limitAmount'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) async => budget);

    final result = await repository.createBudget(
      categoryId: 'food',
      month: DateTime(2026, 3),
      limitAmount: 500000,
      currencyCode: 'LAK',
    );

    expect(result, Right(budget));
  });

  test('createBudget maps ServerException to Left(ServerFailure)', () async {
    when(
      () => dataSource.createBudget(
        categoryId: any(named: 'categoryId'),
        month: any(named: 'month'),
        limitAmount: any(named: 'limitAmount'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenThrow(
      const ServerException(
        'A budget already exists for this category this month.',
      ),
    );

    final result = await repository.createBudget(
      categoryId: 'food',
      month: DateTime(2026, 3),
      limitAmount: 500000,
      currencyCode: 'LAK',
    );

    expect(
      result,
      const Left<Failure, dynamic>(
        ServerFailure('A budget already exists for this category this month.'),
      ),
    );
  });

  test('deleteBudget returns Right(unit) on success', () async {
    when(
      () => dataSource.deleteBudget('food_2026-03'),
    ).thenAnswer((_) async {});

    final result = await repository.deleteBudget('food_2026-03');

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('watchBudgetsForMonth passes the month straight through', () {
    final month = DateTime(2026, 3);
    when(
      () => dataSource.watchBudgetsForMonth(month),
    ).thenAnswer((_) => Stream.value([budget]));

    expect(
      repository.watchBudgetsForMonth(month),
      emits(predicate<List<dynamic>>((b) => b.length == 1)),
    );
  });
}
