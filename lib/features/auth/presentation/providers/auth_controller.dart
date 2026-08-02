import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/analytics_logger.dart';
import '../../../notifications/presentation/providers/fcm_token_providers.dart';
import 'auth_providers.dart';

/// Drives the loading/error state for every auth *action* (login, register,
/// forgot-password, logout, resend-verification, update-display-name).
///
/// It intentionally does not hold the signed-in user itself — that's
/// [authStateChangesProvider]'s job, and it updates automatically once
/// Firebase's own auth state changes, which in turn drives navigation via
/// the router's redirect. This controller only reports whether the
/// in-flight action succeeded, so screens know when to show a snackbar.
class AuthController extends AsyncNotifier<void> {
  @override
  void build() {}

  Failure? get failure => switch (state) {
    AsyncError(:final error) when error is Failure => error,
    _ => null,
  };

  Future<bool> login({required String email, required String password}) async {
    final success = await _run(
      () =>
          ref.read(loginUseCaseProvider).call(email: email, password: password),
    );
    if (success) {
      logAnalyticsEvent(() => ref.read(analyticsProvider), 'login', {
        'method': 'password',
      });
    }
    return success;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final success = await _run(
      () => ref
          .read(registerUseCaseProvider)
          .call(email: email, password: password, displayName: displayName),
    );
    if (success) {
      logAnalyticsEvent(() => ref.read(analyticsProvider), 'sign_up', {
        'method': 'password',
      });
    }
    return success;
  }

  Future<bool> signInWithGoogle() async {
    final success = await _run(
      () => ref.read(signInWithGoogleUseCaseProvider).call(),
    );
    if (success) {
      logAnalyticsEvent(() => ref.read(analyticsProvider), 'login', {
        'method': 'google',
      });
    }
    return success;
  }

  Future<bool> logout() async {
    await _unregisterFcmTokenBestEffort();
    return _run(() => ref.read(logoutUseCaseProvider).call());
  }

  /// Must run *before* `signOut()` completes — Firestore rules require
  /// `request.auth.uid` to still resolve to this user, and it would be
  /// rejected afterward. Best-effort and never blocks sign-out: a stray
  /// leftover token can't cause a wrongly-delivered push either way, since
  /// every Cloud Function send is gated on `notificationsEnabled` before a
  /// token is ever read (see `fcm_token_registration_providers.dart`'s doc
  /// comment for the fuller reasoning, which this mirrors).
  Future<void> _unregisterFcmTokenBestEffort() async {
    try {
      final token = await ref.read(messagingProvider).getToken();
      if (token == null) return;
      await ref.read(unregisterFcmTokenUseCaseProvider).call(token: token);
    } catch (_) {
      // Best-effort — see method doc comment.
    }
  }

  Future<bool> sendPasswordResetEmail(String email) {
    return _run(() => ref.read(forgotPasswordUseCaseProvider).call(email));
  }

  Future<bool> resendEmailVerification() {
    return _run(() => ref.read(sendEmailVerificationUseCaseProvider).call());
  }

  Future<bool> reloadUser() {
    return _run(() => ref.read(reloadUserUseCaseProvider).call());
  }

  Future<bool> updateDisplayName(String displayName) {
    return _run(
      () => ref.read(updateDisplayNameUseCaseProvider).call(displayName),
    );
  }

  Future<bool> deleteAccount({String? password}) {
    return _run(
      () => ref.read(deleteUserAccountUseCaseProvider).call(password: password),
    );
  }

  Future<bool> _run<R>(Future<Either<Failure, R>> Function() action) async {
    // This provider is `autoDispose`, and several of its actions
    // (deleteAccount above all — Firebase signs the user out as a direct
    // side effect) change auth state in a way that makes the router
    // redirect away from whatever screen is watching this controller
    // (e.g. ProfileScreen) *while this same action is still in flight*.
    // Once that screen unmounts, nothing is left watching the provider,
    // so Riverpod is free to dispose it before the final `state = ...`
    // write below runs -- which then throws UnmountedRefException after
    // the underlying auth operation already succeeded. Same fix and same
    // reasoning as TransactionController._run.
    final keepAliveLink = ref.keepAlive();
    try {
      state = const AsyncLoading();
      final result = await action();
      return result.match(
        (failure) {
          state = AsyncError<void>(failure, StackTrace.current);
          return false;
        },
        (_) {
          state = const AsyncData(null);
          return true;
        },
      );
    } finally {
      keepAliveLink.close();
    }
  }
}

final authControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, void>(AuthController.new);
