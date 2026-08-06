import 'package:intl/intl.dart';

import '../../../accounts/domain/entities/account_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

/// RFC 4180 CSV export for the actual report transaction set.  It intentionally
/// receives the already-filtered report records, rather than querying Firestore
/// itself, so exported totals and the visible report cannot diverge.
class ExportTransactionsToCsvUseCase {
  const ExportTransactionsToCsvUseCase();

  static const _headers = [
    'Transaction ID',
    'Date',
    'Time',
    'Type',
    'Description',
    'Category',
    'Account',
    'Amount',
    'Currency',
    'Notes',
    'Created At',
    'Updated At',
  ];

  String call({
    required List<TransactionEntity> transactions,
    required Map<String, AccountEntity> accountsById,
    required Map<String, CategoryEntity> categoriesById,
  }) {
    final rows = <List<Object?>>[_headers];
    for (final transaction in transactions) {
      final account = accountsById[transaction.accountId];
      final category = transaction.categoryId == null
          ? null
          : categoriesById[transaction.categoryId];
      final date = transaction.date.toLocal();
      rows.add([
        transaction.id,
        DateFormat('yyyy-MM-dd').format(date),
        DateFormat('HH:mm:ss').format(date),
        transaction.type.name,
        transaction.note,
        category?.name ?? '',
        account?.name ?? '',
        _number(transaction.amount),
        account?.currencyCode ?? '',
        transaction.note,
        transaction.createdAt.toUtc().toIso8601String(),
        transaction.updatedAt.toUtc().toIso8601String(),
      ]);
    }
    return '${rows.map((row) => row.map(_escape).join(',')).join('\r\n')}\r\n';
  }

  static String _number(double value) => value.isFinite ? value.toString() : '';

  static String _escape(Object? value) {
    if (value == null) return '';
    final text = value.toString();
    if (text.contains(RegExp('[,"\n\r]'))) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}
