import 'package:equatable/equatable.dart';

import '../../../accounts/domain/entities/account_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import 'category_spending.dart';

/// A computed snapshot of the signed-in user's finances for the current
/// month. Every total is keyed by currency code rather than collapsed into
/// one number — Cashly accounts can each use a different currency (Sprint
/// 2), and silently summing across currencies would produce a number that
/// doesn't correspond to any real amount of money.
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.accounts,
    required this.categories,
    required this.totalBalanceByCurrency,
    required this.totalIncomeByCurrency,
    required this.totalExpenseByCurrency,
    required this.recentTransactions,
    required this.spendingByCategory,
  });

  /// Active (non-archived) accounts, for the "Account Balances" section
  /// and for resolving each recent transaction's account.
  final List<AccountEntity> accounts;

  /// Active (non-archived) categories of both types, for resolving each
  /// recent transaction's category (income and expense alike —
  /// [spendingByCategory] only covers expense categories that had
  /// activity this month).
  final List<CategoryEntity> categories;

  final Map<String, double> totalBalanceByCurrency;
  final Map<String, double> totalIncomeByCurrency;
  final Map<String, double> totalExpenseByCurrency;

  /// The most recent transactions this month, newest first.
  final List<TransactionEntity> recentTransactions;

  /// Expense categories this month, grouped by currency and sorted by
  /// amount descending within each currency.
  final Map<String, List<CategorySpending>> spendingByCategory;

  bool get hasAnyAccounts => accounts.isNotEmpty;

  bool get hasAnyTransactionsThisMonth => recentTransactions.isNotEmpty;

  @override
  List<Object?> get props => [
    accounts,
    categories,
    totalBalanceByCurrency,
    totalIncomeByCurrency,
    totalExpenseByCurrency,
    recentTransactions,
    spendingByCategory,
  ];
}
