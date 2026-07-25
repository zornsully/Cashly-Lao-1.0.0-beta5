import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/data/models/account_model.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'fromFirestore maps a stored document back to an AccountModel',
    () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('accounts').doc('acc-1');

      await docRef.set({
        'name': 'Main Wallet',
        'type': 'wallet',
        'balance': 125000.5,
        'currencyCode': 'LAK',
        'icon': 'wallet',
        'color': 'emerald',
        'isArchived': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
      });

      final snapshot = await docRef.get();
      final model = AccountModel.fromFirestore(snapshot);

      expect(model.id, 'acc-1');
      expect(model.name, 'Main Wallet');
      expect(model.type, AccountType.wallet);
      expect(model.balance, 125000.5);
      expect(model.currencyCode, 'LAK');
      expect(model.icon, AppIconKey.wallet);
      expect(model.color, AppColorKey.emerald);
      expect(model.isArchived, isFalse);
      expect(model.createdAt, DateTime(2026, 1, 1));
      expect(model.updatedAt, DateTime(2026, 1, 2));
    },
  );

  test('defaults isArchived to false when the field is absent', () async {
    final firestore = FakeFirebaseFirestore();
    final docRef = firestore.collection('accounts').doc('acc-2');

    await docRef.set({
      'name': 'Bank Account',
      'type': 'bank',
      'balance': 0,
      'currencyCode': 'USD',
      'icon': 'bank',
      'color': 'blue',
    });

    final snapshot = await docRef.get();
    final model = AccountModel.fromFirestore(snapshot);

    expect(model.isArchived, isFalse);
  });

  test('toFirestoreUpdate serializes enum fields by name', () async {
    final model = AccountModel(
      id: 'acc-3',
      name: 'Credit Card',
      type: AccountType.creditCard,
      balance: -450.0,
      currencyCode: 'USD',
      icon: AppIconKey.creditCard,
      color: AppColorKey.red,
      isArchived: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final map = model.toFirestoreUpdate();

    expect(map['name'], 'Credit Card');
    expect(map['type'], 'creditCard');
    expect(map['balance'], -450.0);
    expect(map['icon'], 'creditCard');
    expect(map['color'], 'red');
    expect(map['isArchived'], isTrue);
  });
}
