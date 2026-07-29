import 'package:cashly_lao/core/constants/app_language.dart';
import 'package:cashly_lao/core/constants/app_theme_mode.dart';
import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/features/settings/data/datasources/user_preferences_remote_datasource.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseAuth firebaseAuth;
  late FirestoreUserPreferencesRemoteDataSource dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    firebaseAuth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('uid-1');
    when(() => firebaseAuth.currentUser).thenReturn(user);
    dataSource = FirestoreUserPreferencesRemoteDataSource(
      firestore: firestore,
      firebaseAuth: firebaseAuth,
    );
  });

  test(
    'watchPreferences defaults when the profile document does not yet exist',
    () async {
      final preferences = await dataSource.watchPreferences().first;

      expect(preferences.themeMode, AppThemeModePreference.system);
      expect(preferences.defaultCurrencyCode, 'LAK');
      expect(preferences.language, AppLanguage.english);
    },
  );

  test(
    'updateThemeMode merges the field without clobbering existing data',
    () async {
      await firestore.collection('users').doc('uid-1').set({
        'email': 'a@b.com',
      });

      await dataSource.updateThemeMode(AppThemeModePreference.dark);

      final doc = await firestore.collection('users').doc('uid-1').get();
      expect(doc.data()!['themeMode'], 'dark');
      expect(doc.data()!['email'], 'a@b.com');
    },
  );

  test(
    'updateDefaultCurrency merges the field without clobbering existing data',
    () async {
      await firestore.collection('users').doc('uid-1').set({
        'email': 'a@b.com',
      });

      await dataSource.updateDefaultCurrency('USD');

      final doc = await firestore.collection('users').doc('uid-1').get();
      expect(doc.data()!['defaultCurrencyCode'], 'USD');
      expect(doc.data()!['email'], 'a@b.com');
    },
  );

  test(
    'updateLanguage merges the field without clobbering existing data',
    () async {
      await firestore.collection('users').doc('uid-1').set({
        'email': 'a@b.com',
      });

      await dataSource.updateLanguage(AppLanguage.lao);

      final doc = await firestore.collection('users').doc('uid-1').get();
      expect(doc.data()!['language'], 'lao');
      expect(doc.data()!['email'], 'a@b.com');
    },
  );

  test(
    'updateAppLockEnabled merges the field without clobbering existing data',
    () async {
      await firestore.collection('users').doc('uid-1').set({
        'email': 'a@b.com',
      });

      await dataSource.updateAppLockEnabled(true);

      final doc = await firestore.collection('users').doc('uid-1').get();
      expect(doc.data()!['appLockEnabled'], isTrue);
      expect(doc.data()!['email'], 'a@b.com');
    },
  );

  test('updateNotificationsEnabled merges the field without clobbering '
      'existing data', () async {
    await firestore.collection('users').doc('uid-1').set({'email': 'a@b.com'});

    await dataSource.updateNotificationsEnabled(true);

    final doc = await firestore.collection('users').doc('uid-1').get();
    expect(doc.data()!['notificationsEnabled'], isTrue);
    expect(doc.data()!['email'], 'a@b.com');
  });

  test('watchPreferences reflects updates in real time', () async {
    final stream = dataSource.watchPreferences();
    final emissions = <String>[];
    final subscription = stream.listen(
      (p) => emissions.add(p.defaultCurrencyCode),
    );
    await Future<void>.delayed(Duration.zero);

    await dataSource.updateDefaultCurrency('THB');
    await Future<void>.delayed(Duration.zero);

    expect(emissions, contains('THB'));
    await subscription.cancel();
  });

  test('throws AuthException when there is no signed-in user', () {
    when(() => firebaseAuth.currentUser).thenReturn(null);

    expect(() => dataSource.watchPreferences(), throwsA(isA<AuthException>()));
  });
}
