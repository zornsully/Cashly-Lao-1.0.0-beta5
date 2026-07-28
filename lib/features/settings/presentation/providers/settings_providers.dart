import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/providers/local_auth_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/user_preferences_remote_datasource.dart';
import '../../data/repositories/user_preferences_repository_impl.dart';
import '../../domain/entities/user_preferences_entity.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../../domain/usecases/update_app_lock_enabled_usecase.dart';
import '../../domain/usecases/update_default_currency_usecase.dart';
import '../../domain/usecases/update_language_usecase.dart';
import '../../domain/usecases/update_notifications_enabled_usecase.dart';
import '../../domain/usecases/update_theme_mode_usecase.dart';

final userPreferencesRemoteDataSourceProvider =
    Provider<UserPreferencesRemoteDataSource>((ref) {
      return FirestoreUserPreferencesRemoteDataSource(
        firestore: ref.watch(firestoreProvider),
        firebaseAuth: ref.watch(firebaseAuthProvider),
      );
    });

final userPreferencesRepositoryProvider = Provider<UserPreferencesRepository>((
  ref,
) {
  return UserPreferencesRepositoryImpl(
    ref.watch(userPreferencesRemoteDataSourceProvider),
  );
});

/// The signed-in user's preferences, real-time. Watched both by
/// [CashlyApp] (to pick `MaterialApp.themeMode`) and by the Account/Budget
/// forms (to pre-select the default currency).
///
/// Explicitly watches [authStateChangesProvider] rather than just reading
/// the current user once: this provider is first created at app startup
/// (before sign-in completes), and without watching auth state it would
/// permanently cache whatever it saw at that first build — either an
/// error (no user yet) that never clears once you do sign in, or, after a
/// sign-out/sign-in as a different user, the previous user's stream still
/// streaming instead of the new one's.
final userPreferencesProvider = StreamProvider<UserPreferencesEntity>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(userPreferencesRepositoryProvider).watchPreferences();
});

final updateThemeModeUseCaseProvider = Provider<UpdateThemeModeUseCase>((ref) {
  return UpdateThemeModeUseCase(ref.watch(userPreferencesRepositoryProvider));
});

final updateDefaultCurrencyUseCaseProvider =
    Provider<UpdateDefaultCurrencyUseCase>((ref) {
      return UpdateDefaultCurrencyUseCase(
        ref.watch(userPreferencesRepositoryProvider),
      );
    });

final updateLanguageUseCaseProvider = Provider<UpdateLanguageUseCase>((ref) {
  return UpdateLanguageUseCase(ref.watch(userPreferencesRepositoryProvider));
});

final updateAppLockEnabledUseCaseProvider =
    Provider<UpdateAppLockEnabledUseCase>((ref) {
      return UpdateAppLockEnabledUseCase(
        ref.watch(userPreferencesRepositoryProvider),
      );
    });

/// Whether this device can satisfy an app-lock challenge at all (biometrics
/// enrolled, or a device PIN/pattern/password set) — Settings uses this to
/// disable the toggle rather than let a user turn on a lock they'd
/// immediately be unable to pass.
final isAppLockSupportedProvider = FutureProvider<bool>((ref) {
  if (kIsWeb) return Future.value(false);
  return ref.watch(localAuthenticationProvider).isDeviceSupported();
});

final updateNotificationsEnabledUseCaseProvider =
    Provider<UpdateNotificationsEnabledUseCase>((ref) {
      return UpdateNotificationsEnabledUseCase(
        ref.watch(userPreferencesRepositoryProvider),
      );
    });
