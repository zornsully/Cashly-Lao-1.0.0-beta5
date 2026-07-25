import 'package:equatable/equatable.dart';

class BudgetEntity extends Equatable {
  const BudgetEntity({
    required this.id,
    required this.categoryId,
    required this.month,
    required this.limitAmount,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String categoryId;

  /// Truncated to the first of the month — a budget always covers one
  /// full calendar month.
  final DateTime month;

  /// Always a positive spending cap.
  final double limitAmount;

  /// The currency [limitAmount] is denominated in. Only transactions on
  /// accounts of this same currency count against this budget — see
  /// [PROJECT_PROGRESS.md] for why budgets don't mix currencies.
  final String currencyCode;

  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetEntity copyWith({double? limitAmount, String? currencyCode}) {
    return BudgetEntity(
      id: id,
      categoryId: categoryId,
      month: month,
      limitAmount: limitAmount ?? this.limitAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    categoryId,
    month,
    limitAmount,
    currencyCode,
    createdAt,
    updatedAt,
  ];
}
