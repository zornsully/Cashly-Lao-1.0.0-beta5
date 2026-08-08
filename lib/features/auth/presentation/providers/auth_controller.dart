import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// ProviderException isn't exposed through the main flutter_riverpod.dart
// barrel file -- only through this narrower one.
import 'package:flutter_riverpod/misc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/analytics_logger.dart';
import '../../../../core/utils/auth_debug_log.dart';
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
    AuthDebugLog.log('[AUTH-01] login() called');
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
    AuthDebugLog.log('[AUTH-01] signInWithGoogle() called');
    final success = await _run(
      () => ref.read(signInWithGoogleUseCaseProvider).call(),
      // Longer than every other action: this one waits on human interaction
      // (the Google account picker), not just a network round-trip, and the
      // datasource's own `_signInWithGooglePopup` already bounds the popup
      // itself to 60s with a specific, actionable message ("Allow pop-ups
      // for Cashly Lao and try again."). This timeout must stay longer than
      // that one -- otherwise this generic timeout always wins the race and
      // the more useful datasource-level message can never reach the user.
      timeout: const Duration(seconds: 65),
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

  Future<bool> _run<R>(
    Future<Either<Failure, R>> Function() action, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
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
      AuthDebugLog.log('[AUTH-02] provider chain resolving, action starting');
      // Browser popups (and an interrupted network request) can otherwise
      // leave the shared controller loading forever, disabling every login
      // control as shown on the web sign-in screen.
      final result = await _runWithRetry(action, timeout);
      return result.match(
        (failure) {
          final code = switch (failure) {
            AuthFailure(:final code) => code,
            _ => null,
          };
          AuthDebugLog.log(
            '[AUTH-09] action failed: ${failure.runtimeType}'
            '${code != null ? ' code=$code' : ''} -- ${failure.message}',
          );
          state = AsyncError<void>(failure, StackTrace.current);
          return false;
        },
        (_) {
          AuthDebugLog.log('[AUTH-08] action succeeded, state -> AsyncData');
          state = const AsyncData(null);
          return true;
        },
      );
    } on TimeoutException {
      AuthDebugLog.log(
        '[AUTH-09] action timed out after ${timeout.inSeconds}s -- this '
        'controller-level timeout should rarely fire for Google sign-in '
        "specifically; if it does, the datasource's own 60s popup timeout "
        'and its more specific error never got a chance to run first.',
      );
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
      AuthDebugLog.log(
        '[AUTH-09] unhandled error escaped the retry, recovering: $error',
      );
      // TEMPORARY diagnostic (re-enabled): the firebase_core_web 3.10.0
      // upgrade did not resolve this in practice, so re-surfacing the raw
      // error to check whether it's the exact same TypeError as before or
      // something new. Revert to `const UnknownFailure()` once done.
      state = AsyncError<void>(
        UnknownFailure('Something went wrong: $error'),
        stackTrace,
      );
      return false;
    } finally {
      keepAliveLink.close();
    }
  }

  /// A bare [TypeError] reaching here almost never means our own code hit a
  /// real type bug -- normal failures already come back as `Left(Failure)`
  /// well before this point. On web it's the signature of
  /// https://github.com/firebase/flutterfire/issues/18548: firebase_core_web's
  /// `FirebaseCoreWeb.app()` force-casts whatever it catches to a JS error
  /// type, so a transient, already-resolved condition on Firebase's side
  /// surfaces here as an unrelated TypeError instead of the real (likely
  /// harmless) exception.
  ///
  /// It never arrives as a bare [TypeError] in practice, though: it's thrown
  /// while `firebaseAuthProvider` (a plain `Provider`) constructs, and
  /// Riverpod always surfaces a failed provider's error to callers wrapped
  /// in [ProviderException] -- and wraps it *again* at every provider
  /// further up the `ref.watch` chain (`authRemoteDataSourceProvider` ->
  /// `authRepositoryProvider` -> `loginUseCaseProvider`) that also depends
  /// on it, so by the time it reaches `ref.read(loginUseCaseProvider)` here
  /// it can be several `ProviderException`s deep. [_typeErrorAtRootOf]
  /// unwraps that nesting to find the real cause.
  ///
  /// Simply retrying `action()` would not give that condition a second
  /// chance even once correctly detected: Riverpod caches a `Provider`'s
  /// *error* state forever once `create` throws -- it never re-runs
  /// `create` on its own. Every subsequent read of `firebaseAuthProvider`
  /// -- including a plain retry -- would just rethrow the identical cached
  /// `ProviderException` without ever calling `FirebaseAuth.instance`
  /// again. Invalidating both Firebase SDK providers forces Riverpod to
  /// actually reconstruct them (and, via the `ref.watch` chain, everything
  /// downstream of them) on the retry, so the underlying Firebase call
  /// gets a genuine second attempt. A persistent failure throws again
  /// immediately and falls straight through to `_run`'s own catch-all,
  /// unchanged from before this retry existed.
  Future<Either<Failure, R>> _runWithRetry<R>(
    Future<Either<Failure, R>> Function() action,
    Duration timeout,
  ) async {
    try {
      return await action().timeout(timeout);
    } catch (error) {
      if (_typeErrorAtRootOf(error) is! TypeError) rethrow;
      AuthDebugLog.log(
        '[AUTH-07] caught TypeError (possibly wrapped in ProviderException) '
        '-- invalidating firebaseAuthProvider/firestoreProvider and '
        'retrying once',
      );
      ref.invalidate(firebaseAuthProvider);
      ref.invalidate(firestoreProvider);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return action().timeout(timeout);
    }
  }

  /// Unwraps nested [ProviderException]s to find the original error a
  /// failed provider threw. See [_runWithRetry]'s doc comment for why this
  /// unwrapping is necessary.
  Object _typeErrorAtRootOf(Object error) {
    var current = error;
    while (current is ProviderException) {
      current = current.exception;
    }
    return current;
  }
}

final authControllerProvider =
    NotifierProvider.autoDispose<AuthController, AsyncValue<void>>(
      AuthController.new,
    );
