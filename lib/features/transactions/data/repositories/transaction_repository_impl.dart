import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';

class TransactionRepositoryImpl
    with RepositoryGuard
    implements TransactionRepository {
  const TransactionRepositoryImpl(this._remoteDataSource);

  final TransactionRemoteDataSource _remoteDataSource;

  @override
  Stream<List<TransactionEntity>> watchTransactionsForMonth(DateTime month) {
    return _remoteDataSource.watchTransactionsForMonth(month);
  }

  @override
  Stream<List<TransactionEntity>> watchTransactionsInRange({
    required DateTime start,
    required DateTime endExclusive,
  }) {
    return _remoteDataSource.watchTransactionsInRange(
      start: start,
      endExclusive: endExclusive,
    );
  }

  @override
  Future<Either<Failure, TransactionEntity>> createTransaction({
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  }) {
    return guard(
      () => _remoteDataSource.createTransaction(
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        toAccountId: toAccountId,
        amount: amount,
        date: date,
        note: note,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> updateTransaction({
    required String id,
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  }) {
    return guardUnit(
      () => _remoteDataSource.updateTransaction(
        id: id,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        toAccountId: toAccountId,
        amount: amount,
        date: date,
        note: note,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> deleteTransaction(String id) {
    return guardUnit(() => _remoteDataSource.deleteTransaction(id));
  }
}
