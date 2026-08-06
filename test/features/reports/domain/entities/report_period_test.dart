import 'package:cashly_lao/features/reports/domain/entities/report_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('week starts Monday and ends exclusively the following Monday', () {
    final range = ReportDateRange.forPeriod(
      period: ReportPeriod.week,
      anchor: DateTime(2026, 8, 5), // Wednesday
    );
    expect(range.start, DateTime(2026, 8, 3));
    expect(range.endExclusive, DateTime(2026, 8, 10));
  });

  test('year and custom periods are valid half-open local ranges', () {
    final year = ReportDateRange.forPeriod(
      period: ReportPeriod.year,
      anchor: DateTime(2026, 7, 1),
    );
    expect(year.start, DateTime(2026));
    expect(year.endExclusive, DateTime(2027));

    final custom = ReportDateRange.forPeriod(
      period: ReportPeriod.custom,
      anchor: DateTime(2026),
      customStart: DateTime(2026, 8, 1),
      customEndExclusive: DateTime(2026, 8, 5),
    );
    expect(custom.dayCount, 4);
    expect(custom.previousStart, DateTime(2026, 7, 28));
  });

  test('invalid custom ranges are rejected before a query is issued', () {
    expect(
      () => ReportDateRange.forPeriod(
        period: ReportPeriod.custom,
        anchor: DateTime(2026),
        customStart: DateTime(2026, 8, 4),
        customEndExclusive: DateTime(2026, 8, 4),
      ),
      throwsArgumentError,
    );
  });
}
