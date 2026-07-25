import 'package:equatable/equatable.dart';

import '../../../categories/domain/entities/category_entity.dart';

/// How much was spent in one category during the summarized month, and
/// what share of that currency's total expense it represents.
class CategorySpending extends Equatable {
  const CategorySpending({
    required this.category,
    required this.amount,
    required this.percentageOfExpense,
  });

  final CategoryEntity category;
  final double amount;

  /// 0-100. 0 when the currency's total expense for the month is 0.
  final double percentageOfExpense;

  @override
  List<Object?> get props => [category, amount, percentageOfExpense];
}
