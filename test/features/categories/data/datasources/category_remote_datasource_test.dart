import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseAuth firebaseAuth;
  late _MockUser user;
  late FirestoreCategoryRemoteDataSource dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    firebaseAuth = _MockFirebaseAuth();
    user = _MockUser();
    when(() => user.uid).thenReturn('uid-1');
    when(() => firebaseAuth.currentUser).thenReturn(user);
    dataSource = FirestoreCategoryRemoteDataSource(
      firestore: firestore,
      firebaseAuth: firebaseAuth,
    );
  });

  test(
    'ensureDefaultCategories seeds the curated set and marks the user as seeded',
    () async {
      await dataSource.ensureDefaultCategories();

      final categories = await dataSource.watchCategories().first;
      expect(categories, hasLength(15));
      expect(categories.every((c) => c.isDefault), isTrue);

      final incomeCount = categories
          .where((c) => c.type == CategoryType.income)
          .length;
      final expenseCount = categories
          .where((c) => c.type == CategoryType.expense)
          .length;
      expect(incomeCount, 5);
      expect(expenseCount, 10);

      final userDoc = await firestore.collection('users').doc('uid-1').get();
      expect(userDoc.data()!['defaultCategoriesSeeded'], isTrue);
    },
  );

  test('ensureDefaultCategories is a no-op on the second call', () async {
    await dataSource.ensureDefaultCategories();
    await dataSource.ensureDefaultCategories();

    final categories = await dataSource.watchCategories().first;
    expect(categories, hasLength(15));
  });

  test(
    'createCategory assigns sortOrder based on existing count for its type',
    () async {
      final first = await dataSource.createCategory(
        name: 'Freelance',
        type: CategoryType.income,
        icon: AppIconKey.work,
        color: AppColorKey.green,
      );
      final second = await dataSource.createCategory(
        name: 'Bonus',
        type: CategoryType.income,
        icon: AppIconKey.gift,
        color: AppColorKey.pink,
      );

      expect(first.sortOrder, 0);
      expect(second.sortOrder, 1);
      expect(first.isDefault, isFalse);
    },
  );

  test('deleteCategory throws for a default category', () async {
    final created = await dataSource.createCategory(
      name: 'Temp',
      type: CategoryType.expense,
      icon: AppIconKey.other,
      color: AppColorKey.grey,
    );
    // Simulate a default category by seeding then picking one of them.
    await dataSource.ensureDefaultCategories();
    final defaults = await dataSource.watchCategories().first;
    final defaultCategory = defaults.firstWhere((c) => c.isDefault);

    expect(
      () => dataSource.deleteCategory(defaultCategory.id),
      throwsA(isA<ServerException>()),
    );

    // A non-default (custom) category can still be deleted.
    await dataSource.deleteCategory(created.id);
    final remaining = await dataSource.watchCategories().first;
    expect(remaining.any((c) => c.id == created.id), isFalse);
  });

  test('reorderCategories persists the new sortOrder for each id', () async {
    final a = await dataSource.createCategory(
      name: 'A',
      type: CategoryType.expense,
      icon: AppIconKey.other,
      color: AppColorKey.grey,
    );
    final b = await dataSource.createCategory(
      name: 'B',
      type: CategoryType.expense,
      icon: AppIconKey.other,
      color: AppColorKey.grey,
    );

    await dataSource.reorderCategories([b.id, a.id]);

    final categories = await dataSource.watchCategories().first;
    final reorderedB = categories.firstWhere((c) => c.id == b.id);
    final reorderedA = categories.firstWhere((c) => c.id == a.id);
    expect(reorderedB.sortOrder, 0);
    expect(reorderedA.sortOrder, 1);
  });

  test('archiveCategory then unarchiveCategory toggles isArchived', () async {
    final created = await dataSource.createCategory(
      name: 'Side hustle',
      type: CategoryType.income,
      icon: AppIconKey.work,
      color: AppColorKey.teal,
    );

    await dataSource.archiveCategory(created.id);
    var categories = await dataSource.watchCategories().first;
    expect(categories.single.isArchived, isTrue);

    await dataSource.unarchiveCategory(created.id);
    categories = await dataSource.watchCategories().first;
    expect(categories.single.isArchived, isFalse);
  });
}
