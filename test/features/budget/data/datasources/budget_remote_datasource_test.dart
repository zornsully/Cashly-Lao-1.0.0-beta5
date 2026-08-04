import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/features/budget/data/datasources/budget_remote_datasource.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseAuth firebaseAuth;
  late FirestoreBudgetRemoteDataSource dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    firebaseAuth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('uid-1');
    when(() => firebaseAuth.currentUser).thenReturn(user);
    dataSource = FirestoreBudgetRemoteDataSource(
      firestore: firestore,
      firebaseAuth: firebaseAuth,
    );
  });

  test(
    'createBudget uses a deterministic categoryId_yyyy-MM document id',
    () async {
      final created = await dataSource.createBudget(
        categoryId: 'food',
        month: DateTime(2026, 3, 15),
        limitAmount: 500000,
        currencyCode: 'LAK',
      );

      expect(created.id, 'food_2026-03');
      expect(created.month, DateTime.utc(2026, 3));

      final doc = await firestore
          .collection('users')
          .doc('uid-1')
          .collection('budgets')
          .doc('food_2026-03')
          .get();
      expect(doc.exists, isTrue);
    },
  );

  test(
    'createBudget throws when a budget already exists for that category/month',
    () async {
      await dataSource.createBudget(
        categoryId: 'food',
        month: DateTime(2026, 3),
        limitAmount: 500000,
        currencyCode: 'LAK',
      );

      expect(
        () => dataSource.createBudget(
          categoryId: 'food',
          month: DateTime(2026, 3),
          limitAmount: 999,
          currencyCode: 'LAK',
        ),
        throwsA(isA<ServerException>()),
      );
    },
  );

  test('createBudget allows the same category in a different month', () async {
    await dataSource.createBudget(
      categoryId: 'food',
      month: DateTime(2026, 3),
      limitAmount: 500000,
      currencyCode: 'LAK',
    );

    final aprilBudget = await dataSource.createBudget(
      categoryId: 'food',
      month: DateTime(2026, 4),
      limitAmount: 600000,
      currencyCode: 'LAK',
    );

    expect(aprilBudget.id, 'food_2026-04');
  });

  test(
    'updateBudget changes the limit and currency without affecting category/month',
    () async {
      final created = await dataSource.createBudget(
        categoryId: 'food',
        month: DateTime(2026, 3),
        limitAmount: 500000,
        currencyCode: 'LAK',
      );

      await dataSource.updateBudget(
        id: created.id,
        limitAmount: 700000,
        currencyCode: 'LAK',
      );

      final updated = await dataSource
          .watchBudgetsForMonth(DateTime(2026, 3))
          .first;
      expect(updated.single.limitAmount, 700000);
      expect(updated.single.categoryId, 'food');
    },
  );

  test('deleteBudget removes the document', () async {
    final created = await dataSource.createBudget(
      categoryId: 'food',
      month: DateTime(2026, 3),
      limitAmount: 500000,
      currencyCode: 'LAK',
    );

    await dataSource.deleteBudget(created.id);

    final remaining = await dataSource
        .watchBudgetsForMonth(DateTime(2026, 3))
        .first;
    expect(remaining, isEmpty);
  });

  test('watchBudgetsForMonth only returns budgets for that month', () async {
    await dataSource.createBudget(
      categoryId: 'food',
      month: DateTime(2026, 3),
      limitAmount: 500000,
      currencyCode: 'LAK',
    );
    await dataSource.createBudget(
      categoryId: 'transport',
      month: DateTime(2026, 4),
      limitAmount: 200000,
      currencyCode: 'LAK',
    );

    final march = await dataSource
        .watchBudgetsForMonth(DateTime(2026, 3))
        .first;
    expect(march, hasLength(1));
    expect(march.single.categoryId, 'food');
  });

  test('keeps one user\'s budgets out of another user\'s collection', () async {
    await dataSource.createBudget(
      categoryId: 'food',
      month: DateTime(2026, 3),
      limitAmount: 500000,
      currencyCode: 'LAK',
    );

    final otherUser = _MockUser();
    when(() => otherUser.uid).thenReturn('uid-2');
    when(() => firebaseAuth.currentUser).thenReturn(otherUser);

    expect(
      await dataSource.watchBudgetsForMonth(DateTime(2026, 3)).first,
      isEmpty,
    );
  });

  test('rejects zero, negative, NaN, and infinite budget amounts', () async {
    for (final limit in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        () => dataSource.createBudget(
          categoryId: 'food',
          month: DateTime(2026, 3),
          limitAmount: limit,
          currencyCode: 'LAK',
        ),
        throwsA(isA<ServerException>()),
      );
    }
  });
}
