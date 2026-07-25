import '../../../accounts/domain/entities/account_entity.dart';
import '../entities/savings_goal_entity.dart';
import '../entities/savings_goal_progress.dart';

/// Pure aggregation logic for Savings Goal progress — no repository
/// dependency, same reasoning as Budget's `BuildBudgetProgressUseCase`:
/// there's no new data source to abstract over, just arithmetic combining
/// Goals' own data with Accounts' live balances.
class BuildSavingsGoalProgressUseCase {
  const BuildSavingsGoalProgressUseCase();

  List<SavingsGoalProgress> call({
    required List<SavingsGoalEntity> goals,
    required List<AccountEntity> accounts,
  }) {
    final accountsById = {
      for (final account in accounts) account.id: account,
    };

    return [
      for (final goal in goals)
        if (accountsById[goal.accountId] case final account?)
          SavingsGoalProgress(goal: goal, account: account),
    ];
  }
}
