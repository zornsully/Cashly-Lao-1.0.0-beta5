import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/features/accounts/data/datasources/account_remote_datasource.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
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
  late FirestoreAccountRemoteDataSource dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    firebaseAuth = _MockFirebaseAuth();
    user = _MockUser();
    when(() => user.uid).thenReturn('uid-1');
    when(() => firebaseAuth.currentUser).thenReturn(user);
    dataSource = FirestoreAccountRemoteDataSource(
      firestore: firestore,
      firebaseAuth: firebaseAuth,
    );
  });

  test('createAccount writes under users/{uid}/accounts', () async {
    final created = await dataSource.createAccount(
      name: 'Cash',
      type: AccountType.cash,
      initialBalance: 100,
      currencyCode: 'LAK',
      icon: AppIconKey.cash,
      color: AppColorKey.emerald,
    );

    final doc = await firestore
        .collection('users')
        .doc('uid-1')
        .collection('accounts')
        .doc(created.id)
        .get();

    expect(doc.exists, isTrue);
    expect(doc.data()!['name'], 'Cash');
    expect(doc.data()!['balance'], 100);
    expect(created.name, 'Cash');
    expect(created.balance, 100);
  });

  test('watchAccounts emits accounts created for the current user', () async {
    await dataSource.createAccount(
      name: 'Wallet',
      type: AccountType.wallet,
      initialBalance: 50,
      currencyCode: 'LAK',
      icon: AppIconKey.wallet,
      color: AppColorKey.blue,
    );

    final accounts = await dataSource.watchAccounts().first;

    expect(accounts, hasLength(1));
    expect(accounts.first.name, 'Wallet');
  });

  test('updateAccount does not modify currencyCode', () async {
    final created = await dataSource.createAccount(
      name: 'USD account',
      type: AccountType.bank,
      initialBalance: 100,
      currencyCode: 'USD',
      icon: AppIconKey.bank,
      color: AppColorKey.blue,
    );

    await dataSource.updateAccount(
      id: created.id,
      name: 'USD account renamed',
      type: AccountType.bank,
      balance: 150,
      icon: AppIconKey.bank,
      color: AppColorKey.blue,
    );

    final doc = await firestore
        .collection('users')
        .doc('uid-1')
        .collection('accounts')
        .doc(created.id)
        .get();

    expect(doc.data()!['currencyCode'], 'USD');
    expect(doc.data()!['name'], 'USD account renamed');
    expect(doc.data()!['balance'], 150);
  });

  test('archiveAccount then unarchiveAccount toggles isArchived', () async {
    final created = await dataSource.createAccount(
      name: 'Savings',
      type: AccountType.savings,
      initialBalance: 0,
      currencyCode: 'LAK',
      icon: AppIconKey.savings,
      color: AppColorKey.teal,
    );

    await dataSource.archiveAccount(created.id);
    var accounts = await dataSource.watchAccounts().first;
    expect(accounts.single.isArchived, isTrue);

    await dataSource.unarchiveAccount(created.id);
    accounts = await dataSource.watchAccounts().first;
    expect(accounts.single.isArchived, isFalse);
  });

  test('deleteAccount removes the document', () async {
    final created = await dataSource.createAccount(
      name: 'Old account',
      type: AccountType.cash,
      initialBalance: 0,
      currencyCode: 'LAK',
      icon: AppIconKey.cash,
      color: AppColorKey.grey,
    );

    await dataSource.deleteAccount(created.id);

    final accounts = await dataSource.watchAccounts().first;
    expect(accounts, isEmpty);
  });

  test('deleteAccount throws ServerException when transactions reference the '
      'account', () async {
    final created = await dataSource.createAccount(
      name: 'Referenced account',
      type: AccountType.cash,
      initialBalance: 0,
      currencyCode: 'LAK',
      icon: AppIconKey.cash,
      color: AppColorKey.grey,
    );
    await firestore
        .collection('users')
        .doc('uid-1')
        .collection('transactions')
        .add({'accountId': created.id});

    expect(
      () => dataSource.deleteAccount(created.id),
      throwsA(isA<ServerException>()),
    );

    final accounts = await dataSource.watchAccounts().first;
    expect(accounts, hasLength(1));
  });

  test('deleteAccount throws ServerException when a transfer targets the '
      'account as its destination', () async {
    final created = await dataSource.createAccount(
      name: 'Transfer destination',
      type: AccountType.cash,
      initialBalance: 0,
      currencyCode: 'LAK',
      icon: AppIconKey.cash,
      color: AppColorKey.grey,
    );
    await firestore
        .collection('users')
        .doc('uid-1')
        .collection('transactions')
        .add({'accountId': 'some-other-account', 'toAccountId': created.id});

    expect(
      () => dataSource.deleteAccount(created.id),
      throwsA(isA<ServerException>()),
    );

    final accounts = await dataSource.watchAccounts().first;
    expect(accounts, hasLength(1));
  });

  test('deleteAccount throws ServerException when an active savings goal '
      'references the account', () async {
    final created = await dataSource.createAccount(
      name: 'Goal-linked account',
      type: AccountType.savings,
      initialBalance: 0,
      currencyCode: 'LAK',
      icon: AppIconKey.savings,
      color: AppColorKey.grey,
    );
    await firestore
        .collection('users')
        .doc('uid-1')
        .collection('savingsGoals')
        .add({'accountId': created.id, 'isArchived': false});

    expect(
      () => dataSource.deleteAccount(created.id),
      throwsA(isA<ServerException>()),
    );

    final accounts = await dataSource.watchAccounts().first;
    expect(accounts, hasLength(1));
  });

  test('deleteAccount succeeds when the only referencing savings goal is '
      'archived', () async {
    final created = await dataSource.createAccount(
      name: 'Formerly goal-linked account',
      type: AccountType.savings,
      initialBalance: 0,
      currencyCode: 'LAK',
      icon: AppIconKey.savings,
      color: AppColorKey.grey,
    );
    await firestore
        .collection('users')
        .doc('uid-1')
        .collection('savingsGoals')
        .add({'accountId': created.id, 'isArchived': true});

    await dataSource.deleteAccount(created.id);

    final accounts = await dataSource.watchAccounts().first;
    expect(accounts, isEmpty);
  });

  test('throws AuthException when there is no signed-in user', () async {
    when(() => firebaseAuth.currentUser).thenReturn(null);

    expect(
      () => dataSource.createAccount(
        name: 'Cash',
        type: AccountType.cash,
        initialBalance: 0,
        currencyCode: 'LAK',
        icon: AppIconKey.cash,
        color: AppColorKey.emerald,
      ),
      throwsA(isA<AuthException>()),
    );
  });
}
