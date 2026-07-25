import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/categories/data/models/category_model.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'fromFirestore maps a stored document back to a CategoryModel',
    () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('categories').doc('cat-1');

      await docRef.set({
        'name': 'Salary',
        'type': 'income',
        'icon': 'work',
        'color': 'green',
        'isDefault': true,
        'isArchived': false,
        'sortOrder': 0,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
      });

      final snapshot = await docRef.get();
      final model = CategoryModel.fromFirestore(snapshot);

      expect(model.id, 'cat-1');
      expect(model.name, 'Salary');
      expect(model.type, CategoryType.income);
      expect(model.icon, AppIconKey.work);
      expect(model.color, AppColorKey.green);
      expect(model.isDefault, isTrue);
      expect(model.isArchived, isFalse);
      expect(model.sortOrder, 0);
      expect(model.createdAt, DateTime(2026, 1, 1));
    },
  );

  test('defaults isDefault/isArchived/sortOrder when absent', () async {
    final firestore = FakeFirebaseFirestore();
    final docRef = firestore.collection('categories').doc('cat-2');

    await docRef.set({
      'name': 'Custom',
      'type': 'expense',
      'icon': 'other',
      'color': 'grey',
    });

    final snapshot = await docRef.get();
    final model = CategoryModel.fromFirestore(snapshot);

    expect(model.isDefault, isFalse);
    expect(model.isArchived, isFalse);
    expect(model.sortOrder, 0);
  });

  test('toFirestoreUpdate serializes enum fields by name', () {
    final model = CategoryModel(
      id: 'cat-3',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: AppIconKey.groceries,
      color: AppColorKey.amber,
      isDefault: false,
      isArchived: true,
      sortOrder: 3,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final map = model.toFirestoreUpdate();

    expect(map['name'], 'Groceries');
    expect(map['type'], 'expense');
    expect(map['icon'], 'groceries');
    expect(map['color'], 'amber');
    expect(map['isDefault'], isFalse);
    expect(map['isArchived'], isTrue);
    expect(map['sortOrder'], 3);
  });
}
