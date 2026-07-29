import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/savings_goals/domain/entities/savings_goal_entity.dart';
import 'package:cashly_lao/features/savings_goals/domain/usecases/build_savings_goal_progress_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = BuildSavingsGoalProgressUseCase();

  AccountEntity account({
    required String id,
    required double balance,
    String currencyCode = 'LAK',
  }) {
    return AccountEntity(
      id: id,
      name: 'Account $id',
      type: AccountType.savings,
      balance: balance,
      currencyCode: currencyCode,
      icon: AppIconKey.savings,
      color: AppColorKey.emerald,
      isArchived: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  SavingsGoalEntity goal({
    required String id,
    required String accountId,
    required double targetAmount,
  }) {
    return SavingsGoalEntity(
      id: id,
      name: 'Goal $id',
      targetAmount: targetAmount,
      accountId: accountId,
      icon: AppIconKey.savings,
      color: AppColorKey.emerald,
      isArchived: false,
      lastContributionAt: DateTime(2026),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  test("progress reflects the linked account's live balance", () {
    final accounts = [account(id: 'acc-1', balance: 2000000)];
    final goals = [
      goal(id: 'goal-1', accountId: 'acc-1', targetAmount: 5000000),
    ];

    final result = useCase(goals: goals, accounts: accounts);

    expect(result, hasLength(1));
    expect(result.single.currentAmount, 2000000);
    expect(result.single.remainingAmount, 3000000);
    expect(result.single.percentageComplete, 40);
    expect(result.single.isCompleted, isFalse);
  });

  test('isCompleted is true once the account balance reaches the target', () {
    final accounts = [account(id: 'acc-1', balance: 5000000)];
    final goals = [
      goal(id: 'goal-1', accountId: 'acc-1', targetAmount: 5000000),
    ];

    final result = useCase(goals: goals, accounts: accounts);

    expect(result.single.isCompleted, isTrue);
    expect(result.single.remainingAmount, 0);
  });

  test('remainingAmount never goes negative even when overshot', () {
    final accounts = [account(id: 'acc-1', balance: 6000000)];
    final goals = [
      goal(id: 'goal-1', accountId: 'acc-1', targetAmount: 5000000),
    ];

    final result = useCase(goals: goals, accounts: accounts);

    expect(result.single.remainingAmount, 0);
    expect(result.single.percentageComplete, 120);
  });

  test('excludes goals whose linked account no longer exists', () {
    final goals = [
      goal(id: 'goal-1', accountId: 'deleted-acc', targetAmount: 5000000),
    ];

    final result = useCase(goals: goals, accounts: const []);

    expect(result, isEmpty);
  });

  test('currencyCode is derived from the account, not stored on the goal', () {
    final accounts = [account(id: 'acc-1', balance: 100, currencyCode: 'USD')];
    final goals = [goal(id: 'goal-1', accountId: 'acc-1', targetAmount: 1000)];

    final result = useCase(goals: goals, accounts: accounts);

    expect(result.single.currencyCode, 'USD');
  });
}
