import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/transaction_entity.dart';
import '../entities/transaction_type.dart';

abstract interface class TransactionRepository {
  /// Emits every transaction dated within the calendar month of [month]
  /// (only the year/month matter), newest first, updating in real time as
  /// Firestore's copy changes.
  Stream<List<TransactionEntity>> watchTransactionsForMonth(DateTime month);

  /// Emits every transaction with `date` in `[start, endExclusive)`, newest
  /// first, updating in real time as Firestore's copy changes. Used by
  /// Reports for multi-month trends; [watchTransactionsForMonth] is a
  /// single-month convenience over the same query.
  Stream<List<TransactionEntity>> watchTransactionsInRange({
    required DateTime start,
    required DateTime endExclusive,
  });

  /// Creates the transaction and atomically applies its effect to the
  /// account(s) involved: just [accountId] for income/expense, or both
  /// [accountId] (debited) and [toAccountId] (credited) for a transfer.
  Future<Either<Failure, TransactionEntity>> createTransaction({
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  });

  /// Updates the transaction and atomically reconciles every account
  /// balance affected by either the old or new shape (which may involve a
  /// different account, a different type, or a different number of
  /// accounts than before).
  Future<Either<Failure, Unit>> updateTransaction({
    required String id,
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  });

  /// Deletes the transaction and atomically reverses its effect on every
  /// account it touched.
  Future<Either<Failure, Unit>> deleteTransaction(String id);
}
