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

  @override
  Stream<List<BudgetModel>> watchBudgetsForMonth(DateTime month) {
    final normalizedMonth = DateTime(month.year, month.month);
    return _collection
        .where('month', isEqualTo: Timestamp.fromDate(normalizedMonth))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(BudgetModel.fromFirestore).toList(),
        );
  }

  @override
  Future<BudgetModel> createBudget({
    required String categoryId,
    required DateTime month,
    required double limitAmount,
    required String currencyCode,
  }) async {
    final normalizedMonth = DateTime(month.year, month.month);
    final docRef = _collection.doc(_docId(categoryId, normalizedMonth));

    try {
      final existing = await docRef.get();
      if (existing.exists) {
        throw const ServerException(
          'A budget already exists for this category this month.',
        );
      }

      final now = DateTime.now();
      await docRef.set({
        'categoryId': categoryId,
        'month': Timestamp.fromDate(normalizedMonth),
        'limitAmount': limitAmount,
        'currencyCode': currencyCode,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return BudgetModel(
        id: docRef.id,
        categoryId: categoryId,
        month: normalizedMonth,
        limitAmount: limitAmount,
        currencyCode: currencyCode,
        createdAt: now,
        updatedAt: now,
      );
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
    try {
      await _collection.doc(id).update({
        'limitAmount': limitAmount,
        'currencyCode': currencyCode,
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
