import 'package:cashly_lao/features/budget/data/models/budget_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromFirestore maps a stored document back to a BudgetModel', () async {
    final firestore = FakeFirebaseFirestore();
    final docRef = firestore.collection('budgets').doc('food_2026-03');

    await docRef.set({
      'categoryId': 'food',
      'month': Timestamp.fromDate(DateTime(2026, 3)),
      'limitAmount': 500000.0,
      'currencyCode': 'LAK',
      'createdAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
    });

    final snapshot = await docRef.get();
    final model = BudgetModel.fromFirestore(snapshot);

    expect(model.id, 'food_2026-03');
    expect(model.categoryId, 'food');
    expect(model.month, DateTime(2026, 3));
    expect(model.limitAmount, 500000.0);
    expect(model.currencyCode, 'LAK');
  });
}
