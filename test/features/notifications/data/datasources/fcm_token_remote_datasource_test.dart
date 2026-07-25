import 'package:cashly_lao/features/notifications/data/datasources/fcm_token_remote_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseAuth firebaseAuth;
  late FirestoreFcmTokenRemoteDataSource dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    firebaseAuth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('uid-1');
    when(() => firebaseAuth.currentUser).thenReturn(user);
    dataSource = FirestoreFcmTokenRemoteDataSource(
      firestore: firestore,
      firebaseAuth: firebaseAuth,
    );
  });

  DocumentReference<Map<String, dynamic>> tokenDoc(String token) => firestore
      .collection('users')
      .doc('uid-1')
      .collection('fcmTokens')
      .doc(token);

  test('registerToken creates a doc keyed by the token value itself', () async {
    await dataSource.registerToken(token: 'token-a', platform: 'android');

    final doc = await tokenDoc('token-a').get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['token'], 'token-a');
    expect(doc.data()!['platform'], 'android');
    expect(doc.data()!['createdAt'], isNotNull);
    expect(doc.data()!['updatedAt'], isNotNull);
  });

  test(
    'registering the same token again updates platform without touching createdAt',
    () async {
      await dataSource.registerToken(token: 'token-a', platform: 'android');
      final createdAtFirst = (await tokenDoc('token-a').get()).data()!['createdAt'];

      await dataSource.registerToken(token: 'token-a', platform: 'ios');

      final doc = await tokenDoc('token-a').get();
      expect(doc.data()!['platform'], 'ios');
      expect(doc.data()!['createdAt'], createdAtFirst);
    },
  );

  test('unregisterToken removes the doc', () async {
    await dataSource.registerToken(token: 'token-a', platform: 'android');

    await dataSource.unregisterToken('token-a');

    final doc = await tokenDoc('token-a').get();
    expect(doc.exists, isFalse);
  });

  test('unregisterToken is a no-op when the token was never registered', () async {
    await expectLater(dataSource.unregisterToken('never-registered'), completes);
  });
}
