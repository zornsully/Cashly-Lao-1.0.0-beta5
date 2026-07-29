import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/features/savings_goals/data/datasources/savings_goal_remote_datasource.dart';
import 'package:cashly_lao/features/savings_goals/domain/entities/goal_contribution_frequency.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseAuth firebaseAuth;
  late FirestoreSavingsGoalRemoteDataSource dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    firebaseAuth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('uid-1');
    when(() => firebaseAuth.currentUser).thenReturn(user);
    dataSource = FirestoreSavingsGoalRemoteDataSource(
      firestore: firestore,
      firebaseAuth: firebaseAuth,
    );
  });

  test('createGoal writes under users/{uid}/savingsGoals', () async {
    final created = await dataSource.createGoal(
      name: 'Vacation',
      targetAmount: 5000000,
      accountId: 'acc-1',
      icon: AppIconKey.savings,
      color: AppColorKey.emerald,
    );

    expect(created.name, 'Vacation');
    expect(created.accountId, 'acc-1');
    expect(created.autoContributionAmount, isNull);
    expect(created.autoContributionFrequency, isNull);

    final doc = await firestore
        .collection('users')
        .doc('uid-1')
        .collection('savingsGoals')
        .doc(created.id)
        .get();
    expect(doc.exists, isTrue);
  });

  test('createGoal stores an auto-contribution schedule when given', () async {
    final created = await dataSource.createGoal(
      name: 'Vacation',
      targetAmount: 5000000,
      accountId: 'acc-1',
      icon: AppIconKey.savings,
      color: AppColorKey.emerald,
      autoContributionAmount: 200000,
      autoContributionFrequency: GoalContributionFrequency.monthly,
    );

    expect(created.autoContributionAmount, 200000);
    expect(
      created.autoContributionFrequency,
      GoalContributionFrequency.monthly,
    );
  });

  test(
    'createGoal throws when the account already backs an active goal',
    () async {
      await dataSource.createGoal(
        name: 'Vacation',
        targetAmount: 5000000,
        accountId: 'acc-1',
        icon: AppIconKey.savings,
        color: AppColorKey.emerald,
      );

      expect(
        () => dataSource.createGoal(
          name: 'Emergency Fund',
          targetAmount: 1000000,
          accountId: 'acc-1',
          icon: AppIconKey.savings,
          color: AppColorKey.blue,
        ),
        throwsA(isA<ServerException>()),
      );
    },
  );

  test(
    "createGoal succeeds when the account's only prior goal is archived",
    () async {
      final first = await dataSource.createGoal(
        name: 'Vacation',
        targetAmount: 5000000,
        accountId: 'acc-1',
        icon: AppIconKey.savings,
        color: AppColorKey.emerald,
      );
      await dataSource.archiveGoal(first.id);

      final second = await dataSource.createGoal(
        name: 'Emergency Fund',
        targetAmount: 1000000,
        accountId: 'acc-1',
        icon: AppIconKey.savings,
        color: AppColorKey.blue,
      );

      expect(second.accountId, 'acc-1');
    },
  );

  test('updateGoal changes fields without touching accountId', () async {
    final created = await dataSource.createGoal(
      name: 'Vacation',
      targetAmount: 5000000,
      accountId: 'acc-1',
      icon: AppIconKey.savings,
      color: AppColorKey.emerald,
    );

    await dataSource.updateGoal(
      id: created.id,
      name: 'Big Vacation',
      targetAmount: 6000000,
      icon: AppIconKey.travel,
      color: AppColorKey.blue,
      autoContributionAmount: 250000,
      autoContributionFrequency: GoalContributionFrequency.weekly,
    );

    final updated = await dataSource.watchGoals().first;
    expect(updated.single.name, 'Big Vacation');
    expect(updated.single.targetAmount, 6000000);
    expect(updated.single.accountId, 'acc-1');
    expect(updated.single.autoContributionAmount, 250000);
    expect(
      updated.single.autoContributionFrequency,
      GoalContributionFrequency.weekly,
    );
  });

  test(
    'updateGoal can clear a previously-set auto-contribution schedule',
    () async {
      final created = await dataSource.createGoal(
        name: 'Vacation',
        targetAmount: 5000000,
        accountId: 'acc-1',
        icon: AppIconKey.savings,
        color: AppColorKey.emerald,
        autoContributionAmount: 250000,
        autoContributionFrequency: GoalContributionFrequency.weekly,
      );

      await dataSource.updateGoal(
        id: created.id,
        name: 'Vacation',
        targetAmount: 5000000,
        icon: AppIconKey.savings,
        color: AppColorKey.emerald,
      );

      final updated = await dataSource.watchGoals().first;
      expect(updated.single.autoContributionAmount, isNull);
      expect(updated.single.autoContributionFrequency, isNull);
    },
  );

  test('archiveGoal then unarchiveGoal toggles isArchived', () async {
    final created = await dataSource.createGoal(
      name: 'Vacation',
      targetAmount: 5000000,
      accountId: 'acc-1',
      icon: AppIconKey.savings,
      color: AppColorKey.emerald,
    );

    await dataSource.archiveGoal(created.id);
    var goals = await dataSource.watchGoals().first;
    expect(goals.single.isArchived, isTrue);

    await dataSource.unarchiveGoal(created.id);
    goals = await dataSource.watchGoals().first;
    expect(goals.single.isArchived, isFalse);
  });

  test('deleteGoal removes the document', () async {
    final created = await dataSource.createGoal(
      name: 'Vacation',
      targetAmount: 5000000,
      accountId: 'acc-1',
      icon: AppIconKey.savings,
      color: AppColorKey.emerald,
    );

    await dataSource.deleteGoal(created.id);

    final remaining = await dataSource.watchGoals().first;
    expect(remaining, isEmpty);
  });

  test('recordContribution updates lastContributionAt', () async {
    final created = await dataSource.createGoal(
      name: 'Vacation',
      targetAmount: 5000000,
      accountId: 'acc-1',
      icon: AppIconKey.savings,
      color: AppColorKey.emerald,
    );
    final contributedAt = DateTime(2026, 5, 1);

    await dataSource.recordContribution(
      goalId: created.id,
      contributedAt: contributedAt,
    );

    final goals = await dataSource.watchGoals().first;
    expect(goals.single.lastContributionAt, contributedAt);
  });

  test('throws AuthException when there is no signed-in user', () async {
    when(() => firebaseAuth.currentUser).thenReturn(null);

    expect(
      () => dataSource.createGoal(
        name: 'Vacation',
        targetAmount: 5000000,
        accountId: 'acc-1',
        icon: AppIconKey.savings,
        color: AppColorKey.emerald,
      ),
      throwsA(isA<AuthException>()),
    );
  });
}
