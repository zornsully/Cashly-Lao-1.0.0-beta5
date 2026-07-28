import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../../transactions/domain/usecases/create_transaction_usecase.dart';
import '../entities/savings_goal_entity.dart';
import '../repositories/savings_goal_repository.dart';

/// Making a contribution — manual, or confirming a due auto-contribution
/// prompt — is just an ordinary transfer into the goal's linked account.
/// This reuses the transactions feature's existing atomic balance
/// machinery completely unchanged; the only thing specific to a *goal*
/// here is which account to transfer into, and remembering when it happened
/// so the next reminder is computed correctly.
class ContributeToGoalUseCase {
  const ContributeToGoalUseCase({
    required this._createTransaction,
    required this._goalRepository,
  });

  final CreateTransactionUseCase _createTransaction;
  final SavingsGoalRepository _goalRepository;

  Future<Either<Failure, TransactionEntity>> call({
    required SavingsGoalEntity goal,
    required String sourceAccountId,
    required double amount,
    String note = '',
  }) async {
    final result = await _createTransaction(
      accountId: sourceAccountId,
      type: TransactionType.transfer,
      toAccountId: goal.accountId,
      amount: amount,
      date: DateTime.now(),
      note: note,
    );

    // Best-effort only: this timestamp only affects when the next
    // auto-contribution reminder fires, never money correctness, so a
    // failure here must never undo or mask a transfer that already
    // succeeded.
    await result.match((_) async {}, (_) async {
      await _goalRepository.recordContribution(
        goalId: goal.id,
        contributedAt: DateTime.now(),
      );
    });

    return result;
  }
}
