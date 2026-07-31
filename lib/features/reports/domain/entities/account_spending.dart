import 'package:equatable/equatable.dart';

import '../../../accounts/domain/entities/account_entity.dart';

/// How much was spent from one account during the summarized period, and
/// what share of that currency's total expense it represents. Same shape
/// as `CategorySpending`, one level up (by account instead of category).
class AccountSpending extends Equatable {
  const AccountSpending({
    required this.account,
    required this.amount,
    required this.percentageOfExpense,
  });

  final AccountEntity account;
  final double amount;

  /// 0-100. 0 when the currency's total expense for the period is 0.
  final double percentageOfExpense;

  @override
  List<Object?> get props => [account, amount, percentageOfExpense];
}
