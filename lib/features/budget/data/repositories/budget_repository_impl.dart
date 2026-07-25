import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_remote_datasource.dart';

class BudgetRepositoryImpl with RepositoryGuard implements BudgetRepository {
  const BudgetRepositoryImpl(this._remoteDataSource);

  final BudgetRemoteDataSource _remoteDataSource;

  @override
  Stream<List<BudgetEntity>> watchBudgetsForMonth(DateTime month) {
    return _remoteDataSource.watchBudgetsForMonth(month);
  }

  @override
  Future<Either<Failure, BudgetEntity>> createBudget({
    required String categoryId,
    required DateTime month,
    required double limitAmount,
    required String currencyCode,
  }) {
    return guard(
      () => _remoteDataSource.createBudget(
        categoryId: categoryId,
        month: month,
        limitAmount: limitAmount,
        currencyCode: currencyCode,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> updateBudget({
    required String id,
    required double limitAmount,
    required String currencyCode,
  }) {
    return guardUnit(
      () => _remoteDataSource.updateBudget(
        id: id,
        limitAmount: limitAmount,
        currencyCode: currencyCode,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> deleteBudget(String id) {
    return guardUnit(() => _remoteDataSource.deleteBudget(id));
  }
}
