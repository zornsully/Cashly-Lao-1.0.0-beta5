/// How often a savings goal's auto-contribution schedule recurs.
enum GoalContributionFrequency {
  weekly(label: 'Weekly'),
  biweekly(label: 'Every 2 weeks'),
  monthly(label: 'Monthly');

  const GoalContributionFrequency({required this.label});

  final String label;

  /// The next occurrence strictly after [from]. Monthly uses calendar-month
  /// arithmetic (the same day next month) rather than a fixed 30-day step.
  DateTime nextDueDate(DateTime from) {
    switch (this) {
      case GoalContributionFrequency.weekly:
        return from.add(const Duration(days: 7));
      case GoalContributionFrequency.biweekly:
        return from.add(const Duration(days: 14));
      case GoalContributionFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }
}
