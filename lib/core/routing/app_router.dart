import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/firebase_providers.dart';

import '../../features/accounts/domain/entities/account_entity.dart';
import '../../features/accounts/presentation/screens/account_form_screen.dart';
import '../../features/accounts/presentation/screens/accounts_list_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/categories/domain/entities/category_entity.dart';
import '../../features/categories/domain/entities/category_type.dart';
import '../../features/categories/presentation/screens/categories_list_screen.dart';
import '../../features/categories/presentation/screens/category_form_screen.dart';
import '../../features/budget/domain/entities/budget_entity.dart';
import '../../features/budget/presentation/screens/budget_form_screen.dart';
import '../../features/budget/presentation/screens/budgets_list_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/landing/presentation/screens/landing_page.dart';
import '../../features/landing/presentation/screens/legal_document_page.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/savings_goals/domain/entities/savings_goal_entity.dart';
import '../../features/savings_goals/presentation/screens/savings_goal_detail_screen.dart';
import '../../features/savings_goals/presentation/screens/savings_goal_form_screen.dart';
import '../../features/savings_goals/presentation/screens/savings_goals_list_screen.dart';
import '../../features/settings/presentation/screens/lock_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';
import '../../features/transactions/domain/entities/transaction_entity.dart';
import '../../features/transactions/domain/entities/transaction_type.dart';
import '../../features/transactions/presentation/screens/transaction_form_screen.dart';
import '../../features/transactions/presentation/screens/transactions_list_screen.dart';
import '../providers/app_lock_state_provider.dart';
import '../utils/platform_capabilities.dart';
import 'app_routes.dart';
import 'desktop_page_frame.dart';
import 'home_shell_screen.dart';

const _publicRoutes = {
  AppRoutes.landing,
  AppRoutes.features,
  AppRoutes.screenshots,
  AppRoutes.download,
  AppRoutes.privacy,
  AppRoutes.legacyPrivacy,
  AppRoutes.terms,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
};

const _marketingRoutes = {
  AppRoutes.landing,
  AppRoutes.features,
  AppRoutes.screenshots,
  AppRoutes.download,
  AppRoutes.privacy,
  AppRoutes.legacyPrivacy,
  AppRoutes.terms,
};

const _authOnlyRoutes = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
  AppRoutes.verifyEmail,
};

/// Selects the correct first screen for each product surface.
///
/// The public product site is intentionally web-only. Native apps start at
/// the auth gate, whose redirect then sends a restored session to Dashboard
/// or a signed-out session to Login.
@visibleForTesting
String appInitialLocationForPlatform({
  required bool isWeb,
  String? browserLocation,
}) {
  if (!isWeb) {
    return AppRoutes.splash;
  }
  // Flutter's web platform route defaults to `/` during bootstrap. Preserve
  // the browser URL explicitly so a refresh of /privacy, /terms, or /login
  // displays the requested public page instead of the landing page.
  return browserLocation?.startsWith('/') == true
      ? browserLocation!
      : AppRoutes.landing;
}

@visibleForTesting
bool isMarketingRouteAvailable({
  required bool isWeb,
  required String location,
}) => isWeb && _marketingRoutes.contains(location);

/// Resolves an app route while Firebase Auth is still restoring its first
/// session value. Web must never expose the native-only splash route: it can
/// render Login immediately and the router will return a restored session to
/// Dashboard once the Auth stream emits.
@visibleForTesting
String? pendingAuthRedirectForPlatform({
  required bool isWeb,
  required String location,
}) {
  if (location == AppRoutes.splash) {
    return isWeb ? AppRoutes.login : null;
  }
  return isWeb ? AppRoutes.login : AppRoutes.splash;
}

