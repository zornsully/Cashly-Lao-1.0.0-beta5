import 'package:cashly_lao/core/routing/app_router.dart';
import 'package:cashly_lao/core/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
