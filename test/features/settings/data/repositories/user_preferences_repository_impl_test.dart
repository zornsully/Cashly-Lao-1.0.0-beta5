import 'package:cashly_lao/core/constants/app_language.dart';
import 'package:cashly_lao/core/constants/app_theme_mode.dart';
import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/settings/data/datasources/user_preferences_remote_datasource.dart';
import 'package:cashly_lao/features/settings/data/models/user_preferences_model.dart';
import 'package:cashly_lao/features/settings/data/repositories/user_preferences_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserPreferencesRemoteDataSource extends Mock
    implements UserPreferencesRemoteDataSource {}

void main() {
  late _MockUserPreferencesRemoteDataSource dataSource;
  late UserPreferencesRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(AppThemeModePreference.system);
    registerFallbackValue(AppLanguage.english);
  });

  setUp(() {
    dataSource = _MockUserPreferencesRemoteDataSource();
    repository = UserPreferencesRepositoryImpl(dataSource);
  });

  const preferences = UserPreferencesModel(
    themeMode: AppThemeModePreference.dark,
    defaultCurrencyCode: 'USD',
    language: AppLanguage.english,
    appLockEnabled: false,
    notificationsEnabled: false,
  );

  test('watchPreferences passes the stream straight through', () {
    when(
      () => dataSource.watchPreferences(),
    ).thenAnswer((_) => Stream.value(preferences));

    expect(repository.watchPreferences(), emits(preferences));
  });

  test('updateThemeMode returns Right(unit) on success', () async {
    when(() => dataSource.updateThemeMode(any())).thenAnswer((_) async {});

    final result = await repository.updateThemeMode(
      AppThemeModePreference.dark,
    );

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('updateThemeMode maps ServerException to Left(ServerFailure)', () async {
    when(
      () => dataSource.updateThemeMode(any()),
    ).thenThrow(const ServerException('Could not update your theme.'));

    final result = await repository.updateThemeMode(
      AppThemeModePreference.light,
    );

    expect(
      result,
      const Left<Failure, Unit>(ServerFailure('Could not update your theme.')),
    );
  });

  test('updateDefaultCurrency returns Right(unit) on success', () async {
    when(
      () => dataSource.updateDefaultCurrency(any()),
    ).thenAnswer((_) async {});

    final result = await repository.updateDefaultCurrency('EUR');

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('updateLanguage returns Right(unit) on success', () async {
    when(() => dataSource.updateLanguage(any())).thenAnswer((_) async {});

    final result = await repository.updateLanguage(AppLanguage.lao);

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('updateAppLockEnabled returns Right(unit) on success', () async {
    when(
      () => dataSource.updateAppLockEnabled(any()),
    ).thenAnswer((_) async {});

    final result = await repository.updateAppLockEnabled(true);

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('updateNotificationsEnabled returns Right(unit) on success', () async {
    when(
      () => dataSource.updateNotificationsEnabled(any()),
    ).thenAnswer((_) async {});

    final result = await repository.updateNotificationsEnabled(true);

    expect(result, const Right<Failure, Unit>(unit));
  });
}
