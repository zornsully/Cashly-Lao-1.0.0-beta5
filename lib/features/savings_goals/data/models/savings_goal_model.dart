import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../domain/entities/goal_contribution_frequency.dart';
import '../../domain/entities/savings_goal_entity.dart';

class SavingsGoalModel extends SavingsGoalEntity {
  const SavingsGoalModel({
    required super.id,
    required super.name,
    required super.targetAmount,
    required super.accountId,
    required super.icon,
    required super.color,
    required super.isArchived,
    required super.lastContributionAt,
    required super.createdAt,
    required super.updatedAt,
    super.autoContributionAmount,
    super.autoContributionFrequency,
  });

  factory SavingsGoalModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    // Stored as 0 / '' rather than an absent field for "no auto-contribution
    // schedule" (see firestore.rules) — normalized back to null here, same
    // sentinel convention as TransactionModel's categoryId/toAccountId.
    final rawAutoContributionAmount = (data['autoContributionAmount'] as num?)
        ?.toDouble();
    final autoContributionFrequencyRaw =
        data['autoContributionFrequency'] as String? ?? '';
    return SavingsGoalModel(
      id: doc.id,
      name: data['name'] as String,
      targetAmount: (data['targetAmount'] as num).toDouble(),
      accountId: data['accountId'] as String,
      icon: AppIconKey.values.byName(data['icon'] as String),
      color: AppColorKey.values.byName(data['color'] as String),
      isArchived: data['isArchived'] as bool? ?? false,
      autoContributionAmount:
          (rawAutoContributionAmount != null && rawAutoContributionAmount > 0)
          ? rawAutoContributionAmount
          : null,
      autoContributionFrequency: autoContributionFrequencyRaw.isEmpty
          ? null
          : GoalContributionFrequency.values.byName(
              autoContributionFrequencyRaw,
            ),
      lastContributionAt:
          (data['lastContributionAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
