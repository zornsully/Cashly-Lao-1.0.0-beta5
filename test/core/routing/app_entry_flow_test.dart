import 'dart:async';

import 'package:cashly_lao/core/routing/app_router.dart';
import 'package:cashly_lao/core/routing/app_routes.dart';
import 'package:cashly_lao/features/auth/domain/entities/user_entity.dart';
import 'package:cashly_lao/features/auth/domain/repositories/auth_repository.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

final _verifiedUser = UserEntity(
  uid: 'uid-1',
  email: 'user@example.com',
  emailVerified: true,
  createdAt: DateTime(2026),
);

/// Builds a container with [authRepositoryProvider] mocked to emit exactly
/// [events] on `authStateChanges()`, and waits for the first one to land so
/// `authStateChangesProvider`'s synchronous `AsyncValue` snapshot is settled
/// before a test reads it. Pass no events to leave the stream pending
/// forever, simulating an auth state that hasn't resolved yet.
///
/// Uses `container.listen` (a persistent subscription) rather than the
/// `.future` modifier -- `.future` was found to hang indefinitely against a
/// mocked repository stream in this exact setup; a plain listen plus a
/// microtask pump is the more direct, more reliable way to force the
/// provider to actually build and process the queued event.
Future<ProviderContainer> _containerWithAuthEvents(
  List<UserEntity?>? events,
) async {
  final repository = _MockAuthRepository();
  final controller = StreamController<UserEntity?>();
  when(
    () => repository.authStateChanges(),
  ).thenAnswer((_) => controller.stream);
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  container.listen(authStateChangesProvider, (_, _) {});
  if (events != null) {
    for (final event in events) {
      controller.add(event);
    }
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
  return container;
}

/// Reads [computeAppRedirect] through a throwaway `Provider` so the test can
/// supply a real Riverpod [Ref] without needing a full widget/router tree.
String? _redirectFor(
  ProviderContainer container,
  String location, {
  required bool isWeb,
}) {
  return container.read(
    Provider((ref) => computeAppRedirect(ref, location, isWeb: isWeb)),
  );
}

void main() {
  test('web starts on the public landing page', () {
    expect(appInitialLocationForPlatform(isWeb: true), AppRoutes.landing);
    expect(
      isMarketingRouteAvailable(isWeb: true, location: AppRoutes.landing),
      isTrue,
    );
  });

  test('web preserves a direct public route on refresh', () {
    expect(
      appInitialLocationForPlatform(
        isWeb: true,
        browserLocation: AppRoutes.privacy,
      ),
      AppRoutes.privacy,
    );
    expect(
      appInitialLocationForPlatform(
        isWeb: true,
        browserLocation: AppRoutes.login,
      ),
      AppRoutes.login,
    );
  });

  test('web exposes every public marketing page as a direct route', () {
    for (final route in [
      AppRoutes.features,
      AppRoutes.screenshots,
      AppRoutes.download,
      AppRoutes.privacy,
    ]) {
      expect(isMarketingRouteAvailable(isWeb: true, location: route), isTrue);
      expect(
        appInitialLocationForPlatform(isWeb: true, browserLocation: route),
        route,
      );
    }
  });

  test('native apps start at the auth gate instead of the landing page', () {
    expect(appInitialLocationForPlatform(isWeb: false), AppRoutes.splash);
    expect(
      isMarketingRouteAvailable(isWeb: false, location: AppRoutes.landing),
      isFalse,
    );
  });

  test('web never leaves an unresolved session on the native splash route', () {
    expect(
      pendingAuthRedirectForPlatform(isWeb: true, location: AppRoutes.splash),
      AppRoutes.login,
    );
    expect(
      pendingAuthRedirectForPlatform(
        isWeb: true,
        location: AppRoutes.dashboard,
      ),
      AppRoutes.login,
    );
  });

  test('native keeps its splash route while restoring authentication', () {
    expect(
      pendingAuthRedirectForPlatform(isWeb: false, location: AppRoutes.splash),
      isNull,
    );
  });

  // Regression guard for a real production bug: on web, /login (and
  // /register, /forgot-password) used to short-circuit to "stay put"
  // *before* ever reading the auth state, so a user who signed in while
  // sitting on /login -- no explicit navigation, just Firebase's auth
  // stream emitting reactively -- never actually got redirected away from
  // it, despite `AuthController` correctly reporting success.
  test('web redirects a signed-in, verified user away from /login once auth '
      'state resolves reactively (not just on next navigation)', () async {
    final container = await _containerWithAuthEvents([_verifiedUser]);
    addTearDown(container.dispose);

    expect(
      _redirectFor(container, AppRoutes.login, isWeb: true),
      AppRoutes.home,
    );
    expect(
      _redirectFor(container, AppRoutes.register, isWeb: true),
      AppRoutes.home,
    );
  });

  test('web leaves an unresolved auth state on /login alone (the original, '
      'still-intended behavior this fix must not break)', () async {
    // No events -- authStateChangesProvider stays AsyncLoading,
    // simulating Firebase not having reported a session yet.
    final container = await _containerWithAuthEvents(null);
    addTearDown(container.dispose);

    expect(_redirectFor(container, AppRoutes.login, isWeb: true), isNull);
  });

  test('web leaves a genuinely signed-out user on /login alone', () async {
    final container = await _containerWithAuthEvents([null]);
    addTearDown(container.dispose);

    expect(_redirectFor(container, AppRoutes.login, isWeb: true), isNull);
  });
}
