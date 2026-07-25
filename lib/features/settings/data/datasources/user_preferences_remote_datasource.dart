import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_language.dart';
import '../../../../core/constants/app_theme_mode.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_preferences_model.dart';

abstract interface class UserPreferencesRemoteDataSource {
  Stream<UserPreferencesModel> watchPreferences();

  Future<void> updateThemeMode(AppThemeModePreference mode);

  Future<void> updateDefaultCurrency(String currencyCode);

  Future<void> updateLanguage(AppLanguage language);

  Future<void> updateAppLockEnabled(bool enabled);

  Future<void> updateNotificationsEnabled(bool enabled);
}

class FirestoreUserPreferencesRemoteDataSource
    implements UserPreferencesRemoteDataSource {
  FirestoreUserPreferencesRemoteDataSource({
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

  @override
  Stream<UserPreferencesModel> watchPreferences() {
    return _userDoc.snapshots().map(UserPreferencesModel.fromFirestore);
  }

  @override
  Future<void> updateThemeMode(AppThemeModePreference mode) async {
    try {
      await _userDoc.set({
        'themeMode': mode.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not update your theme.');
    }
  }

  @override
  Future<void> updateDefaultCurrency(String currencyCode) async {
    try {
      await _userDoc.set({
        'defaultCurrencyCode': currencyCode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Could not update your default currency.',
      );
    }
  }

  @override
  Future<void> updateLanguage(AppLanguage language) async {
    try {
      await _userDoc.set({
        'language': language.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not update your language.');
    }
  }

  @override
  Future<void> updateAppLockEnabled(bool enabled) async {
    try {
      await _userDoc.set({
        'appLockEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not update app lock.');
    }
  }

  @override
  Future<void> updateNotificationsEnabled(bool enabled) async {
    try {
      await _userDoc.set({
        'notificationsEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not update notifications.');
    }
  }
}
