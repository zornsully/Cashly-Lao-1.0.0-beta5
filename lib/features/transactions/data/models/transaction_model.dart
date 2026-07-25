import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.accountId,
    required super.type,
    required super.amount,
    required super.date,
    required super.note,
    required super.createdAt,
    required super.updatedAt,
    super.categoryId,
    super.toAccountId,
  });

  factory TransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    // Stored as '' rather than an absent field for whichever of
    // categoryId/toAccountId doesn't apply to this transaction's type (see
    // firestore.rules) — normalized back to null here so the rest of the
    // app can treat "no category"/"not a transfer" as a real null instead
    // of a magic empty string.
    final categoryId = data['categoryId'] as String? ?? '';
    final toAccountId = data['toAccountId'] as String? ?? '';
    return TransactionModel(
      id: doc.id,
      accountId: data['accountId'] as String,
      categoryId: categoryId.isEmpty ? null : categoryId,
      type: TransactionType.values.byName(data['type'] as String),
      toAccountId: toAccountId.isEmpty ? null : toAccountId,
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
