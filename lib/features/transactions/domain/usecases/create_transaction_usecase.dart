import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/transaction_entity.dart';
import '../entities/transaction_type.dart';
import '../repositories/transaction_repository.dart';

class CreateTransactionUseCase {
  const CreateTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  Future<Either<Failure, TransactionEntity>> call({
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  }) {
    return _repository.createTransaction(
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      toAccountId: toAccountId,
      amount: amount,
      date: date,
      note: note,
    );
  }
}
