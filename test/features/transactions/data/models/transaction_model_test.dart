import 'package:cashly_lao/features/transactions/data/models/transaction_model.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'fromFirestore maps a stored document back to a TransactionModel',
    () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('transactions').doc('txn-1');

      await docRef.set({
        'accountId': 'acc-1',
        'categoryId': 'cat-1',
        'type': 'expense',
        'amount': 42.5,
        'date': Timestamp.fromDate(DateTime(2026, 3, 15)),
        'note': 'Lunch',
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 15, 12)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 3, 15, 12)),
      });

      final snapshot = await docRef.get();
      final model = TransactionModel.fromFirestore(snapshot);

      expect(model.id, 'txn-1');
      expect(model.accountId, 'acc-1');
      expect(model.categoryId, 'cat-1');
      expect(model.type, TransactionType.expense);
      expect(model.amount, 42.5);
      expect(model.date, DateTime(2026, 3, 15));
      expect(model.note, 'Lunch');
      expect(model.signedAmount, -42.5);
    },
  );

  test(
    'fromFirestore normalizes an empty categoryId/toAccountId to null',
    () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('transactions').doc('txn-transfer');

      await docRef.set({
        'accountId': 'acc-1',
        'categoryId': '',
        'type': 'transfer',
        'toAccountId': 'acc-2',
        'amount': 30,
        'date': Timestamp.fromDate(DateTime(2026, 3, 15)),
        'note': '',
      });

      final snapshot = await docRef.get();
      final model = TransactionModel.fromFirestore(snapshot);

      expect(model.type, TransactionType.transfer);
      expect(model.categoryId, isNull);
      expect(model.toAccountId, 'acc-2');
    },
  );

  test(
    'fromFirestore normalizes an absent toAccountId to null for '
    'income/expense',
    () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('transactions').doc('txn-income');

      await docRef.set({
        'accountId': 'acc-1',
        'categoryId': 'cat-1',
        'type': 'income',
        'amount': 30,
        'date': Timestamp.fromDate(DateTime(2026, 3, 15)),
        'note': '',
      });

      final snapshot = await docRef.get();
      final model = TransactionModel.fromFirestore(snapshot);

      expect(model.categoryId, 'cat-1');
      expect(model.toAccountId, isNull);
    },
  );

  test('defaults note to empty string when absent', () async {
    final firestore = FakeFirebaseFirestore();
    final docRef = firestore.collection('transactions').doc('txn-2');

    await docRef.set({
      'accountId': 'acc-1',
      'categoryId': 'cat-1',
      'type': 'income',
      'amount': 100,
      'date': Timestamp.fromDate(DateTime(2026, 3, 1)),
    });

    final snapshot = await docRef.get();
    final model = TransactionModel.fromFirestore(snapshot);

    expect(model.note, '');
    expect(model.signedAmount, 100);
  });
}
