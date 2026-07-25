import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/transaction_type.dart';
import '../repositories/transaction_repository.dart';

class UpdateTransactionUseCase {
  const UpdateTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String id,
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  }) {
    return _repository.updateTransaction(
      id: id,
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
