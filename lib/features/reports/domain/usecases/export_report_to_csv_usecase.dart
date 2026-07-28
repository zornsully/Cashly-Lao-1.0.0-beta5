import '../entities/monthly_report.dart';

/// Flattens a [MonthlyReport] into a CSV string, built on
/// [MonthlyReport.toExportRows]'s stable row shape. Pure and
/// repository-free — same reasoning as `BuildMonthlyTrendUseCase`.
///
/// Rows are heterogeneous (a category row and a summary row don't share
/// every column — see `toExportRows()`'s doc comment), so the header is the
/// union of every key across every row, in a fixed, readable order; a row
/// missing a given column gets an empty cell rather than the columns
/// shifting per row, which is what makes this openable in a spreadsheet at
/// all.
class ExportReportToCsvUseCase {
  const ExportReportToCsvUseCase();

  static const List<String> _columnOrder = [
    'month',
    'currency',
    'rowType',
    'category',
    'amount',
    'percentageOfExpense',
    'totalIncome',
    'totalExpense',
    'net',
  ];

  String call(MonthlyReport report) {
    final rows = report.toExportRows();
    final buffer = StringBuffer()..writeln(_columnOrder.map(_escape).join(','));

    for (final row in rows) {
      buffer.writeln(
        _columnOrder.map((column) => _escape(row[column])).join(','),
      );
    }

    return buffer.toString();
  }

  /// RFC 4180: a field containing a comma, quote, or newline is wrapped in
  /// quotes, with any internal quote doubled.
  static String _escape(Object? value) {
    if (value == null) return '';
    final text = value.toString();
    if (text.contains(RegExp('[,"\n\r]'))) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}
