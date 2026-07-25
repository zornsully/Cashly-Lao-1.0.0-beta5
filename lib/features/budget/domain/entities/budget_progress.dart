import 'package:equatable/equatable.dart';

import '../../../categories/domain/entities/category_entity.dart';
import 'budget_entity.dart';

/// A budget combined with how much has actually been spent against it —
/// computed on the fly from Transactions, never stored.
class BudgetProgress extends Equatable {
  const BudgetProgress({
    required this.budget,
    required this.category,
    required this.spentAmount,
  });

  final BudgetEntity budget;
  final CategoryEntity category;
  final double spentAmount;

  double get remainingAmount => budget.limitAmount - spentAmount;

  /// Can exceed 100 when overspent — callers that render a progress bar
  /// should clamp separately from the number they display as text.
  double get percentageUsed {
    if (budget.limitAmount == 0) return 0;
    return (spentAmount / budget.limitAmount) * 100;
  }

  bool get isOverspent => spentAmount > budget.limitAmount;

  @override
  List<Object?> get props => [budget, category, spentAmount];
}
