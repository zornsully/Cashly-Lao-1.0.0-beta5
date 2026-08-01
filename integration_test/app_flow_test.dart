import 'dart:convert';
import 'dart:io';

import 'package:cashly_lao/core/constants/app_symbols.dart';
import 'package:cashly_lao/core/widgets/primary_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:cashly_lao/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The Auth Emulator never sends a real verification email, so a freshly
/// registered user is permanently stuck at `emailVerified == false` (and
/// the router gates every unverified user to `VerifyEmailScreen`) unless
/// something completes the same verification flow a real email click
/// would.
///
/// Two prior approaches were tried and confirmed wrong by direct testing,
/// not assumption: (1) the self-service `identitytoolkit.googleapis.com/
/// v1/accounts:update` endpoint with the user's own `idToken` returns
/// `200` but silently ignores `emailVerified` -- real Identity Platform
/// behavior, since a signed-in user can't self-grant verification that
/// way; (2) a guessed admin-only path (`/emulator/v1/projects/{id}/
/// accounts:update`) returned a real `404` -- it doesn't exist. The
/// **actual** documented emulator testing surface is
/// `/emulator/v1/projects/{id}/oobCodes`, which lists every pending
/// out-of-band action (including the `VERIFY_EMAIL` one this app's own
/// `sendEmailVerification()` call generates on registration, with a real
/// `oobCode`) -- exactly what the emulator's own console log prints as a
/// clickable link. Submitting that `oobCode` to the standard
/// `accounts:update` endpoint completes verification exactly as clicking
/// the real link would.
Future<void> _markCurrentUserEmailVerifiedInEmulator() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final client = HttpClient();
  try {
    final listRequest = await client.getUrl(
      Uri.parse(
        'http://localhost:9099/emulator/v1/projects/cashly-lao/oobCodes',
      ),
    );
    final listResponse = await listRequest.close();
    final listBody = await listResponse.transform(utf8.decoder).join();
    final oobCodes = (jsonDecode(listBody) as Map<String, dynamic>)['oobCodes']
        as List<dynamic>;
    final match = oobCodes.cast<Map<String, dynamic>>().lastWhere(
      (entry) =>
          entry['email'] == user.email && entry['requestType'] == 'VERIFY_EMAIL',
      orElse: () => throw StateError(
        'No pending VERIFY_EMAIL oobCode found for ${user.email}',
      ),
    );

    final confirmRequest = await client.postUrl(
      Uri.parse(
        'http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:update?key=fake-api-key',
      ),
    );
    confirmRequest.headers.contentType = ContentType.json;
    confirmRequest.write(jsonEncode({'oobCode': match['oobCode']}));
    final confirmResponse = await confirmRequest.close();
    final confirmBody = await confirmResponse.transform(utf8.decoder).join();
    if (confirmResponse.statusCode != 200) {
      throw StateError(
        'Confirming oobCode did not verify the user '
        '(${confirmResponse.statusCode}): $confirmBody',
      );
    }
  } finally {
    client.close();
  }
  await user.reload();
}

