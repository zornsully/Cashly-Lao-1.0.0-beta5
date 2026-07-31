import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction_type.dart';

/// Narrows what Reports summarizes, on top of the month it's already
/// browsing. A plain domain value object — no Flutter `DateTimeRange` here,
/// see `CLAUDE.md`'s Architecture Principles (`domain` never imports
/// Flutter types); the presentation layer converts to/from its own
/// `DateTimeRange` when driving a date picker.
class ReportFilter extends Equatable {
  const ReportFilter({
    this.customRangeStart,
    this.customRangeEndExclusive,
    this.accountId,
    this.categoryId,
    this.type,
  });

  /// When both are set, replaces the selected month as the report's time
  /// window entirely. Always set together — never one without the other.
  final DateTime? customRangeStart;
  final DateTime? customRangeEndExclusive;

  final String? accountId;
  final String? categoryId;
  final TransactionType? type;

  bool get hasCustomRange =>
      customRangeStart != null && customRangeEndExclusive != null;

  bool get isActive =>
      hasCustomRange || accountId != null || categoryId != null || type != null;

  @override
  List<Object?> get props => [
    customRangeStart,
    customRangeEndExclusive,
    accountId,
    categoryId,
    type,
  ];
}
