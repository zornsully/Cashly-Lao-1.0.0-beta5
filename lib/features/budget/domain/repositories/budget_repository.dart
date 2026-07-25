import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/budget_entity.dart';

abstract interface class BudgetRepository {
  /// Emits every budget for the calendar month of [month] (only year/month
  /// matter), updating in real time as Firestore's copy changes.
  Stream<List<BudgetEntity>> watchBudgetsForMonth(DateTime month);

  /// Fails if a budget already exists for this [categoryId] and [month] —
  /// there can only be one; use [updateBudget] to change its limit.
  Future<Either<Failure, BudgetEntity>> createBudget({
    required String categoryId,
    required DateTime month,
    required double limitAmount,
    required String currencyCode,
  });

  /// Only the limit and currency can change — a budget's category and
  /// month are fixed at creation (see [createBudget]).
  Future<Either<Failure, Unit>> updateBudget({
    required String id,
    required double limitAmount,
    required String currencyCode,
  });

  Future<Either<Failure, Unit>> deleteBudget(String id);
}
