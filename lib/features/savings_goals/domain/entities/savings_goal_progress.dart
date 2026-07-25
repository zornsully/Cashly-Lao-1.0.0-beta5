import 'package:equatable/equatable.dart';

import '../../../accounts/domain/entities/account_entity.dart';
import 'savings_goal_entity.dart';

/// A savings goal combined with the account whose live balance backs it —
/// computed on the fly, never stored. Progress is deliberately *not* a
/// separately summed ledger of contributions: it's just the linked
/// account's current balance, so it can never drift from what's actually
/// there if the user later spends out of that account for something
/// unrelated to the goal.
class SavingsGoalProgress extends Equatable {
  const SavingsGoalProgress({required this.goal, required this.account});

  final SavingsGoalEntity goal;
  final AccountEntity account;

  double get currentAmount => account.balance;

  /// Derived from the linked account, never stored on the goal itself — an
  /// account's currency can be edited after the fact, so caching a copy on
  /// the goal would risk the two silently disagreeing.
  String get currencyCode => account.currencyCode;

  double get remainingAmount {
    final remaining = goal.targetAmount - currentAmount;
    return remaining > 0 ? remaining : 0;
  }

  /// Can exceed 100 when overshot — callers rendering a progress bar/ring
  /// should clamp separately from the number they display as text (same
  /// convention as `BudgetProgress.percentageUsed`).
  double get percentageComplete {
    if (goal.targetAmount == 0) return 0;
    return (currentAmount / goal.targetAmount) * 100;
  }

  bool get isCompleted => currentAmount >= goal.targetAmount;

  @override
  List<Object?> get props => [goal, account];
}
