import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/savings_goals/data/models/savings_goal_model.dart';
import 'package:cashly_lao/features/savings_goals/domain/entities/goal_contribution_frequency.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'fromFirestore maps a stored document back to a SavingsGoalModel',
    () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('savingsGoals').doc('goal-1');

      await docRef.set({
        'name': 'Vacation',
        'targetAmount': 5000000.0,
        'accountId': 'acc-1',
        'icon': AppIconKey.savings.name,
        'color': AppColorKey.emerald.name,
        'isArchived': false,
        'autoContributionAmount': 200000.0,
        'autoContributionFrequency': 'monthly',
        'lastContributionAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
      });

      final snapshot = await docRef.get();
      final model = SavingsGoalModel.fromFirestore(snapshot);

      expect(model.id, 'goal-1');
      expect(model.name, 'Vacation');
      expect(model.targetAmount, 5000000.0);
      expect(model.accountId, 'acc-1');
      expect(model.icon, AppIconKey.savings);
      expect(model.color, AppColorKey.emerald);
      expect(model.isArchived, isFalse);
      expect(model.autoContributionAmount, 200000.0);
      expect(
        model.autoContributionFrequency,
        GoalContributionFrequency.monthly,
      );
      expect(model.lastContributionAt, DateTime(2026, 3, 1));
    },
  );

  test(
    'fromFirestore maps the 0/"" sentinel to null auto-contribution fields',
    () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('savingsGoals').doc('goal-2');

      await docRef.set({
        'name': 'Emergency Fund',
        'targetAmount': 1000000.0,
        'accountId': 'acc-2',
        'icon': AppIconKey.savings.name,
        'color': AppColorKey.blue.name,
        'isArchived': false,
        'autoContributionAmount': 0.0,
        'autoContributionFrequency': '',
        'lastContributionAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
      });

      final snapshot = await docRef.get();
      final model = SavingsGoalModel.fromFirestore(snapshot);

      expect(model.autoContributionAmount, isNull);
      expect(model.autoContributionFrequency, isNull);
    },
  );
}
