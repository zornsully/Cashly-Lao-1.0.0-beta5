/// Named path constants for every route in the app. Screens navigate with
/// `context.go(AppRoutes.login)` rather than hardcoded path strings.
abstract final class AppRoutes {
  /// Public product site. This stays outside the authenticated app shell.
  static const String landing = '/';
  static const String features = '/features';
  static const String screenshots = '/screenshots';
  static const String download = '/download';
  static const String privacy = '/privacy-policy';

  /// Kept only so old links continue to work after the public-site split.
  static const String legacyPrivacy = '/privacy';
  static const String terms = '/terms';

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';

  /// Shown instead of the authenticated app when the user has app lock
  /// enabled and the current session hasn't been unlocked yet — see
  /// `isUnlockedProvider`.
  static const String lock = '/lock';

  /// Bottom-nav tabs, all living inside the authenticated shell.
  static const String dashboard = '/dashboard';
  static const String accounts = '/accounts';
  static const String transactions = '/transactions';
  static const String categories = '/categories';
  static const String budget = '/budget';
  static const String profile = '/profile';

  /// Where a freshly-authenticated, verified user lands.
  static const String home = dashboard;

  static const String accountNew = '/accounts/new';
  static const String accountEdit = '/accounts/:id/edit';

  static String accountEditPath(String id) => '/accounts/$id/edit';

  static const String categoryNew = '/categories/new';
  static const String categoryEdit = '/categories/:id/edit';

  static String categoryEditPath(String id) => '/categories/$id/edit';

  static const String transactionNew = '/transactions/new';
  static const String transactionEdit = '/transactions/:id/edit';

  static String transactionEditPath(String id) => '/transactions/$id/edit';

  static const String budgetNew = '/budget/new';
  static const String budgetEdit = '/budget/:id/edit';

  static String budgetEditPath(String id) => '/budget/$id/edit';

  /// Not a bottom-nav tab — reached via an icon button from Dashboard, since
  /// six tabs already exceeds Material's typical 3-5 guidance.
  static const String reports = '/reports';

  /// Also not a bottom-nav tab, same reasoning as [reports] — reached via
  /// an icon button from Dashboard.
  static const String savingsGoals = '/savings-goals';
  static const String savingsGoalNew = '/savings-goals/new';
  static const String savingsGoalEdit = '/savings-goals/:id/edit';
  static const String savingsGoalDetail = '/savings-goals/:id';

  static String savingsGoalEditPath(String id) => '/savings-goals/$id/edit';

  static String savingsGoalDetailPath(String id) => '/savings-goals/$id';

  /// Reached via an icon button on the Profile tab.
  static const String settings = '/settings';

  /// Dedicated account-management entry point from Settings. It reuses the
  /// authenticated profile management flow rather than a placeholder screen.
  static const String settingsAccount = '/settings/account';
}
