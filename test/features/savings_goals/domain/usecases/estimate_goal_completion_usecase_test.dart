import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/savings_goals/domain/entities/goal_completion_estimate.dart';
import 'package:cashly_lao/features/savings_goals/domain/entities/goal_contribution_frequency.dart';
import 'package:cashly_lao/features/savings_goals/domain/entities/savings_goal_entity.dart';
import 'package:cashly_lao/features/savings_goals/domain/entities/savings_goal_progress.dart';
import 'package:cashly_lao/features/savings_goals/domain/usecases/estimate_goal_completion_usecase.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = EstimateGoalCompletionUseCase();
  final now = DateTime(2026, 6, 1);

  AccountEntity account({required double balance}) {
    return AccountEntity(
      id: 'acc-1',
      name: 'Vacation Fund',
      type: AccountType.savings,
      balance: balance,
      currencyCode: 'LAK',
      icon: AppIconKey.savings,
      color: AppColorKey.emerald,
      isArchived: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  SavingsGoalEntity goal({
    required double targetAmount,
    double? autoContributionAmount,
    GoalContributionFrequency? autoContributionFrequency,
    DateTime? lastContributionAt,
  }) {
    return SavingsGoalEntity(
      id: 'goal-1',
      name: 'Vacation',
      targetAmount: targetAmount,
      accountId: 'acc-1',
      icon: AppIconKey.savings,
      color: AppColorKey.emerald,
      isArchived: false,
      autoContributionAmount: autoContributionAmount,
      autoContributionFrequency: autoContributionFrequency,
      lastContributionAt: lastContributionAt ?? DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  test(
    'alreadyCompleted when the account balance already meets the target',
    () {
      final progress = SavingsGoalProgress(
        goal: goal(targetAmount: 1000000),
        account: account(balance: 1000000),
      );

      final result = useCase(
        progress: progress,
        recentContributions: const [],
        now: now,
      );

      expect(result.basis, GoalCompletionEstimateBasis.alreadyCompleted);
      expect(result.estimatedDate, isNull);
    },
  );

  test('scheduled projects forward from the auto-contribution schedule', () {
    final progress = SavingsGoalProgress(
      goal: goal(
        targetAmount: 1000000,
        autoContributionAmount: 250000,
        autoContributionFrequency: GoalContributionFrequency.monthly,
        lastContributionAt: DateTime(2026, 5, 1),
      ),
      account: account(balance: 0),
    );

    final result = useCase(
      progress: progress,
      recentContributions: const [],
      now: now,
    );

    expect(result.basis, GoalCompletionEstimateBasis.scheduled);
    // now (2026-06-01) is after lastContributionAt, so the schedule
    // projects forward from now: 4 monthly periods of 250,000 each to
    // cover the remaining 1,000,000 -> 07-01, 08-01, 09-01, 10-01.
    expect(result.estimatedDate, DateTime(2026, 10, 1));
  });

  test('trailingAverage projects from the recent pace of transfers in when '
      'no schedule is set', () {
    final progress = SavingsGoalProgress(
      goal: goal(targetAmount: 1000000),
      account: account(balance: 400000),
    );
    final recentContributions = [
      TransactionEntity(
        id: 'txn-1',
        accountId: 'source-acc',
        toAccountId: 'acc-1',
        type: TransactionType.transfer,
        amount: 200000,
        date: DateTime(2026, 5, 2),
        note: '',
        createdAt: DateTime(2026, 5, 2),
        updatedAt: DateTime(2026, 5, 2),
      ),
      TransactionEntity(
        id: 'txn-2',
        accountId: 'source-acc',
        toAccountId: 'acc-1',
        type: TransactionType.transfer,
        amount: 200000,
        date: DateTime(2026, 5, 12),
        note: '',
        createdAt: DateTime(2026, 5, 12),
        updatedAt: DateTime(2026, 5, 12),
      ),
    ];

    final result = useCase(
      progress: progress,
      recentContributions: recentContributions,
      now: now,
    );

    expect(result.basis, GoalCompletionEstimateBasis.trailingAverage);
    expect(result.estimatedDate, isNotNull);
    expect(result.estimatedDate!.isAfter(now), isTrue);
  });

  test(
    'insufficientData when there is no schedule and no contribution history',
    () {
      final progress = SavingsGoalProgress(
        goal: goal(targetAmount: 1000000),
        account: account(balance: 0),
      );

      final result = useCase(
        progress: progress,
        recentContributions: const [],
        now: now,
      );

      expect(result.basis, GoalCompletionEstimateBasis.insufficientData);
      expect(result.estimatedDate, isNull);
    },
  );

  test('insufficientData when a scheduled projection would exceed the max '
      'period cap, rather than looping unbounded or overflowing a date', () {
    final progress = SavingsGoalProgress(
      goal: goal(
        targetAmount: 1000000000,
        autoContributionAmount: 1,
        autoContributionFrequency: GoalContributionFrequency.monthly,
      ),
      account: account(balance: 0),
    );

    final result = useCase(
      progress: progress,
      recentContributions: const [],
      now: now,
    );

    expect(result.basis, GoalCompletionEstimateBasis.insufficientData);
  });

  test('insufficientData when a trailing-average projection would land too '
      'far in the future', () {
    final progress = SavingsGoalProgress(
      goal: goal(targetAmount: 1000000000),
      account: account(balance: 0),
    );
    final recentContributions = [
      TransactionEntity(
        id: 'txn-1',
        accountId: 'source-acc',
        toAccountId: 'acc-1',
        type: TransactionType.transfer,
        amount: 1,
        date: DateTime(2026, 5, 2),
        note: '',
        createdAt: DateTime(2026, 5, 2),
        updatedAt: DateTime(2026, 5, 2),
      ),
    ];

    final result = useCase(
      progress: progress,
      recentContributions: recentContributions,
      now: now,
    );

    expect(result.basis, GoalCompletionEstimateBasis.insufficientData);
  });
}
