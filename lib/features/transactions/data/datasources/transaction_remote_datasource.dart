import 'dart:async';
import 'dart:developer' as developer;

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

  // A failed online transaction can produce one queued batch for a record.
  // Keep that operation key until Firestore acknowledges or rejects it so a
  // double tap, retry, or route rebuild cannot enqueue the same balance
  // increments twice while the device is offline.
  final Set<String> _queuedMutationKeys = <String>{};

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

  /// The normal path intentionally stays a Firestore transaction: account
  /// reconciliation and the transaction record must reach the server as one
  /// atomic change whenever a live connection is available.
  ///
  /// This small seam lets the offline branch be tested without weakening the
  /// production path or changing [TransactionRemoteDataSource]'s public API.
  Future<T> runAtomicTransaction<T>(TransactionHandler<T> transactionHandler) {
    return _firestore.runTransaction<T>(transactionHandler);
  }

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

  /// Defense-in-depth alongside `firestore.rules`' own get()-based check:
  /// Cashly never converts currency on a transfer, so source and
  /// destination must already be the same currency. The app form already
  /// restricts the destination picker to same-currency accounts, but that's
  /// a client-only convention a direct API write could bypass — this is
  /// what makes it a real guarantee for the one path (online, atomic
  /// transaction) that can enforce it against a live read.
  Future<void> _requireMatchingTransferCurrency(
    Transaction txn, {
    required TransactionType type,
    required String accountId,
    required String? toAccountId,
  }) async {
    if (type != TransactionType.transfer || toAccountId == null) return;
    final sourceSnap = await txn.get(_accountDoc(accountId));
    final destSnap = await txn.get(_accountDoc(toAccountId));
    if (!sourceSnap.exists || !destSnap.exists) {
      throw const ServerException('That account no longer exists.');
    }
    final sourceCurrency = sourceSnap.data()!['currencyCode'];
    final destCurrency = destSnap.data()!['currencyCode'];
    if (sourceCurrency != destCurrency) {
      throw const ServerException(
        'A transfer requires both accounts to use the same currency.',
      );
    }
  }

  /// Offline counterpart of [_requireMatchingTransferCurrency], reading from
  /// the device cache the same way [_requireCachedAccounts] does.
  Future<void> _requireCachedMatchingTransferCurrency({
    required TransactionType type,
    required String accountId,
    required String? toAccountId,
  }) async {
    if (type != TransactionType.transfer || toAccountId == null) return;
    final sourceSnap = await _accountDoc(
      accountId,
    ).get(const GetOptions(source: Source.cache));
    final destSnap = await _accountDoc(
      toAccountId,
    ).get(const GetOptions(source: Source.cache));
    final sourceCurrency = sourceSnap.data()?['currencyCode'];
    final destCurrency = destSnap.data()?['currencyCode'];
    if (sourceCurrency == null || destCurrency == null) {
      throw const ServerException(
        'This change cannot be queued offline because one of its accounts '
        'is not stored on this device yet.',
      );
    }
    if (sourceCurrency != destCurrency) {
      throw const ServerException(
        'A transfer requires both accounts to use the same currency.',
      );
    }
  }

  /// Only fall back for a confirmed unavailable/offline result. In
  /// particular, a timeout is deliberately *not* treated as offline: an
  /// atomic transaction may have reached the server even if a response was
  /// delayed, and queuing another set of increments in that case could apply
  /// a balance change twice.
  bool _isConfirmedOfflineError(FirebaseException error) {
    final message = error.message?.toLowerCase() ?? '';
    return error.code == 'unavailable' ||
        (error.code == 'failed-precondition' && message.contains('offline'));
  }

  /// Reads an account from the device cache only. A queued [WriteBatch]
  /// cannot safely use an account that has never been stored locally: an
  /// update for a non-existent server document would reject the entire batch
  /// later, leaving the user with an optimistic transaction that rolls back.
  Future<void> _requireCachedAccounts(Iterable<String> accountIds) async {
    try {
      for (final accountId in accountIds.toSet()) {
        final snapshot = await _accountDoc(
          accountId,
        ).get(const GetOptions(source: Source.cache));
        final balance = snapshot.data()?['balance'];
        if (!snapshot.exists || balance is! num) {
          throw const ServerException(
            'This change cannot be queued offline because one of its '
            'accounts is not stored on this device yet.',
          );
        }
      }
    } on ServerException {
      rethrow;
    } on FirebaseException {
      throw const ServerException(
        'This change cannot be queued offline because its account data is '
        'not stored on this device yet.',
      );
    }
  }

  /// An edit/delete has to reverse the exact shape that is currently visible
  /// to the user. Read it from [Source.cache] rather than the default source
  /// so this fallback never makes a network request or guesses at old values.
  Future<_CachedTransactionShape> _requireCachedTransaction(String id) async {
    try {
      final snapshot = await _collection
          .doc(id)
          .get(const GetOptions(source: Source.cache));
      if (!snapshot.exists || snapshot.data() == null) {
        throw const ServerException(
          'This transaction is not stored on this device yet, so it cannot '
          'be changed while offline.',
        );
      }

      return _CachedTransactionShape.fromFirestore(snapshot.data()!);
    } on ServerException {
      rethrow;
    } on FirebaseException {
      throw const ServerException(
        'This transaction is not stored on this device yet, so it cannot '
        'be changed while offline.',
      );
    } on ArgumentError {
      throw const ServerException(
        'This transaction has incomplete cached data and cannot be changed '
        'while offline.',
      );
    } on StateError {
      throw const ServerException(
        'This transaction has incomplete cached data and cannot be changed '
        'while offline.',
      );
    }
  }

  Map<String, dynamic> _transactionData({
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
    required bool isCreate,
  }) {
    return {
      'accountId': accountId,
      'categoryId': categoryId ?? '',
      'type': type.name,
      'toAccountId': toAccountId ?? '',
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, double> _netDeltas({
    required Map<String, double> oldDeltas,
    required Map<String, double> newDeltas,
  }) {
    final netDeltas = <String, double>{};
    oldDeltas.forEach((accountId, delta) {
      netDeltas.update(
        accountId,
        (value) => value - delta,
        ifAbsent: () => -delta,
      );
    });
    newDeltas.forEach((accountId, delta) {
      netDeltas.update(
        accountId,
        (value) => value + delta,
        ifAbsent: () => delta,
      );
    });
    netDeltas.removeWhere((_, delta) => delta == 0);
    return netDeltas;
  }

  /// Adds account mutations to a single queued batch. [FieldValue.increment]
  /// is important here: it reconciles against the server's latest balance
  /// when this offline batch eventually syncs, rather than overwriting a
  /// balance with a stale cached value.
  void _queueAccountDeltas(WriteBatch batch, Map<String, double> deltas) {
    for (final entry in deltas.entries) {
      batch.update(_accountDoc(entry.key), {
        'balance': FieldValue.increment(entry.value),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Calling [WriteBatch.commit] immediately stores the one atomic mutation
  /// in Firestore's persistent local queue, which updates active snapshots
  /// before the device reconnects. [mutationKey] makes the fallback
  /// idempotent inside this datasource: one queued mutation may own the
  /// balance deltas for a transaction until Firestore resolves it. We
  /// intentionally do not retry the batch ourselves, because replaying a
  /// [FieldValue.increment] would not be safe.
  void _commitQueuedBatch(WriteBatch batch, {required String mutationKey}) {
    if (!_queuedMutationKeys.add(mutationKey)) {
      return;
    }

    unawaited(
      batch.commit().then<void>(
        (_) => _queuedMutationKeys.remove(mutationKey),
        onError: (Object error, StackTrace stackTrace) {
          _queuedMutationKeys.remove(mutationKey);
          // A server-side rejection after reconnect (for example, an
          // account removed on another device) is rolled back by Firestore's
          // local cache. Keep the failure visible to diagnostics without
          // pretending it is safe to replay the balance deltas here.
          developer.log(
            'Queued transaction mutation was rejected during sync.',
            name: 'cashly.transactions',
            error: error,
            stackTrace: stackTrace,
          );
        },
      ),
    );
  }

  Future<void> _queueCreateOffline({
    required DocumentReference<Map<String, dynamic>> transactionRef,
    required Map<String, double> deltas,
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  }) async {
    await _requireCachedMatchingTransferCurrency(
      type: type,
      accountId: accountId,
      toAccountId: toAccountId,
    );
    await _requireCachedAccounts(deltas.keys);

    final batch = _firestore.batch();
    _queueAccountDeltas(batch, deltas);
    batch.set(
      transactionRef,
      _transactionData(
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        toAccountId: toAccountId,
        amount: amount,
        date: date,
        note: note,
        isCreate: true,
      ),
    );
    _commitQueuedBatch(batch, mutationKey: 'create:${transactionRef.id}');
  }

  Future<void> _queueUpdateOffline({
    required String id,
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  }) async {
    final mutationKey = 'transaction:$id';
    if (_queuedMutationKeys.contains(mutationKey)) {
      throw const ServerException(
        'This transaction already has a change waiting to sync. Try again '
        'after the connection returns.',
      );
    }

    final old = await _requireCachedTransaction(id);
    final oldDeltas = _deltasFor(
      accountId: old.accountId,
      toAccountId: old.toAccountId,
      type: old.type,
      amount: old.amount,
    );
    final newDeltas = _deltasFor(
      accountId: accountId,
      toAccountId: toAccountId,
      type: type,
      amount: amount,
    );
    final netDeltas = _netDeltas(oldDeltas: oldDeltas, newDeltas: newDeltas);
    await _requireCachedMatchingTransferCurrency(
      type: type,
      accountId: accountId,
      toAccountId: toAccountId,
    );
    await _requireCachedAccounts(netDeltas.keys);

    final batch = _firestore.batch();
    _queueAccountDeltas(batch, netDeltas);
    batch.update(
      _collection.doc(id),
      _transactionData(
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        toAccountId: toAccountId,
        amount: amount,
        date: date,
        note: note,
        isCreate: false,
      ),
    );
    _commitQueuedBatch(batch, mutationKey: mutationKey);
  }

  Future<void> _queueDeleteOffline(String id) async {
    final mutationKey = 'transaction:$id';
    if (_queuedMutationKeys.contains(mutationKey)) {
      throw const ServerException(
        'This transaction already has a change waiting to sync. Try again '
        'after the connection returns.',
      );
    }

    final old = await _requireCachedTransaction(id);
    final deltas = _deltasFor(
      accountId: old.accountId,
      toAccountId: old.toAccountId,
      type: old.type,
      amount: old.amount,
    );
    final reversed = deltas.map(
      (accountId, delta) => MapEntry(accountId, -delta),
    );
    await _requireCachedAccounts(reversed.keys);

    final batch = _firestore.batch();
    _queueAccountDeltas(batch, reversed);
    batch.delete(_collection.doc(id));
    _commitQueuedBatch(batch, mutationKey: mutationKey);
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
      await runAtomicTransaction((txn) async {
        await _requireMatchingTransferCurrency(
          txn,
          type: type,
          accountId: accountId,
          toAccountId: toAccountId,
        );
        await _applyDeltas(txn, deltas, requireExists: true);
        txn.set(
          docRef,
          _transactionData(
            accountId: accountId,
            categoryId: categoryId,
            type: type,
            toAccountId: toAccountId,
            amount: amount,
            date: date,
            note: note,
            isCreate: true,
          ),
        );
      });
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      if (_isConfirmedOfflineError(e)) {
        await _queueCreateOffline(
          transactionRef: docRef,
          deltas: deltas,
          accountId: accountId,
          categoryId: categoryId,
          type: type,
          toAccountId: toAccountId,
          amount: amount,
          date: date,
          note: note,
        );
      } else {
        throw ServerException(e.message ?? 'Could not save the transaction.');
      }
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
      await runAtomicTransaction((txn) async {
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
        final netDeltas = _netDeltas(
          oldDeltas: oldDeltas,
          newDeltas: newDeltas,
        );

        await _requireMatchingTransferCurrency(
          txn,
          type: type,
          accountId: accountId,
          toAccountId: toAccountId,
        );
        await _applyDeltas(txn, netDeltas, requireExists: true);

        txn.update(
          txnRef,
          _transactionData(
            accountId: accountId,
            categoryId: categoryId,
            type: type,
            toAccountId: toAccountId,
            amount: amount,
            date: date,
            note: note,
            isCreate: false,
          ),
        );
      });
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      if (_isConfirmedOfflineError(e)) {
        await _queueUpdateOffline(
          id: id,
          accountId: accountId,
          categoryId: categoryId,
          type: type,
          toAccountId: toAccountId,
          amount: amount,
          date: date,
          note: note,
        );
      } else {
        throw ServerException(e.message ?? 'Could not update the transaction.');
      }
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await runAtomicTransaction((txn) async {
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
      if (_isConfirmedOfflineError(e)) {
        await _queueDeleteOffline(id);
      } else {
        throw ServerException(e.message ?? 'Could not delete the transaction.');
      }
    }
  }
}

/// The minimum cached shape needed to reverse a transaction's account
/// deltas. Keeping it private prevents the public domain entity from gaining
/// persistence-only offline state.
class _CachedTransactionShape {
  const _CachedTransactionShape({
    required this.accountId,
    required this.type,
    required this.amount,
    required this.toAccountId,
  });

  factory _CachedTransactionShape.fromFirestore(Map<String, dynamic> data) {
    final accountId = data['accountId'];
    final typeName = data['type'];
    final amount = data['amount'];
    final toAccountIdValue = data['toAccountId'];

    if (accountId is! String ||
        accountId.isEmpty ||
        typeName is! String ||
        amount is! num ||
        amount <= 0 ||
        (toAccountIdValue != null && toAccountIdValue is! String)) {
      throw StateError('Incomplete cached transaction data.');
    }

    return _CachedTransactionShape(
      accountId: accountId,
      type: TransactionType.values.byName(typeName),
      amount: amount.toDouble(),
      toAccountId: (toAccountIdValue as String? ?? '').isEmpty
          ? null
          : toAccountIdValue as String,
    );
  }

  final String accountId;
  final TransactionType type;
  final double amount;
  final String? toAccountId;
}
