import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/transaction_type.dart';
import '../models/transaction_model.dart';

abstract interface class TransactionRemoteDataSource {
  Stream<List<TransactionModel>> watchTransactionsForMonth(DateTime month);

  Stream<List<TransactionModel>> watchTransactionsInRange({
    required DateTime start,
    required DateTime endExclusive,
  });

  /// [categoryId] is required for income/expense and must be omitted for a
  /// transfer; [toAccountId] is required for a transfer (and must differ
  /// from [accountId]) and must be omitted otherwise.
  Future<TransactionModel> createTransaction({
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  });

  Future<void> updateTransaction({
    required String id,
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  });

  Future<void> deleteTransaction(String id);
}

class FirestoreTransactionRemoteDataSource
    implements TransactionRemoteDataSource {
  FirestoreTransactionRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  }) : _firestore = firestore, // ignore: prefer_initializing_formals
       _firebaseAuth = firebaseAuth; // ignore: prefer_initializing_formals

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  String get _uid {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw const AuthException('No signed-in user.', code: 'no-current-user');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection(FirestorePaths.users).doc(_uid);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _userDoc.collection(FirestorePaths.transactions);

  DocumentReference<Map<String, dynamic>> _accountDoc(String accountId) =>
      _userDoc.collection(FirestorePaths.accounts).doc(accountId);

  @override
  Stream<List<TransactionModel>> watchTransactionsForMonth(DateTime month) {
    return watchTransactionsInRange(
      start: DateTime(month.year, month.month),
      endExclusive: DateTime(month.year, month.month + 1),
    );
  }

  @override
  Stream<List<TransactionModel>> watchTransactionsInRange({
    required DateTime start,
    required DateTime endExclusive,
  }) {
    return _collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(endExclusive))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(TransactionModel.fromFirestore).toList(),
        );
  }

  /// Per-account balance deltas a transaction with this shape applies.
  /// income/expense touch one account; transfer touches two — a debit on
  /// the source and an equal credit on the destination. Centralizing this
  /// is what lets create/update/delete share one reconciliation algorithm
  /// instead of each hand-rolling "1 account or 2" branches.
  Map<String, double> _deltasFor({
    required String accountId,
    required String? toAccountId,
    required TransactionType type,
    required double amount,
  }) {
    switch (type) {
      case TransactionType.income:
        return {accountId: amount};
      case TransactionType.expense:
        return {accountId: -amount};
      case TransactionType.transfer:
        if (toAccountId == null || toAccountId == accountId) {
          throw const ServerException(
            'A transfer needs two different accounts.',
          );
        }
        return {accountId: -amount, toAccountId: amount};
    }
  }

  /// Reads every account in [deltas], applies its delta, and returns the
  /// refs actually written (an account missing at read time is silently
  /// skipped only when [requireExists] is false — used by delete, where a
  /// since-deleted account has nothing left to reverse; create/update
  /// require every referenced account to still exist).
  Future<void> _applyDeltas(
    Transaction txn,
    Map<String, double> deltas, {
    required bool requireExists,
  }) async {
    // Firestore transactions require every read to happen before any
    // write, so this resolves all account refs first, then writes.
    final refs = {
      for (final accountId in deltas.keys) accountId: _accountDoc(accountId),
    };
    final snaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final entry in refs.entries) {
      final snap = await txn.get(entry.value);
      if (!snap.exists) {
        if (requireExists) {
          throw const ServerException('That account no longer exists.');
        }
        continue;
      }
      snaps[entry.key] = snap;
    }

    for (final entry in snaps.entries) {
      final balance = (entry.value.data()!['balance'] as num).toDouble();
      txn.update(refs[entry.key]!, {
        'balance': balance + deltas[entry.key]!,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<TransactionModel> createTransaction({
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  }) async {
    final docRef = _collection.doc();
    final now = DateTime.now();
    final deltas = _deltasFor(
      accountId: accountId,
      toAccountId: toAccountId,
      type: type,
      amount: amount,
    );

    try {
      await _firestore.runTransaction((txn) async {
        await _applyDeltas(txn, deltas, requireExists: true);
        txn.set(docRef, {
          'accountId': accountId,
          'categoryId': categoryId ?? '',
          'type': type.name,
          'toAccountId': toAccountId ?? '',
          'amount': amount,
          'date': Timestamp.fromDate(date),
          'note': note,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not save the transaction.');
    }

    return TransactionModel(
      id: docRef.id,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      toAccountId: toAccountId,
      amount: amount,
      date: date,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> updateTransaction({
    required String id,
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  }) async {
    try {
      await _firestore.runTransaction((txn) async {
        final txnRef = _collection.doc(id);
        final txnSnap = await txn.get(txnRef);
        if (!txnSnap.exists) {
          throw const ServerException('That transaction no longer exists.');
        }
        final oldData = txnSnap.data()!;
        final oldAccountId = oldData['accountId'] as String;
        final oldType = TransactionType.values.byName(
          oldData['type'] as String,
        );
        final oldAmount = (oldData['amount'] as num).toDouble();
        final oldToAccountIdRaw = oldData['toAccountId'] as String? ?? '';
        final oldToAccountId = oldToAccountIdRaw.isEmpty
            ? null
            : oldToAccountIdRaw;

        final oldDeltas = _deltasFor(
          accountId: oldAccountId,
          toAccountId: oldToAccountId,
          type: oldType,
          amount: oldAmount,
        );
        final newDeltas = _deltasFor(
          accountId: accountId,
          toAccountId: toAccountId,
          type: type,
          amount: amount,
        );

        // Net effect per account: reverse the old shape, apply the new
        // one. An account touched by both (e.g. editing a transfer's
        // amount without changing which accounts it's between) nets to a
        // single delta instead of two separate writes — this is what
        // lets create/update/delete share one path regardless of whether
        // 1 or 2 accounts, or which type, is involved on either side.
        final netDeltas = <String, double>{};
        oldDeltas.forEach((accId, delta) {
          netDeltas.update(accId, (v) => v - delta, ifAbsent: () => -delta);
        });
        newDeltas.forEach((accId, delta) {
          netDeltas.update(accId, (v) => v + delta, ifAbsent: () => delta);
        });
        netDeltas.removeWhere((_, delta) => delta == 0);

        await _applyDeltas(txn, netDeltas, requireExists: true);

        txn.update(txnRef, {
          'accountId': accountId,
          'categoryId': categoryId ?? '',
          'type': type.name,
          'toAccountId': toAccountId ?? '',
          'amount': amount,
          'date': Timestamp.fromDate(date),
          'note': note,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not update the transaction.');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await _firestore.runTransaction((txn) async {
        final txnRef = _collection.doc(id);
        final txnSnap = await txn.get(txnRef);
        if (!txnSnap.exists) return;

        final data = txnSnap.data()!;
        final accountId = data['accountId'] as String;
        final type = TransactionType.values.byName(data['type'] as String);
        final amount = (data['amount'] as num).toDouble();
        final toAccountIdRaw = data['toAccountId'] as String? ?? '';
        final toAccountId = toAccountIdRaw.isEmpty ? null : toAccountIdRaw;

        final deltas = _deltasFor(
          accountId: accountId,
          toAccountId: toAccountId,
          type: type,
          amount: amount,
        );
        // Reversing, so every delta is negated — same "best effort" as
        // before: an account already deleted has nothing left to reverse.
        final reversed = deltas.map((accId, delta) => MapEntry(accId, -delta));
        await _applyDeltas(txn, reversed, requireExists: false);

        txn.delete(txnRef);
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not delete the transaction.');
    }
  }
}