/// The app's single [GoRouter] instance. Auth guarding lives entirely in
/// [redirect]: no screen needs to manually check "am I logged in?" before
/// rendering, and no screen needs to manually navigate after a successful
/// login/logout — both happen reactively as [authStateChangesProvider]
/// updates from Firebase.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Driven by ref.listen on authStateChangesProvider itself — Riverpod's
  // own single, shared subscription to authRepository.authStateChanges()
  // — rather than a second, independent call to authStateChanges() here.
  // A separate subscription to the same underlying Firebase stream
  // doesn't reliably replay the stream's first event to a late
  // subscriber, which left this provider needing a value (redirect below
  // reads it via ref.read, which isn't itself reactive) permanently
  // stuck without one — the app never left the splash screen for any
  // user, ever.
  final refreshNotifier = _AuthRefreshNotifier();
  // The public-route guard below runs before Auth is read, so listening here
  // never delays the web landing page. Once Firebase finishes bootstrapping,
  // this refresh moves a restored browser session from Login to Dashboard.
  ref.listen(authStateChangesProvider, (_, _) => refreshNotifier.refresh());
  // App lock gate needs the router to re-evaluate `redirect` whenever
  // either changes: the session unlocks/re-locks, or the preference itself
  // is toggled in Settings (so turning it off there immediately clears the
  // gate rather than waiting for the next navigation).
  ref.listen(isUnlockedProvider, (_, _) => refreshNotifier.refresh());
  if (!kIsWeb) {
    ref.listen(userPreferencesProvider, (_, _) => refreshNotifier.refresh());
  }
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: appInitialLocationForPlatform(
      isWeb: kIsWeb,
      browserLocation: kIsWeb ? Uri.base.path : null,
    ),
    overridePlatformDefaultLocation: kIsWeb,
    refreshListenable: refreshNotifier,
    observers: [
      if (!kIsWeb && AppPlatformCapabilities.supportsFirebaseAnalytics)
        FirebaseAnalyticsObserver(analytics: ref.read(analyticsProvider)),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;

      // The marketing site is web-only. Native launches always flow through
      // Splash while Firebase restores the session, never through Landing.
      // This check must come before touching Firebase-backed providers: the
      // public web shell needs to render even when Firebase is unavailable.
      if (isMarketingRouteAvailable(isWeb: kIsWeb, location: location)) {
        return null;
      }

      // Login, registration, and password recovery must remain reachable
      // while the background Firebase initialization is still in progress.
      // These pages show their own recoverable service state when an action
      // needs Firebase, rather than turning a public URL into a blank page.
      if (kIsWeb && _publicRoutes.contains(location)) {
        return null;
      }

      // /splash belongs to the native entry flow. Old hashes, bookmarks, or
      // an interrupted Auth restore must land at Login on web instead of
      // leaving a browser visitor behind an indefinite spinner.
      if (kIsWeb && location == AppRoutes.splash) {
        return AppRoutes.login;
      }

      final authState = ref.read(authStateChangesProvider);

      if (!authState.hasValue) {
        return pendingAuthRedirectForPlatform(
          isWeb: kIsWeb,
          location: location,
        );
      }

      final user = authState.value;

      if (user == null) {
        if (!kIsWeb && location == AppRoutes.landing) {
          return AppRoutes.login;
        }
        return _publicRoutes.contains(location) ? null : AppRoutes.login;
      }

      if (!user.emailVerified) {
        return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
      }

      final appLockEnabled =
          ref.read(userPreferencesProvider).value?.appLockEnabled ?? false;
      if (!kIsWeb && appLockEnabled && !ref.read(isUnlockedProvider)) {
        return location == AppRoutes.lock ? null : AppRoutes.lock;
      }
      if (location == AppRoutes.lock) {
        return AppRoutes.home;
      }

      return _authOnlyRoutes.contains(location) ? AppRoutes.home : null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.landing,
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: AppRoutes.features,
        builder: (context, state) => const LandingPage.features(),
      ),
      GoRoute(
        path: AppRoutes.screenshots,
        builder: (context, state) => const LandingPage.screenshots(),
      ),
      GoRoute(
        path: AppRoutes.download,
        builder: (context, state) => const LandingPage.download(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) => const LandingPage.privacy(),
      ),
      GoRoute(
        path: AppRoutes.legacyPrivacy,
        redirect: (context, state) => AppRoutes.privacy,
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const LegalDocumentPage.terms(),
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.lock,
        builder: (context, state) => const LockScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.accounts,
                builder: (context, state) => const AccountsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (context, state) => const TransactionsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.categories,
                builder: (context, state) => const CategoriesListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.budget,
                builder: (context, state) => const BudgetsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.accountNew,
        builder: (context, state) => const AccountFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountEdit,
        builder: (context, state) =>
            AccountFormScreen(existing: state.extra as AccountEntity?),
      ),
      GoRoute(
        path: AppRoutes.categoryNew,
        builder: (context, state) =>
            CategoryFormScreen(initialType: state.extra as CategoryType?),
      ),
      GoRoute(
        path: AppRoutes.categoryEdit,
        builder: (context, state) =>
            CategoryFormScreen(existing: state.extra as CategoryEntity?),
      ),
      GoRoute(
        path: AppRoutes.transactionNew,
        builder: (context, state) {
          final extra = state.extra;
          return TransactionFormScreen(
            initialType: extra is TransactionType ? extra : null,
            duplicateFrom: extra is TransactionEntity ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.transactionEdit,
        builder: (context, state) =>
            TransactionFormScreen(existing: state.extra as TransactionEntity?),
      ),
      GoRoute(
        path: AppRoutes.budgetNew,
        redirect: (context, state) => state.extra is NewBudgetArgs
            ? null
            : AppRoutes.budget,
        builder: (context, state) =>
            BudgetFormScreen(newBudgetArgs: state.extra as NewBudgetArgs?),
      ),
      GoRoute(
        path: AppRoutes.budgetEdit,
        redirect: (context, state) => state.extra is BudgetEntity
            ? null
            : AppRoutes.budget,
        builder: (context, state) =>
            BudgetFormScreen(existing: state.extra as BudgetEntity?),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const DesktopPageFrame(
          activeRoute: AppRoutes.reports,
          child: ReportsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const DesktopPageFrame(
          activeRoute: AppRoutes.settings,
          child: SettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsAccount,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.savingsGoals,
        builder: (context, state) => const DesktopPageFrame(
          activeRoute: AppRoutes.savingsGoals,
          child: SavingsGoalsListScreen(),
        ),
      ),
      // Registered before savingsGoalDetail: both /savings-goals/new and
      // /savings-goals/:id would otherwise match the literal path
      // "/savings-goals/new", and go_router resolves top-level routes in
      // declaration order rather than preferring the more specific one.
      GoRoute(
        path: AppRoutes.savingsGoalNew,
        builder: (context, state) => const SavingsGoalFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.savingsGoalEdit,
        builder: (context, state) =>
            SavingsGoalFormScreen(existing: state.extra as SavingsGoalEntity?),
      ),
      GoRoute(
        path: AppRoutes.savingsGoalDetail,
        builder: (context, state) =>
            SavingsGoalDetailScreen(goalId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Bridges a `ref.listen` callback into a [Listenable] for GoRouter's
/// `refreshListenable` — see [appRouterProvider] for why this goes through
/// Riverpod's own listener rather than a second, independent subscription
/// to the underlying auth stream.
class _AuthRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
