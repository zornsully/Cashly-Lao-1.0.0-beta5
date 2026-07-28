import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/smart_money_score.dart';
import '../models/smart_money_score_model.dart';

abstract interface class SmartMoneyScoreRemoteDataSource {
  Stream<List<SmartMoneyScoreModel>> watchHistory();

  Future<SmartMoneyScoreModel> ensureMonthlyOpening(
    SmartMoneyScoreOpening candidate,
  );

  Future<void> saveMonthlyCalculation({
    required SmartMoneyScoreMonth month,
    required SmartMoneyScoreCalculation calculation,
  });
}

/// Firestore-backed score history. A transaction protects the deterministic
/// monthly document from duplicate resets when multiple devices open Cashly
/// at the same time.
class FirestoreSmartMoneyScoreRemoteDataSource
    implements SmartMoneyScoreRemoteDataSource {
  FirestoreSmartMoneyScoreRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  }) : _firestore = firestore, // ignore: prefer_initializing_formals
       _firebaseAuth = firebaseAuth; // ignore: prefer_initializing_formals

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw const AuthException('No signed-in user.', code: 'no-current-user');
    }
    return _firestore.collection(FirestorePaths.users).doc(uid);
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _userDoc.collection(FirestorePaths.smartMoneyScores);

  @override
  Stream<List<SmartMoneyScoreModel>> watchHistory() {
    return _collection
        .orderBy('monthStart', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(SmartMoneyScoreModel.fromFirestore).toList(),
        );
  }

  @override
  Future<SmartMoneyScoreModel> ensureMonthlyOpening(
    SmartMoneyScoreOpening candidate,
  ) async {
    _validateOpening(candidate);
    final reference = _collection.doc(candidate.documentId);
    SmartMoneyScoreModel? existing;
    final now = DateTime.now();

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        if (snapshot.exists) {
          existing = SmartMoneyScoreModel.fromFirestore(snapshot);
          return;
        }
        transaction.set(
          reference,
          SmartMoneyScoreModel.openingToFirestore(candidate),
        );
      });
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } on FirebaseException catch (error) {
      throw ServerException(
        error.message ?? 'Could not save the monthly score opening balance.',
      );
    }

    return existing ??
        SmartMoneyScoreModel(
          opening: candidate,
          createdAt: now,
          updatedAt: now,
        );
  }

  @override
  Future<void> saveMonthlyCalculation({
    required SmartMoneyScoreMonth month,
    required SmartMoneyScoreCalculation calculation,
  }) async {
    final reference = _collection.doc(month.id);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists) {
          throw const ServerException(
            'The monthly score opening balance must be created before saving a calculation.',
          );
        }
        final data = snapshot.data()!;
        // Do not allow a stale client to write calculation data into a
        // different period or currency document if its state was replaced.
        if (data['monthKey'] != month.opening.monthKey ||
            data['currencyCode'] != month.opening.currencyCode ||
            (data['monthStart'] as Timestamp?)?.toDate() !=
                month.opening.monthStart) {
          throw const ServerException(
            'The stored monthly score no longer matches this calculation.',
          );
        }
        transaction.update(reference, {
          'latestCalculation': SmartMoneyScoreModel.calculationToFirestore(
            calculation,
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } on FirebaseException catch (error) {
      throw ServerException(
        error.message ?? 'Could not save the Smart Money Score calculation.',
      );
    }
  }

  void _validateOpening(SmartMoneyScoreOpening candidate) {
    if (candidate.monthStart.day != 1 ||
        candidate.currencyCode.trim().isEmpty ||
        !candidate.openingBalance.isFinite) {
      throw const ServerException(
        'The monthly score opening balance is invalid.',
      );
    }
  }
}
