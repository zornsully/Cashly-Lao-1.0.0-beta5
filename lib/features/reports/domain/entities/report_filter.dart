import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction_type.dart';
import 'report_period.dart';

/// Narrows what Reports summarizes, on top of the month it's already
/// browsing. A plain domain value object — no Flutter `DateTimeRange` here,
/// see `CLAUDE.md`'s Architecture Principles (`domain` never imports
/// Flutter types); the presentation layer converts to/from its own
/// `DateTimeRange` when driving a date picker.
class ReportFilter extends Equatable {
  const ReportFilter({
    this.period = ReportPeriod.month,
    this.customRangeStart,
    this.customRangeEndExclusive,
    this.accountId,
    this.categoryId,
    this.currencyCode,
    this.type,
  });

  /// The calendar preset being browsed.  Custom ranges use [customRangeStart]
  /// and [customRangeEndExclusive]; all other presets derive their range from
  /// the selected report anchor.
  final ReportPeriod period;

  /// When both are set, replaces the selected month as the report's time
  /// window entirely. Always set together — never one without the other.
  final DateTime? customRangeStart;
  final DateTime? customRangeEndExclusive;

  final String? accountId;
  final String? categoryId;
  final String? currencyCode;
  final TransactionType? type;

  bool get hasCustomRange =>
      period == ReportPeriod.custom &&
      customRangeStart != null &&
      customRangeEndExclusive != null;

  bool get isActive =>
      period != ReportPeriod.month ||
      hasCustomRange ||
      accountId != null ||
      categoryId != null ||
      currencyCode != null ||
      type != null;

  @override
  List<Object?> get props => [
    period,
    customRangeStart,
    customRangeEndExclusive,
    accountId,
    categoryId,
    currencyCode,
    type,
  ];
}
