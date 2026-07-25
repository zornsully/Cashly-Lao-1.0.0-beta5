import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUserInfo extends Mock implements UserInfo {}

class _MockUserMetadata extends Mock implements UserMetadata {}

void main() {
  late _MockFirebaseAuth firebaseAuth;
  late FirebaseFirestore firestore;
  late AuthRemoteDataSource dataSource;

  setUpAll(() {
    registerFallbackValue(
      EmailAuthProvider.credential(email: 'fallback@example.com', password: 'x'),
    );
  });

  setUp(() {
    firebaseAuth = _MockFirebaseAuth();
    firestore = FakeFirebaseFirestore();
    dataSource = FirebaseAuthRemoteDataSource(
      firebaseAuth: firebaseAuth,
      firestore: firestore,
    );
  });

  test(
    'authStateChanges() is backed by userChanges(), not authStateChanges() '
    '— required so the verify-email and edit-name screens update reactively '
    'after reload()/updateProfile() calls, which only notify userChanges()',
    () {
      final userStream = Stream<User?>.value(_MockUser());
      when(() => firebaseAuth.userChanges()).thenAnswer((_) => userStream);

      final result = dataSource.authStateChanges();

      expect(result, same(userStream));
      verify(() => firebaseAuth.userChanges()).called(1);
      verifyNever(() => firebaseAuth.authStateChanges());
    },
  );

  group('login', () {
    setUp(() {
      final user = _MockUser();
      final metadata = _MockUserMetadata();
      when(() => metadata.creationTime).thenReturn(DateTime(2026, 1, 1));
      when(() => user.uid).thenReturn('uid-1');
      when(() => user.email).thenReturn('test@example.com');
      when(() => user.emailVerified).thenReturn(true);
      when(() => user.displayName).thenReturn('Test User');
      when(() => user.photoURL).thenReturn(null);
      when(() => user.providerData).thenReturn(const []);
      when(() => user.metadata).thenReturn(metadata);

      final credential = _MockUserCredential();
      when(() => credential.user).thenReturn(user);
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);
    });

    test('seeds users/{uid} when the profile doc is missing', () async {
      final result = await dataSource.login(
        email: 'test@example.com',
        password: 'correct-password',
      );

      expect(result.uid, 'uid-1');
      final doc = await firestore.collection('users').doc('uid-1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['email'], 'test@example.com');
    });

    test(
      'leaves an existing profile doc untouched — does not re-stamp '
      'createdAt or clobber fields set elsewhere (e.g. Settings)',
      () async {
        final userDoc = firestore.collection('users').doc('uid-1');
        await userDoc.set({
          'uid': 'uid-1',
          'email': 'test@example.com',
          'createdAt': Timestamp.fromDate(DateTime(2020, 1, 1)),
          'themeMode': 'dark',
        });

        await dataSource.login(
          email: 'test@example.com',
          password: 'correct-password',
        );

        final data = (await userDoc.get()).data();
        expect(data?['createdAt'], Timestamp.fromDate(DateTime(2020, 1, 1)));
        expect(data?['themeMode'], 'dark');
      },
    );
  });

  group('deleteAccount', () {
    late _MockUser user;

    setUp(() {
      user = _MockUser();
      final passwordProviderInfo = _MockUserInfo();
      when(() => passwordProviderInfo.providerId).thenReturn('password');

      when(() => user.uid).thenReturn('uid-1');
      when(() => user.email).thenReturn('test@example.com');
      when(() => user.providerData).thenReturn([passwordProviderInfo]);
      when(
        () => user.reauthenticateWithCredential(any()),
      ).thenAnswer((_) async => _MockUserCredential());
      when(() => user.delete()).thenAnswer((_) async {});
      when(() => firebaseAuth.currentUser).thenReturn(user);
    });

    Future<void> seed() async {
      final userDoc = firestore.collection('users').doc('uid-1');
      await userDoc.set({'email': 'test@example.com'});
      await userDoc.collection('accounts').add({'name': 'Cash'});
      await userDoc.collection('categories').add({'name': 'Food'});
      await userDoc.collection('transactions').add({'note': 'Coffee'});
      await userDoc.collection('budgets').add({'limitAmount': 100});
    }

    test(
      'reauthenticates, then deletes the profile doc, every subcollection, '
      'and the Firebase user — in that order',
      () async {
        await seed();

        await dataSource.deleteAccount(password: 'correct-password');

        verify(
          () => user.reauthenticateWithCredential(any()),
        ).called(1);

        final userDoc = firestore.collection('users').doc('uid-1');
        expect((await userDoc.get()).exists, isFalse);
        for (final name in [
          'accounts',
          'categories',
          'transactions',
          'budgets',
        ]) {
          expect((await userDoc.collection(name).get()).docs, isEmpty);
        }

        verify(() => user.delete()).called(1);
      },
    );

    test(
      'throws AuthException and deletes nothing when reauthentication fails',
      () async {
        await seed();
        when(() => user.reauthenticateWithCredential(any())).thenThrow(
          FirebaseAuthException(code: 'wrong-password'),
        );

        await expectLater(
          dataSource.deleteAccount(password: 'wrong-password'),
          throwsA(isA<AuthException>()),
        );

        final userDoc = firestore.collection('users').doc('uid-1');
        expect((await userDoc.get()).exists, isTrue);
        verifyNever(() => user.delete());
      },
    );
  });
}
