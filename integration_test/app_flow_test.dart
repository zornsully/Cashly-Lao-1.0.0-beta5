import 'package:cashly_lao/core/constants/app_symbols.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:cashly_lao/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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

      // ---- 1. Register ----------------------------------------------
      // Splash -> unauthenticated redirect lands on Login; go to Register.
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

      // ---- 2. Lands on Dashboard --------------------------------------
      expect(find.text(l10n.dashboardTitle), findsWidgets);

      // ---- 3. Create two accounts (second one enables the Transfer /
      // Savings Goal steps below) --------------------------------------
      Future<void> createAccount(String name, String balance) async {
        await tester.tap(find.text(l10n.accountsTitle));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(AppSymbols.addRounded).first);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), name);
        await tester.enterText(find.byType(TextFormField).at(1), balance);
        await tester.tap(find.text(l10n.addAccountButton));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      await createAccount('Main Wallet', '1000000');
      await createAccount('Savings Jar', '0');
      expect(find.text('Main Wallet'), findsWidgets);
      expect(find.text('Savings Jar'), findsWidgets);

      // ---- 4/5. Add an income and an expense transaction ---------------
      Future<void> pickDropdownOption(int dropdownIndex, String text) async {
        await tester.tap(find.byType(DropdownButtonFormField<String>).at(
          dropdownIndex,
        ));
        await tester.pumpAndSettle();
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text(l10n.transactionsTabLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(AppSymbols.addRounded).first);
      await tester.pumpAndSettle();
      // Default segment is Expense; switch to Income for this one.
      await tester.tap(find.text(l10n.incomeLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '500000');
      await pickDropdownOption(0, 'Main Wallet');
      await pickDropdownOption(1, 'Salary');
      await tester.tap(find.text(l10n.addTransactionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byIcon(AppSymbols.addRounded).first);
      await tester.pumpAndSettle();
      // Expense is the default segment already.
      await tester.enterText(find.byType(TextFormField).at(0), '75000');
      await pickDropdownOption(0, 'Main Wallet');
      await pickDropdownOption(1, 'Groceries');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Weekly groceries',
      );
      await tester.tap(find.text(l10n.addTransactionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Weekly groceries'), findsOneWidget);

      // ---- 6. Transfer between the two accounts ------------------------
      await tester.tap(find.byIcon(AppSymbols.addRounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.transferLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '100000');
      await pickDropdownOption(0, 'Main Wallet');
      await pickDropdownOption(1, 'Savings Jar');
      await tester.tap(find.text(l10n.addTransactionButton));
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
      await tester.tap(find.text(l10n.budgetTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.setBudgetButton).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '2000000');
      await tester.tap(find.text(l10n.setBudgetButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ---- 10. Create a savings goal --------------------------------------
      await tester.tap(find.byIcon(AppSymbols.addRounded).first);
      await tester.pumpAndSettle();
      // Reached via the Dashboard's Savings Goals shortcut, not a bottom
      // tab — go there first.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.dashboardTitle).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.savingsGoalsTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(AppSymbols.addRounded));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'New Laptop',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '8000000');
      await pickDropdownOption(0, 'Savings Jar');
      await tester.tap(find.text(l10n.addGoalButton));
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
      await tester.tap(find.text(l10n.profileTitle));
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
      await tester.tap(find.text(l10n.profileTitle));
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
