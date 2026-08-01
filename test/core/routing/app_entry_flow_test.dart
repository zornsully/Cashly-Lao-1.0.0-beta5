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

  test('native apps start at the auth gate instead of the landing page', () {
    expect(appInitialLocationForPlatform(isWeb: false), AppRoutes.splash);
    expect(
      isMarketingRouteAvailable(isWeb: false, location: AppRoutes.landing),
      isFalse,
    );
  });
}
