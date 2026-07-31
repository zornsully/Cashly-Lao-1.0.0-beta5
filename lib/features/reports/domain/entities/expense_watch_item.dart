import 'package:equatable/equatable.dart';

import '../../../categories/domain/entities/category_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

/// A spending pattern worth a user's attention, surfaced in Reports'
/// "Keep an Eye On" section. Purely on-device: computed from transactions
/// already streamed to the client, no server-side detection or new
/// backend — see `DetectExpenseWatchUseCase`.
///
/// A sealed class rather than one flat class with nullable fields: the
/// three variants genuinely have different shapes (one transaction vs.
/// several vs. a category-level rollup), and a sealed hierarchy lets the
/// presentation layer's `switch` be exhaustive instead of relying on a
/// runtime `reason` enum plus optional fields that only some reasons use.
sealed class ExpenseWatchItem extends Equatable {
  const ExpenseWatchItem();
}

/// A single transaction well above what this category typically costs.
class LargeExpenseWatchItem extends ExpenseWatchItem {
  const LargeExpenseWatchItem({
    required this.transaction,
    required this.category,
    required this.categoryAverageAmount,
  });

  final TransactionEntity transaction;
  final CategoryEntity category;

  /// The trailing average amount for this category, that [transaction]
  /// significantly exceeds.
  final double categoryAverageAmount;

  @override
  List<Object?> get props => [transaction, category, categoryAverageAmount];
}

/// Multiple transactions of the same (or near-identical) amount, in the
/// same category and account, within a short window — a common signature
/// of an accidental duplicate charge or an unwanted repeat subscription.
class RepeatedExpenseWatchItem extends ExpenseWatchItem {
  const RepeatedExpenseWatchItem({
    required this.transactions,
    required this.category,
    required this.amount,
  });

  /// Two or more transactions, oldest first.
  final List<TransactionEntity> transactions;
  final CategoryEntity category;

  /// The shared (or average, if not exactly equal) amount.
  final double amount;

  @override
  List<Object?> get props => [transactions, category, amount];
}

/// A category whose total spend this period has risen sharply against its
/// own trailing average — a trend-level flag, not tied to one transaction.
class RisingCategoryWatchItem extends ExpenseWatchItem {
  const RisingCategoryWatchItem({
    required this.category,
    required this.currencyCode,
    required this.currentAmount,
    required this.averageAmount,
    required this.percentIncrease,
  });

  final CategoryEntity category;
  final String currencyCode;
  final double currentAmount;
  final double averageAmount;

  /// Always positive — only a genuine increase is ever flagged.
  final double percentIncrease;

  @override
  List<Object?> get props => [
    category,
    currencyCode,
    currentAmount,
    averageAmount,
    percentIncrease,
  ];
}
