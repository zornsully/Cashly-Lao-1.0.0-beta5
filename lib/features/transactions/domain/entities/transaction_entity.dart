import 'package:equatable/equatable.dart';

import 'transaction_type.dart';

class TransactionEntity extends Equatable {
  const TransactionEntity({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.date,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.toAccountId,
  });

  final String id;

  /// For income/expense, the account it affects. For a transfer, the
  /// *source* account money moves out of.
  final String accountId;

  /// Null for a transfer — transfers move money between the user's own
  /// accounts and aren't categorized as income or spending. Always
  /// non-null for income/expense.
  final String? categoryId;

  final TransactionType type;

  /// Only set (and required) when [type] is [TransactionType.transfer] —
  /// the destination account money moves into.
  final String? toAccountId;

  /// Always a positive magnitude — [type] determines whether it's added to
  /// or subtracted from the account's balance.
  final double amount;

  /// The date the transaction happened (user-selected), distinct from
  /// [createdAt] (when the record was saved).
  final DateTime date;

  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The signed effect on [accountId]'s balance: positive for income,
  /// negative for expense or transfer (a transfer's effect on
  /// [toAccountId] isn't represented by a single signed value).
  double get signedAmount => type == TransactionType.income ? amount : -amount;

  TransactionEntity copyWith({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    String? toAccountId,
    double? amount,
    DateTime? date,
    String? note,
  }) {
    return TransactionEntity(
      id: id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      toAccountId: toAccountId ?? this.toAccountId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    accountId,
    categoryId,
    type,
    toAccountId,
    amount,
    date,
    note,
    createdAt,
    updatedAt,
  ];
}
