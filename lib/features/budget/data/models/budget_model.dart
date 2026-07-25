import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/budget_entity.dart';

class BudgetModel extends BudgetEntity {
  const BudgetModel({
    required super.id,
    required super.categoryId,
    required super.month,
    required super.limitAmount,
    required super.currencyCode,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BudgetModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return BudgetModel(
      id: doc.id,
      categoryId: data['categoryId'] as String,
      month: (data['month'] as Timestamp).toDate(),
      limitAmount: (data['limitAmount'] as num).toDouble(),
      currencyCode: data['currencyCode'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
