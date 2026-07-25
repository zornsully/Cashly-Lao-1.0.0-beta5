import 'package:equatable/equatable.dart';

/// Which basis [GoalCompletionEstimate.estimatedDate] was projected from.
enum GoalCompletionEstimateBasis {
  /// The goal has already reached its target — there's nothing to project.
  alreadyCompleted,

  /// Projected from the goal's own configured auto-contribution schedule.
  scheduled,

  /// No schedule configured — projected from the recent pace of transfers
  /// into the linked account instead.
  trailingAverage,

  /// Neither a schedule nor enough recent history to estimate from.
  insufficientData,
}

class GoalCompletionEstimate extends Equatable {
  const GoalCompletionEstimate({required this.basis, this.estimatedDate});

  final GoalCompletionEstimateBasis basis;

  /// Null for [GoalCompletionEstimateBasis.alreadyCompleted] and
  /// [GoalCompletionEstimateBasis.insufficientData].
  final DateTime? estimatedDate;

  @override
  List<Object?> get props => [basis, estimatedDate];
}
