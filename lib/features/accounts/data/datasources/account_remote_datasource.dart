import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/account_type.dart';
import '../models/account_model.dart';

abstract interface class AccountRemoteDataSource {
  Stream<List<AccountModel>> watchAccounts();

  Future<AccountModel> createAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    required String currencyCode,
    required AppIconKey icon,
    required AppColorKey color,
  });

  Future<void> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required double balance,
    required String currencyCode,
    required AppIconKey icon,
    required AppColorKey color,
  });

  Future<void> archiveAccount(String id);

  Future<void> unarchiveAccount(String id);

  Future<void> deleteAccount(String id);
}

class FirestoreAccountRemoteDataSource implements AccountRemoteDataSource {
  FirestoreAccountRemoteDataSource({
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
      _userDoc.collection(FirestorePaths.accounts);

  @override
  Stream<List<AccountModel>> watchAccounts() {
    return _collection
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(AccountModel.fromFirestore).toList(),
        );
  }

  @override
  Future<AccountModel> createAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    required String currencyCode,
    required AppIconKey icon,
    required AppColorKey color,
  }) async {
    try {
      final docRef = _collection.doc();
      final now = DateTime.now();
      await docRef.set({
        'name': name,
        'type': type.name,
        'balance': initialBalance,
        'currencyCode': currencyCode,
        'icon': icon.name,
        'color': color.name,
        'isArchived': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return AccountModel(
        id: docRef.id,
        name: name,
        type: type,
        balance: initialBalance,
        currencyCode: currencyCode,
        icon: icon,
        color: color,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not create the account.');
    }
  }

  @override
  Future<void> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required double balance,
    required String currencyCode,
    required AppIconKey icon,
    required AppColorKey color,
  }) async {
    try {
      await _collection.doc(id).update({
        'name': name,
        'type': type.name,
        'balance': balance,
        'currencyCode': currencyCode,
        'icon': icon.name,
        'color': color.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not update the account.');
    }
  }

  @override
  Future<void> archiveAccount(String id) => _setArchived(id, archived: true);

  @override
  Future<void> unarchiveAccount(String id) => _setArchived(id, archived: false);

  Future<void> _setArchived(String id, {required bool archived}) async {
    try {
      await _collection.doc(id).update({
        'isArchived': archived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not update the account.');
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      // Hard-deleting an account that still has transactions would orphan
      // them: they'd keep showing up in the transactions list but silently
      // drop out of every dashboard/report total, since those aggregators
      // skip any transaction whose account can't be resolved. Archive is
      // the safe alternative already offered in the UI for this case.
      // Checked both as the primary account (income/expense, and a
      // transfer's source) and as a transfer's destination — either one
      // orphans the transaction the same way.
      final transactions = _userDoc.collection(FirestorePaths.transactions);
      final referencingAsAccount = await transactions
          .where('accountId', isEqualTo: id)
          .limit(1)
          .get();
      final hasReferencingTransactions = referencingAsAccount.docs.isNotEmpty
          ? true
          : (await transactions
                    .where('toAccountId', isEqualTo: id)
                    .limit(1)
                    .get())
                .docs
                .isNotEmpty;
      if (hasReferencingTransactions) {
        throw const ServerException(
          "This account has transactions and can't be deleted — archive it "
          'instead.',
        );
      }

      // A savings goal's progress *is* its linked account's balance (see
      // SavingsGoalProgress) — deleting the account out from under an
      // active goal would leave it pointing at nothing. A goal with zero
      // contributions yet has no transactions, so the check above alone
      // wouldn't catch this case.
      final referencingGoals = await _userDoc
          .collection(FirestorePaths.savingsGoals)
          .where('accountId', isEqualTo: id)
          .where('isArchived', isEqualTo: false)
          .limit(1)
          .get();
      if (referencingGoals.docs.isNotEmpty) {
        throw const ServerException(
          "This account backs an active savings goal and can't be deleted "
          '— archive the goal first.',
        );
      }

      await _collection.doc(id).delete();
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not delete the account.');
    }
  }
}