/// End-to-end user journey against the real app, wired to the local
/// Firebase Emulator Suite (never production — see `main.dart`'s
/// `_useFirebaseEmulator` gate and `integration_test/README.md`).
///
/// Must be run with `--dart-define=USE_FIREBASE_EMULATOR=true` and a live
/// `firebase emulators:start --only auth,firestore` (or `emulators:exec`)
/// alongside it. See `integration_test/README.md` for the exact commands.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets(
    'register, manage finances, change language, logout, delete account',
    (tester) async {
      // Fixed, narrow (phone-shaped) viewport for the whole test — both the
      // navigation shell and the Dashboard AppBar's Reports/Savings-Goals
      // shortcuts switch to a different (sidebar / no-AppBar) layout past
      // 760px, and this test targets the mobile bottom-nav + AppBar-icon
      // shape consistently rather than branching on layout.
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch;
      final email = 'integration-test-$uniqueSuffix@example.com';
      const password = 'TestPass123';

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Firebase Auth persists a signed-in session locally across separate
      // process launches (even against the emulator) -- without this, a
      // user left signed in by an earlier, partial run of this same test
      // would resume here instead of landing on the public flow this test
      // actually wants to exercise from scratch.
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // ---- 1. Register ----------------------------------------------
      // The router's initial location is the public landing page (marketing
      // routes are exempt from the auth redirect), not Login directly --
      // "Open app" navigates to /dashboard, which the redirect then bounces
      // an unauthenticated visitor to /login from. At this test's narrow
      // (mobile-shaped) viewport, landing_page.dart renders this as an
      // icon-only button with a Tooltip (not a visible Text widget) -- see
      // its own `narrow` branch.
      expect(find.byTooltip('Open app'), findsOneWidget);
      await tester.tap(find.byTooltip('Open app'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.signIn), findsOneWidget);
      await tester.tap(find.text(l10n.signUpLink));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Integration Test',
      );
      await tester.enterText(find.byType(TextFormField).at(1), email);
      await tester.enterText(find.byType(TextFormField).at(2), password);
      await tester.enterText(find.byType(TextFormField).at(3), password);
      await tester.tap(find.text(l10n.createAccountButton));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ---- 2. Verify the emulator user, then land on Dashboard ----------
      // Registration lands on VerifyEmailScreen first (the router gates
      // every unverified signed-in user there) -- the Auth Emulator never
      // sends a real email, so nothing would ever clear that gate without
      // marking it verified directly. Tapping the screen's own real "I've
      // verified" button (which calls the same `reloadUser()` use case a
      // real user's tap would) is both more reliable than a bare SDK
      // reload and a more faithful test of the actual path a real user
      // takes.
      await _markCurrentUserEmailVerifiedInEmulator();
      await tester.tap(find.text(l10n.verifiedButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text(l10n.dashboardTitle), findsWidgets);

      // ---- 3. Create two accounts (second one enables the Transfer /
      // Savings Goal steps below) --------------------------------------
      Future<void> createAccount(String name, String balance) async {
        // The bottom nav's `onlyShowSelected` label behavior hides an
        // unselected tab's inline text label entirely, so tapping it by
        // text only works once it's already selected. Every
        // `NavigationDestination` always carries a `Tooltip` with its
        // label text regardless of selection state (Flutter's own
        // accessibility affordance for icon-only destinations) -- that's
        // reliable for switching *to* a not-yet-selected tab.
        await tester.tap(find.byTooltip(l10n.accountsTitle));
        await tester.pumpAndSettle();
        // Every shell-tab FAB shares the same `addRounded` icon and the
        // shell keeps already-visited branches mounted, so a plain
        // icon-based finder is ambiguous once more than one tab's FAB is
        // alive at once -- each FAB carries its own unique `Key` for
        // exactly this reason (see accounts_list_screen.dart).
        await tester.tap(find.byKey(const ValueKey('accounts-fab')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), name);
        await tester.enterText(find.byType(TextFormField).at(1), balance);
        // `l10n.addAccountButton` ("Add account") appears twice while
        // creating a new account: once as the AppBar title, once as the
        // submit button's label -- target the actual `PrimaryButton`
        // widget directly rather than guessing tree-traversal order with
        // `.first`/`.last` against duplicate text.
        await tester.tap(find.byType(PrimaryButton));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      await createAccount('Main Wallet', '1000000');
      await createAccount('Savings Jar', '0');
      expect(find.text('Main Wallet'), findsWidgets);
      expect(find.text('Savings Jar'), findsWidgets);

      // ---- 4/5. Add an income and an expense transaction ---------------
      Future<void> pickDropdownOption(int dropdownIndex, String text) async {
        await tester.tap(
          find.byType(DropdownButtonFormField<String>).at(dropdownIndex),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byTooltip(l10n.transactionsTabLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('transactions-fab')));
      await tester.pumpAndSettle();
      // Default segment is Expense; switch to Income for this one.
      await tester.tap(find.text(l10n.incomeLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '500000');
      await pickDropdownOption(0, 'Main Wallet');
      await pickDropdownOption(1, 'Salary');
      // `l10n.addTransactionButton` also appears as the AppBar title on
      // this form -- target the `PrimaryButton` widget directly.
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const ValueKey('transactions-fab')));
      await tester.pumpAndSettle();
      // Expense is the default segment already.
      await tester.enterText(find.byType(TextFormField).at(0), '75000');
      await pickDropdownOption(0, 'Main Wallet');
      await pickDropdownOption(1, 'Groceries');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Weekly groceries',
      );
      // `l10n.addTransactionButton` also appears as the AppBar title on
      // this form -- target the `PrimaryButton` widget directly.
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Weekly groceries'), findsOneWidget);

      // ---- 6. Transfer between the two accounts ------------------------
      await tester.tap(find.byKey(const ValueKey('transactions-fab')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.transferLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '100000');
      await pickDropdownOption(0, 'Main Wallet');
      await pickDropdownOption(1, 'Savings Jar');
      // `l10n.addTransactionButton` also appears as the AppBar title on
      // this form -- target the `PrimaryButton` widget directly.
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ---- 7. Edit the expense transaction ------------------------------
      await tester.tap(find.byIcon(AppSymbols.moreVert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.editMenuItem));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '80000');
      await tester.tap(find.text(l10n.saveChangesButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ---- 8. Delete a transaction ---------------------------------------
      await tester.tap(find.byIcon(AppSymbols.moreVert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.delete));
      await tester.pumpAndSettle();
      // AppDialog.confirm's destructive confirm button.
      await tester.tap(find.text(l10n.delete).last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ---- 9. Create a budget --------------------------------------------
      await tester.tap(find.byTooltip(l10n.budgetTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.setBudgetButton).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '2000000');
      // Same AppBar-title-vs-submit-button collision as the account/
      // transaction forms above -- target the `PrimaryButton` directly.
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ---- 10. Create a savings goal --------------------------------------
      // Reached via the Dashboard's Savings Goals shortcut, not a bottom
      // tab, and BudgetsListScreen (where the previous step left off) has
      // no floating action button of its own — go to Dashboard first.
      await tester.tap(find.byTooltip(l10n.dashboardTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.savingsGoalsTooltip));
      await tester.pumpAndSettle();
      // Same ambiguity as the other FABs above -- use its unique key.
      await tester.tap(find.byKey(const ValueKey('savings-goals-fab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'New Laptop');
      await tester.enterText(find.byType(TextFormField).at(1), '8000000');
      await pickDropdownOption(0, 'Savings Jar');
      // Same AppBar-title-vs-submit-button collision as the other forms --
      // target the `PrimaryButton` directly.
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('New Laptop'), findsWidgets);

      // ---- 11. View report ------------------------------------------------
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.reportsTooltip));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text(l10n.reportsTitle), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // ---- 12. Change language, confirm, then switch back ------------------
      await tester.tap(find.byTooltip(l10n.profileTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.settingsTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.languageLao));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final laoLocalizations = await AppLocalizations.delegate.load(
        const Locale('lo'),
      );
      expect(find.text(laoLocalizations.settingsTitle), findsWidgets);
      await tester.tap(find.text(l10n.languageEnglish));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text(l10n.settingsTitle), findsWidgets);

      // ---- 13. Logout safely, then log back in for account deletion -------
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.signOutButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text(l10n.signIn), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), email);
      await tester.enterText(find.byType(TextFormField).at(1), password);
      await tester.tap(find.text(l10n.signIn));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text(l10n.dashboardTitle), findsWidgets);

      // ---- 14. Delete account ------------------------------------------
      await tester.tap(find.byTooltip(l10n.profileTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.deleteAccountButtonLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, password);
      await tester.tap(find.text(l10n.deleteAccountConfirmButton));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text(l10n.signIn), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
