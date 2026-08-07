import 'dart:async';

import 'package:flutter/foundation.dart';
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
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

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
      // Browser popups (and an interrupted network request) can otherwise
      // leave the shared controller loading forever, disabling every login
      // control as shown on the web sign-in screen.
      final result = await action().timeout(const Duration(seconds: 30));
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
    } on TimeoutException {
      state = AsyncError<void>(
        const NetworkFailure('Sign-in timed out. Please try again.'),
        StackTrace.current,
      );
      return false;
    } catch (error, stackTrace) {
      // Anything landing here escaped even RepositoryGuard.guard()'s own
      // catch-all inside the repository layer -- the only way that happens
      // is if `action()` itself throws before guard()'s try block is ever
      // entered, e.g. a provider dependency of `action`'s use case (like
      // authRepositoryProvider) throwing during construction. Without this
      // clause, `state` would stay AsyncLoading() forever: nothing else in
      // this method ever gets a chance to move it off that value, which is
      // exactly the "every login control disabled with no way to recover"
      // failure mode AuthActionStuckBanner exists to defend against.
      debugPrint('AuthController._run: unhandled error, recovering: $error');
      // TEMPORARY diagnostic: surfacing the raw error text directly in the
      // user-facing message (normally just "Something went wrong.") because
      // repeated attempts to get console output from the person hitting
      // this in production were unsuccessful, and this exact class of
      // uncaught error has no message shown anywhere else reachable from a
      // screenshot. Revert to `const UnknownFailure()` once the real error
      // behind tonight's live repro is captured -- this should never ship
      // long-term, since raw exception text isn't something an end user
      // should see.
      state = AsyncError<void>(UnknownFailure('Something went wrong: $error'), stackTrace);
      return false;
    } finally {
      keepAliveLink.close();
    }
  }
}

final authControllerProvider =
    NotifierProvider.autoDispose<AuthController, AsyncValue<void>>(
      AuthController.new,
    );
