import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/goal_contribution_frequency.dart';
import '../models/savings_goal_model.dart';

abstract interface class SavingsGoalRemoteDataSource {
  Stream<List<SavingsGoalModel>> watchGoals();

  /// Fails if [accountId] already backs another active (non-archived)
  /// goal — see `SavingsGoalRepository.createGoal`.
  Future<SavingsGoalModel> createGoal({
    required String name,
    required double targetAmount,
    required String accountId,
    required AppIconKey icon,
    required AppColorKey color,
    double? autoContributionAmount,
    GoalContributionFrequency? autoContributionFrequency,
  });

  Future<void> updateGoal({
    required String id,
    required String name,
    required double targetAmount,
    required AppIconKey icon,
    required AppColorKey color,
    double? autoContributionAmount,
    GoalContributionFrequency? autoContributionFrequency,
  });

  Future<void> archiveGoal(String id);

  Future<void> unarchiveGoal(String id);

  Future<void> deleteGoal(String id);

  Future<void> recordContribution({
    required String goalId,
    required DateTime contributedAt,
  });
}

class FirestoreSavingsGoalRemoteDataSource
    implements SavingsGoalRemoteDataSource {
  FirestoreSavingsGoalRemoteDataSource({
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
      .collection(FirestorePaths.savingsGoals);

  @override
  Stream<List<SavingsGoalModel>> watchGoals() {
    return _collection
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(SavingsGoalModel.fromFirestore).toList(),
        );
  }

  @override
  Future<SavingsGoalModel> createGoal({
    required String name,
    required double targetAmount,
    required String accountId,
    required AppIconKey icon,
    required AppColorKey color,
    double? autoContributionAmount,
    GoalContributionFrequency? autoContributionFrequency,
  }) async {
    try {
      // Progress is simply the linked account's own balance (see
      // SavingsGoalProgress), so an account backing two active goals at
      // once would show identical progress for both — block it here the
      // same "check, then write" way FirestoreBudgetRemoteDataSource
      // prevents a duplicate category+month budget.
      final existingActive = await _collection
          .where('accountId', isEqualTo: accountId)
          .where('isArchived', isEqualTo: false)
          .limit(1)
          .get();
      if (existingActive.docs.isNotEmpty) {
        throw const ServerException(
          'This account already backs another active savings goal.',
        );
      }

      final docRef = _collection.doc();
      final now = DateTime.now();
      await docRef.set({
        'name': name,
        'targetAmount': targetAmount,
        'accountId': accountId,
        'icon': icon.name,
        'color': color.name,
        'isArchived': false,
        'autoContributionAmount': autoContributionAmount ?? 0,
        'autoContributionFrequency': autoContributionFrequency?.name ?? '',
        'lastContributionAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return SavingsGoalModel(
        id: docRef.id,
        name: name,
        targetAmount: targetAmount,
        accountId: accountId,
        icon: icon,
        color: color,
        isArchived: false,
        autoContributionAmount: autoContributionAmount,
        autoContributionFrequency: autoContributionFrequency,
        lastContributionAt: now,
        createdAt: now,
        updatedAt: now,
      );
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Could not create the savings goal.',
      );
    }
  }

  @override
  Future<void> updateGoal({
    required String id,
    required String name,
    required double targetAmount,
    required AppIconKey icon,
    required AppColorKey color,
    double? autoContributionAmount,
    GoalContributionFrequency? autoContributionFrequency,
  }) async {
    try {
      await _collection.doc(id).update({
        'name': name,
        'targetAmount': targetAmount,
        'icon': icon.name,
        'color': color.name,
        'autoContributionAmount': autoContributionAmount ?? 0,
        'autoContributionFrequency': autoContributionFrequency?.name ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Could not update the savings goal.',
      );
    }
  }

  @override
  Future<void> archiveGoal(String id) => _setArchived(id, archived: true);

  @override
  Future<void> unarchiveGoal(String id) =>
      _setArchived(id, archived: false);

  Future<void> _setArchived(String id, {required bool archived}) async {
    try {
      await _collection.doc(id).update({
        'isArchived': archived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Could not update the savings goal.',
      );
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      await _collection.doc(id).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Could not delete the savings goal.',
      );
    }
  }

  @override
  Future<void> recordContribution({
    required String goalId,
    required DateTime contributedAt,
  }) async {
    try {
      await _collection.doc(goalId).update({
        'lastContributionAt': Timestamp.fromDate(contributedAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Could not record the contribution.',
      );
    }
  }
}
