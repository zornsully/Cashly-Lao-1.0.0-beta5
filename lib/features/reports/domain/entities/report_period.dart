import 'package:equatable/equatable.dart';

/// The calendar window a report represents.  The values deliberately model
/// calendar boundaries in local time; Firestore queries use the resulting
/// half-open range (`start <= date < endExclusive`) so adjacent reports never
/// double-count a transaction.
enum ReportPeriod { today, week, month, year, custom }

extension ReportPeriodLabel on ReportPeriod {
  String get label => switch (this) {
    ReportPeriod.today => 'Today',
    ReportPeriod.week => 'This week',
    ReportPeriod.month => 'This month',
    ReportPeriod.year => 'This year',
    ReportPeriod.custom => 'Custom range',
  };
}

/// A validated, local-time reporting window.  [endExclusive] is always after
/// [start], which prevents zero-length ranges and avoids 23:59:59 timestamp
/// edge cases around daylight-saving changes.
class ReportDateRange extends Equatable {
  ReportDateRange({required this.start, required this.endExclusive})
    : assert(endExclusive.isAfter(start));

  final DateTime start;
  final DateTime endExclusive;

  int get dayCount => endExclusive.difference(start).inDays.clamp(1, 3660);

  DateTime get previousStart => start.subtract(endExclusive.difference(start));

  static ReportDateRange forPeriod({
    required ReportPeriod period,
    required DateTime anchor,
    DateTime? customStart,
    DateTime? customEndExclusive,
  }) {
    switch (period) {
      case ReportPeriod.today:
        final start = DateTime(anchor.year, anchor.month, anchor.day);
        return ReportDateRange(
          start: start,
          endExclusive: start.add(const Duration(days: 1)),
        );
      case ReportPeriod.week:
        final day = DateTime(anchor.year, anchor.month, anchor.day);
        final start = day.subtract(Duration(days: day.weekday - DateTime.monday));
        return ReportDateRange(
          start: start,
          endExclusive: start.add(const Duration(days: 7)),
        );
      case ReportPeriod.month:
        final start = DateTime(anchor.year, anchor.month);
        return ReportDateRange(
          start: start,
          endExclusive: DateTime(anchor.year, anchor.month + 1),
        );
      case ReportPeriod.year:
        final start = DateTime(anchor.year);
        return ReportDateRange(start: start, endExclusive: DateTime(anchor.year + 1));
      case ReportPeriod.custom:
        if (customStart == null || customEndExclusive == null ||
            !customEndExclusive.isAfter(customStart)) {
          throw ArgumentError('A custom report range must have an end after its start.');
        }
        return ReportDateRange(start: customStart, endExclusive: customEndExclusive);
    }
  }

  @override
  List<Object> get props => [start, endExclusive];
}
