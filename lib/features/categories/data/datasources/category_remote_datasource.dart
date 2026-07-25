import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/category_type.dart';
import 'default_categories.dart';
import '../models/category_model.dart';

abstract interface class CategoryRemoteDataSource {
  Stream<List<CategoryModel>> watchCategories();

  Future<void> ensureDefaultCategories();

  Future<CategoryModel> createCategory({
    required String name,
    required CategoryType type,
    required AppIconKey icon,
    required AppColorKey color,
  });

  Future<void> updateCategory({
    required String id,
    required String name,
    required CategoryType type,
    required AppIconKey icon,
    required AppColorKey color,
  });

  Future<void> archiveCategory(String id);

  Future<void> unarchiveCategory(String id);

  Future<void> deleteCategory(String id);

  Future<void> reorderCategories(List<String> orderedIds);
}

class FirestoreCategoryRemoteDataSource implements CategoryRemoteDataSource {
  FirestoreCategoryRemoteDataSource({
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
      _userDoc.collection(FirestorePaths.categories);

  @override
  Stream<List<CategoryModel>> watchCategories() {
    return _collection
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(CategoryModel.fromFirestore).toList(),
        );
  }

  @override
  Future<void> ensureDefaultCategories() async {
    try {
      final userSnapshot = await _userDoc.get();
      final alreadySeeded =
          userSnapshot.data()?[FirestorePaths.defaultCategoriesSeededField]
              as bool? ??
          false;
      if (alreadySeeded) return;

      final batch = _firestore.batch();
      final typeCounters = <CategoryType, int>{};

      for (final seed in defaultCategorySeeds) {
        final sortOrder = typeCounters.update(
          seed.type,
          (value) => value + 1,
          ifAbsent: () => 0,
        );
        final docRef = _collection.doc();
        batch.set(docRef, {
          'name': seed.name,
          'type': seed.type.name,
          'icon': seed.icon.name,
          'color': seed.color.name,
          'isDefault': true,
          'isArchived': false,
          'sortOrder': sortOrder,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      batch.set(_userDoc, {
        FirestorePaths.defaultCategoriesSeededField: true,
      }, SetOptions(merge: true));

      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Could not set up your default categories.',
      );
    }
  }

  @override
  Future<CategoryModel> createCategory({
    required String name,
    required CategoryType type,
    required AppIconKey icon,
    required AppColorKey color,
  }) async {
    try {
      final existingOfType = await _collection
          .where('type', isEqualTo: type.name)
          .get();
      final sortOrder = existingOfType.docs.length;

      final docRef = _collection.doc();
      final now = DateTime.now();
      await docRef.set({
        'name': name,
        'type': type.name,
        'icon': icon.name,
        'color': color.name,
        'isDefault': false,
        'isArchived': false,
        'sortOrder': sortOrder,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return CategoryModel(
        id: docRef.id,
        name: name,
        type: type,
        icon: icon,
        color: color,
        isDefault: false,
        isArchived: false,
        sortOrder: sortOrder,
        createdAt: now,
        updatedAt: now,
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not create the category.');
    }
  }

  @override
  Future<void> updateCategory({
    required String id,
    required String name,
    required CategoryType type,
    required AppIconKey icon,
    required AppColorKey color,
  }) async {
    try {
      await _collection.doc(id).update({
        'name': name,
        'type': type.name,
        'icon': icon.name,
        'color': color.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not update the category.');
    }
  }

  @override
  Future<void> archiveCategory(String id) => _setArchived(id, archived: true);

  @override
  Future<void> unarchiveCategory(String id) =>
      _setArchived(id, archived: false);

  Future<void> _setArchived(String id, {required bool archived}) async {
    try {
      await _collection.doc(id).update({
        'isArchived': archived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not update the category.');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      final isDefault = doc.data()?['isDefault'] as bool? ?? false;
      if (isDefault) {
        throw const ServerException(
          "Default categories can't be deleted — archive it instead.",
        );
      }
      await _collection.doc(id).delete();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not delete the category.');
    }
  }

  @override
  Future<void> reorderCategories(List<String> orderedIds) async {
    try {
      final batch = _firestore.batch();
      for (var i = 0; i < orderedIds.length; i++) {
        batch.update(_collection.doc(orderedIds[i]), {
          'sortOrder': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Could not save the new order.');
    }
  }
}
