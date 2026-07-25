import 'package:cashly_lao/core/constants/app_language.dart';
import 'package:cashly_lao/core/constants/app_theme_mode.dart';
import 'package:cashly_lao/features/settings/data/models/user_preferences_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  test(
    'fromFirestore maps a stored document back to a UserPreferencesModel',
    () async {
      final ref = firestore.collection('users').doc('uid-1');
      await ref.set({
        'themeMode': 'dark',
        'defaultCurrencyCode': 'USD',
        'language': 'lao',
        'appLockEnabled': true,
        'notificationsEnabled': true,
      });
      final doc = await ref.get();

      final model = UserPreferencesModel.fromFirestore(doc);

      expect(model.themeMode, AppThemeModePreference.dark);
      expect(model.defaultCurrencyCode, 'USD');
      expect(model.language, AppLanguage.lao);
      expect(model.appLockEnabled, isTrue);
      expect(model.notificationsEnabled, isTrue);
    },
  );

  test(
    'defaults to system theme, LAK, English, and both toggles off when '
    'fields are absent',
    () async {
      final ref = firestore.collection('users').doc('uid-1');
      await ref.set({'email': 'a@b.com'});
      final doc = await ref.get();

      final model = UserPreferencesModel.fromFirestore(doc);

      expect(model.themeMode, AppThemeModePreference.system);
      expect(model.defaultCurrencyCode, 'LAK');
      expect(model.language, AppLanguage.english);
      expect(model.appLockEnabled, isFalse);
      expect(model.notificationsEnabled, isFalse);
    },
  );

  test(
    'defaults to system theme, LAK, English, and both toggles off when the '
    'document does not exist',
    () async {
      final doc = await firestore.collection('users').doc('missing').get();

      final model = UserPreferencesModel.fromFirestore(doc);

      expect(model.themeMode, AppThemeModePreference.system);
      expect(model.defaultCurrencyCode, 'LAK');
      expect(model.language, AppLanguage.english);
      expect(model.appLockEnabled, isFalse);
      expect(model.notificationsEnabled, isFalse);
    },
  );
}
