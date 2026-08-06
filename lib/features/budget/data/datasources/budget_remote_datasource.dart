import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../models/budget_model.dart';

abstract interface class BudgetRemoteDataSource {
  Stream<List<BudgetModel>> watchBudgetsForMonth(DateTime month);

  Future<BudgetModel> createBudget({
    required String categoryId,
    required DateTime month,
    required double limitAmount,
    required String currencyCode,
  });

  Future<void> updateBudget({
    required String id,
    required double limitAmount,
    required String currencyCode,
  });

  Future<void> deleteBudget(String id);
}

class FirestoreBudgetRemoteDataSource implements BudgetRemoteDataSource {
  FirestoreBudgetRemoteDataSource({
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

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection(FirestorePaths.users)
      .doc(_uid)
      .collection(FirestorePaths.budgets);

  /// One budget per category per month: the document ID itself encodes
  /// both, so a duplicate is a write to the same document rather than a
  /// second one — see [FirestorePaths.budgets].
  String _docId(String categoryId, DateTime month) {
    final normalized = month.month.toString().padLeft(2, '0');
    return '${categoryId}_${month.year}-$normalized';
  }

  String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  DateTime _normalizeMonth(DateTime month) =>
      DateTime.utc(month.year, month.month);

  void _validateBudgetInput({
    required String categoryId,
    required double limitAmount,
    required String currencyCode,
  }) {
    if (categoryId.trim().isEmpty) {
      throw const ServerException('Choose an expense category first.');
    }
    if (!limitAmount.isFinite || limitAmount <= 0) {
      throw const ServerException('Budget amount must be a positive number.');
    }
    if (currencyCode.trim().isEmpty) {
      throw const ServerException('Choose a currency for the budget.');
    }
  }

  @override
  Stream<List<BudgetModel>> watchBudgetsForMonth(DateTime month) {
    final normalizedMonth = _normalizeMonth(month);
    final monthKey = _monthKey(normalizedMonth);
    // A stream of the user's small budget collection avoids brittle equality
    // checks against timestamps created in another time zone. New documents
    // carry monthKey; the timestamp fallback keeps existing budgets visible.
    return _collection.snapshots().map((snapshot) {
      final budgets = <BudgetModel>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final storedMonth = data['month'];
        final isRequestedMonth =
            data['monthKey'] == monthKey ||
            (storedMonth is Timestamp &&
                storedMonth.toDate().year == normalizedMonth.year &&
                storedMonth.toDate().month == normalizedMonth.month);
        if (isRequestedMonth) budgets.add(BudgetModel.fromFirestore(doc));
      }
      budgets.sort((a, b) => a.categoryId.compareTo(b.categoryId));
      return budgets;
    });
  }

  @override
  Future<BudgetModel> createBudget({
    required String categoryId,
    required DateTime month,
    required double limitAmount,
    required String currencyCode,
  }) async {
    _validateBudgetInput(
      categoryId: categoryId,
      limitAmount: limitAmount,
      currencyCode: currencyCode,
    );
    final normalizedMonth = _normalizeMonth(month);
    final docRef = _collection.doc(_docId(categoryId, normalizedMonth));

    try {
      final now = DateTime.now();
      final budget = BudgetModel(
        id: docRef.id,
        categoryId: categoryId,
        month: normalizedMonth,
        limitAmount: limitAmount,
        currencyCode: currencyCode,
        createdAt: now,
        updatedAt: now,
      );
      await _firestore.runTransaction<void>((transaction) async {
        final existing = await transaction.get(docRef);
        if (existing.exists) {
          throw const ServerException(
            'A budget already exists for this category this month. Edit it instead.',
          );
        }
        transaction.set(docRef, {
          'categoryId': categoryId,
          'month': Timestamp.fromDate(normalizedMonth),
          'monthKey': _monthKey(normalizedMonth),
          'year': normalizedMonth.year,
          'monthNumber': normalizedMonth.month,
          'limitAmount': limitAmount,
          'currencyCode': currencyCode,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return budget;
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not create the budget.');
    }
  }

  @override
  Future<void> updateBudget({
    required String id,
    required double limitAmount,
    required String currencyCode,
  }) async {
    _validateBudgetInput(
      categoryId: 'existing-budget',
      limitAmount: limitAmount,
      currencyCode: currencyCode,
    );
    try {
      final docRef = _collection.doc(id);
      final existing = await docRef.get();
      final data = existing.data();
      final categoryId = data?['categoryId'];
      final storedMonth = data?['month'];
      if (!existing.exists ||
          categoryId is! String ||
          categoryId.isEmpty ||
          storedMonth is! Timestamp) {
        throw const ServerException('That budget no longer exists.');
      }
      final month = _normalizeMonth(storedMonth.toDate());
      await docRef.update({
        'limitAmount': limitAmount,
        'currencyCode': currencyCode,
        // Backfill the fields added for reliable month filtering whenever an
        // older budget is edited. This keeps existing users' budgets usable
        // after the Firestore rule/data-model hardening.
        'monthKey': _monthKey(month),
        'year': month.year,
        'monthNumber': month.month,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not update the budget.');
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      await _collection.doc(id).delete();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not delete the budget.');
    }
  }
}
