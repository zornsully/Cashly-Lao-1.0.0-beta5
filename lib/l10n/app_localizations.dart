import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_lo.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('lo'),
  ];

  /// The app's name, shown on the splash screen.
  ///
  /// In en, this message translates to:
  /// **'Cashly'**
  String get appName;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @splashTimeoutMessage.
  ///
  /// In en, this message translates to:
  /// **'This is taking longer than expected. Check your device\'s network connection and try again.'**
  String get splashTimeoutMessage;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep track of your money.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get passwordRequiredError;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @loginFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Please try again.'**
  String get loginFailedMessage;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountPrompt;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpLink;

  /// No description provided for @orDividerLabel.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get orDividerLabel;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @googleSignInFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in with Google. Please try again.'**
  String get googleSignInFailedMessage;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start budgeting smarter in a couple of minutes.'**
  String get registerSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// No description provided for @registerFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not create your account. Please try again.'**
  String get registerFailedMessage;

  /// No description provided for @haveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccountPrompt;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLinkButton;

  /// No description provided for @resetEmailFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not send the reset email. Please try again.'**
  String get resetEmailFailedMessage;

  /// No description provided for @checkEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmailTitle;

  /// No description provided for @checkEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to {email}.'**
  String checkEmailSubtitle(String email);

  /// No description provided for @backToSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignInButton;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification link to {email}. Click it, then continue below.'**
  String verifyEmailSubtitle(String email);

  /// No description provided for @verifiedButton.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified my email'**
  String get verifiedButton;

  /// No description provided for @resendEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resendEmailButton;

  /// No description provided for @resendEmailCountdownButton.
  ///
  /// In en, this message translates to:
  /// **'Resend email ({seconds}s)'**
  String resendEmailCountdownButton(int seconds);

  /// No description provided for @verificationEmailSentMessage.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent.'**
  String get verificationEmailSentMessage;

  /// No description provided for @resendFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not resend the email. Please try again.'**
  String get resendFailedMessage;

  /// No description provided for @notVerifiedYetMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm verification yet.'**
  String get notVerifiedYetMessage;

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutButton;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @offlineBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Offline — changes will sync when you\'re back online'**
  String get offlineBannerMessage;

  /// No description provided for @reportsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTooltip;

  /// No description provided for @previousMonthTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonthTooltip;

  /// No description provided for @nextMonthTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonthTooltip;

  /// No description provided for @showPasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPasswordTooltip;

  /// No description provided for @hidePasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePasswordTooltip;

  /// No description provided for @editDisplayNameTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editDisplayNameTooltip;

  /// No description provided for @deleteTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get deleteTransactionTitle;

  /// No description provided for @deleteTransactionMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes the transaction and reverses its effect on the account\'s balance. This cannot be undone.'**
  String get deleteTransactionMessage;

  /// No description provided for @deleteTransactionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the transaction.'**
  String get deleteTransactionFailedMessage;

  /// No description provided for @welcomeToCashly.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Cashly'**
  String get welcomeToCashly;

  /// No description provided for @addFirstAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first account to start seeing your finances summarized here.'**
  String get addFirstAccountMessage;

  /// No description provided for @addAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccountButton;

  /// No description provided for @recentTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactionsTitle;

  /// No description provided for @noTransactionsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet this month.'**
  String get noTransactionsThisMonth;

  /// No description provided for @spendingByCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get spendingByCategoryTitle;

  /// No description provided for @budgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgetsTitle;

  /// No description provided for @accountBalancesTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Balances'**
  String get accountBalancesTitle;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @totalBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Balance ({currencyCode})'**
  String totalBalanceLabel(String currencyCode);

  /// No description provided for @incomeMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Income (month)'**
  String get incomeMonthLabel;

  /// No description provided for @expenseMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense (month)'**
  String get expenseMonthLabel;

  /// No description provided for @dashboardHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A clear view of your money this month.'**
  String get dashboardHeaderSubtitle;

  /// No description provided for @dashboardQuickActionAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get dashboardQuickActionAddIncome;

  /// No description provided for @dashboardQuickActionAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get dashboardQuickActionAddExpense;

  /// No description provided for @dashboardQuickActionTransferMoney.
  ///
  /// In en, this message translates to:
  /// **'Transfer money'**
  String get dashboardQuickActionTransferMoney;

  /// No description provided for @dashboardQuickActionCreateBudget.
  ///
  /// In en, this message translates to:
  /// **'Create budget'**
  String get dashboardQuickActionCreateBudget;

  /// No description provided for @dashboardMetricTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get dashboardMetricTotalBalance;

  /// No description provided for @dashboardMetricTotalBalanceCaption.
  ///
  /// In en, this message translates to:
  /// **'Live across active accounts'**
  String get dashboardMetricTotalBalanceCaption;

  /// No description provided for @dashboardMetricAlsoBalance.
  ///
  /// In en, this message translates to:
  /// **'Also {currencyCode} {amount}'**
  String dashboardMetricAlsoBalance(String currencyCode, String amount);

  /// No description provided for @dashboardMetricMonthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly income'**
  String get dashboardMetricMonthlyIncome;

  /// No description provided for @dashboardMetricMonthlyExpenses.
  ///
  /// In en, this message translates to:
  /// **'Monthly expenses'**
  String get dashboardMetricMonthlyExpenses;

  /// No description provided for @dashboardMetricNetCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Net cash flow'**
  String get dashboardMetricNetCashFlow;

  /// No description provided for @dashboardMetricThisMonthCaption.
  ///
  /// In en, this message translates to:
  /// **'This calendar month'**
  String get dashboardMetricThisMonthCaption;

  /// No description provided for @dashboardMetricNetCaption.
  ///
  /// In en, this message translates to:
  /// **'Income minus expenses'**
  String get dashboardMetricNetCaption;

  /// No description provided for @dashboardChooseCurrencyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose currency'**
  String get dashboardChooseCurrencyTooltip;

  /// No description provided for @dashboardNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get dashboardNotificationsTooltip;

  /// No description provided for @dashboardNotificationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up.'**
  String get dashboardNotificationsEmptyMessage;

  /// No description provided for @dashboardIncomeExpensePanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Income & expenses'**
  String get dashboardIncomeExpensePanelTitle;

  /// No description provided for @dashboardTrendEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Not enough activity to show a trend yet.'**
  String get dashboardTrendEmptyMessage;

  /// No description provided for @dashboardTrendLast6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get dashboardTrendLast6Months;

  /// No description provided for @dashboardCategoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No recorded expense categories this month.'**
  String get dashboardCategoryEmptyMessage;

  /// No description provided for @dashboardCategoryBreakdownLabel.
  ///
  /// In en, this message translates to:
  /// **'Category breakdown'**
  String get dashboardCategoryBreakdownLabel;

  /// No description provided for @dashboardBudgetsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No active budgets this month.'**
  String get dashboardBudgetsEmptyMessage;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageLao.
  ///
  /// In en, this message translates to:
  /// **'ລາວ'**
  String get languageLao;

  /// No description provided for @languageUpdateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not update your language.'**
  String get languageUpdateFailedMessage;

  /// No description provided for @emailRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get emailRequiredError;

  /// No description provided for @emailInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalidError;

  /// No description provided for @passwordTooShortError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordTooShortError;

  /// No description provided for @passwordNeedsUppercaseError.
  ///
  /// In en, this message translates to:
  /// **'Include at least one uppercase letter.'**
  String get passwordNeedsUppercaseError;

  /// No description provided for @passwordNeedsNumberError.
  ///
  /// In en, this message translates to:
  /// **'Include at least one number.'**
  String get passwordNeedsNumberError;

  /// No description provided for @confirmPasswordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password.'**
  String get confirmPasswordRequiredError;

  /// No description provided for @passwordsDoNotMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatchError;

  /// No description provided for @nameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get nameRequiredError;

  /// No description provided for @nameTooShortError.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters.'**
  String get nameTooShortError;

  /// No description provided for @fieldRequiredError.
  ///
  /// In en, this message translates to:
  /// **'{label} is required.'**
  String fieldRequiredError(String label);

  /// No description provided for @amountRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Amount is required.'**
  String get amountRequiredError;

  /// No description provided for @amountInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number.'**
  String get amountInvalidError;

  /// No description provided for @amountMustBePositiveError.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero.'**
  String get amountMustBePositiveError;

  /// No description provided for @incomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeLabel;

  /// No description provided for @expenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseLabel;

  /// No description provided for @transferLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferLabel;

  /// No description provided for @archivedBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedBadgeLabel;

  /// No description provided for @defaultBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultBadgeLabel;

  /// No description provided for @archiveMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveMenuItem;

  /// No description provided for @unarchiveMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchiveMenuItem;

  /// No description provided for @hideArchivedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide archived'**
  String get hideArchivedTooltip;

  /// No description provided for @showArchivedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get showArchivedTooltip;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesButton;

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @noAccountsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get noAccountsYetTitle;

  /// No description provided for @noAccountsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a cash, wallet, bank, credit card, or savings account to start tracking your money.'**
  String get noAccountsYetMessage;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes \"{name}\". This cannot be undone.'**
  String deleteAccountMessage(String name);

  /// No description provided for @deleteAccountFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account.'**
  String get deleteAccountFailedMessage;

  /// No description provided for @updateAccountFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not update the account.'**
  String get updateAccountFailedMessage;

  /// No description provided for @accountFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountFormEditTitle;

  /// No description provided for @accountNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountNameLabel;

  /// No description provided for @accountTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountTypeLabel;

  /// No description provided for @currentBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalanceLabel;

  /// No description provided for @initialBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Initial balance'**
  String get initialBalanceLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @accountCurrencyLockedHelper.
  ///
  /// In en, this message translates to:
  /// **'Currency can\'t be changed after an account is created.'**
  String get accountCurrencyLockedHelper;

  /// No description provided for @saveAccountFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not save the account. Please try again.'**
  String get saveAccountFailedMessage;

  /// No description provided for @accountTypeCashLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCashLabel;

  /// No description provided for @accountTypeWalletLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get accountTypeWalletLabel;

  /// No description provided for @accountTypeBankLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountTypeBankLabel;

  /// No description provided for @accountTypeCreditCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get accountTypeCreditCardLabel;

  /// No description provided for @accountTypeSavingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get accountTypeSavingsLabel;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @noExpenseCategoriesYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No expense categories yet'**
  String get noExpenseCategoriesYetTitle;

  /// No description provided for @noIncomeCategoriesYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No income categories yet'**
  String get noIncomeCategoriesYetTitle;

  /// No description provided for @addCategoryToStartMessage.
  ///
  /// In en, this message translates to:
  /// **'Add one to start tagging your transactions.'**
  String get addCategoryToStartMessage;

  /// No description provided for @addCategoryButton.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategoryButton;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete category?'**
  String get deleteCategoryTitle;

  /// No description provided for @deleteCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes \"{name}\". This cannot be undone.'**
  String deleteCategoryMessage(String name);

  /// No description provided for @deleteCategoryFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the category.'**
  String get deleteCategoryFailedMessage;

  /// No description provided for @updateCategoryFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not update the category.'**
  String get updateCategoryFailedMessage;

  /// No description provided for @reorderCategoriesFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not save the new order.'**
  String get reorderCategoriesFailedMessage;

  /// No description provided for @categoryFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoryFormEditTitle;

  /// No description provided for @categoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryNameLabel;

  /// No description provided for @categoryTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get categoryTypeLabel;

  /// No description provided for @saveCategoryFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not save the category. Please try again.'**
  String get saveCategoryFailedMessage;

  /// No description provided for @budgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetTitle;

  /// No description provided for @deleteBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete budget?'**
  String get deleteBudgetTitle;

  /// No description provided for @deleteBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes the budget for \"{name}\" this month. This cannot be undone.'**
  String deleteBudgetMessage(String name);

  /// No description provided for @deleteBudgetFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the budget.'**
  String get deleteBudgetFailedMessage;

  /// No description provided for @addExpenseCategoryFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Add an expense category first, then set a budget for it.'**
  String get addExpenseCategoryFirstMessage;

  /// No description provided for @noBudgetSetLabel.
  ///
  /// In en, this message translates to:
  /// **'No budget set'**
  String get noBudgetSetLabel;

  /// No description provided for @setBudgetButton.
  ///
  /// In en, this message translates to:
  /// **'Set budget'**
  String get setBudgetButton;

  /// No description provided for @budgetFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get budgetFormEditTitle;

  /// No description provided for @categoryAndMonthLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Category and month can\'t be changed here — delete and re-create the budget instead.'**
  String get categoryAndMonthLockedMessage;

  /// No description provided for @monthlyLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get monthlyLimitLabel;

  /// No description provided for @budgetCurrencyRestrictionMessage.
  ///
  /// In en, this message translates to:
  /// **'Only transactions in this currency count toward this budget.'**
  String get budgetCurrencyRestrictionMessage;

  /// No description provided for @deleteBudgetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete budget'**
  String get deleteBudgetTooltip;

  /// No description provided for @overspentByMessage.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String overspentByMessage(String amount);

  /// No description provided for @remainingAmountMessage.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String remainingAmountMessage(String amount);

  /// No description provided for @saveBudgetFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not save the budget. Please try again.'**
  String get saveBudgetFailedMessage;

  /// No description provided for @savingsGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get savingsGoalsTitle;

  /// No description provided for @savingsGoalsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get savingsGoalsTooltip;

  /// No description provided for @noSavingsGoalsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet'**
  String get noSavingsGoalsYetTitle;

  /// No description provided for @noSavingsGoalsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Set a target and link an account to start tracking progress toward it.'**
  String get noSavingsGoalsYetMessage;

  /// No description provided for @addGoalButton.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get addGoalButton;

  /// No description provided for @goalFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalFormEditTitle;

  /// No description provided for @goalNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get goalNameLabel;

  /// No description provided for @targetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get targetAmountLabel;

  /// No description provided for @linkedAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked account'**
  String get linkedAccountLabel;

  /// No description provided for @linkedAccountLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Linked account can\'t be changed here — delete and re-create the goal instead.'**
  String get linkedAccountLockedMessage;

  /// No description provided for @createNewAccountOption.
  ///
  /// In en, this message translates to:
  /// **'+ Add a new account'**
  String get createNewAccountOption;

  /// No description provided for @accountAlreadyBacksGoalError.
  ///
  /// In en, this message translates to:
  /// **'This account already backs another active savings goal.'**
  String get accountAlreadyBacksGoalError;

  /// No description provided for @noEligibleAccountsMessage.
  ///
  /// In en, this message translates to:
  /// **'All your accounts already back another active goal — add a new one to continue.'**
  String get noEligibleAccountsMessage;

  /// No description provided for @autoContributionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto contribution'**
  String get autoContributionSectionTitle;

  /// No description provided for @autoContributionToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Remind me to contribute'**
  String get autoContributionToggleLabel;

  /// No description provided for @autoContributionAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Contribution amount'**
  String get autoContributionAmountLabel;

  /// No description provided for @autoContributionFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get autoContributionFrequencyLabel;

  /// No description provided for @goalFrequencyWeeklyLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get goalFrequencyWeeklyLabel;

  /// No description provided for @goalFrequencyBiweeklyLabel.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get goalFrequencyBiweeklyLabel;

  /// No description provided for @goalFrequencyMonthlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get goalFrequencyMonthlyLabel;

  /// No description provided for @saveGoalFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not save the goal. Please try again.'**
  String get saveGoalFailedMessage;

  /// No description provided for @deleteGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete goal?'**
  String get deleteGoalTitle;

  /// No description provided for @deleteGoalMessage.
  ///
  /// In en, this message translates to:
  /// **'This deletes the goal. It doesn\'t affect the linked account or its balance. This cannot be undone.'**
  String get deleteGoalMessage;

  /// No description provided for @deleteGoalFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the goal.'**
  String get deleteGoalFailedMessage;

  /// No description provided for @contributeButton.
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get contributeButton;

  /// No description provided for @contributionSourceAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get contributionSourceAccountLabel;

  /// No description provided for @contributionAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get contributionAmountLabel;

  /// No description provided for @confirmContributionButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm contribution'**
  String get confirmContributionButton;

  /// No description provided for @contributionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not save the contribution. Please try again.'**
  String get contributionFailedMessage;

  /// No description provided for @contributionDueBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Your {amount} contribution is due.'**
  String contributionDueBannerMessage(String amount);

  /// No description provided for @goalCompletedBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goalCompletedBadgeLabel;

  /// No description provided for @goalDueBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get goalDueBadgeLabel;

  /// No description provided for @estimatedCompletionScheduledMessage.
  ///
  /// In en, this message translates to:
  /// **'On track to finish by {date}'**
  String estimatedCompletionScheduledMessage(String date);

  /// No description provided for @estimatedCompletionTrailingAverageMessage.
  ///
  /// In en, this message translates to:
  /// **'Estimated to finish around {date} at your recent pace'**
  String estimatedCompletionTrailingAverageMessage(String date);

  /// No description provided for @estimatedCompletionInsufficientDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a few contributions to see an estimated finish date.'**
  String get estimatedCompletionInsufficientDataMessage;

  /// No description provided for @estimatedCompletionCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your goal.'**
  String get estimatedCompletionCompletedMessage;

  /// No description provided for @accountActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Account activity'**
  String get accountActivityTitle;

  /// No description provided for @noAccountActivityYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Contributions and other transactions on the linked account will show up here.'**
  String get noAccountActivityYetMessage;

  /// No description provided for @goalCelebrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal reached!'**
  String get goalCelebrationTitle;

  /// No description provided for @goalCelebrationMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve hit your \"{goalName}\" goal.'**
  String goalCelebrationMessage(String goalName);

  /// No description provided for @goalNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This goal no longer exists.'**
  String get goalNotFoundMessage;

  /// No description provided for @linkedAccountArchivedMessage.
  ///
  /// In en, this message translates to:
  /// **'This goal\'s linked account is archived.'**
  String get linkedAccountArchivedMessage;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @transactionsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTabLabel;

  /// No description provided for @noTransactionsInMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions in {month}'**
  String noTransactionsInMonthTitle(String month);

  /// No description provided for @addFirstTransactionMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first income or expense for this month.'**
  String get addFirstTransactionMessage;

  /// No description provided for @addTransactionButton.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addTransactionButton;

  /// No description provided for @searchTransactionsHint.
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get searchTransactionsHint;

  /// No description provided for @searchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTooltip;

  /// No description provided for @closeSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearchTooltip;

  /// No description provided for @filterSortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter & sort'**
  String get filterSortTooltip;

  /// No description provided for @filterSortSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter & sort'**
  String get filterSortSheetTitle;

  /// No description provided for @typeFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeFilterLabel;

  /// No description provided for @allTypesLabel.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get allTypesLabel;

  /// No description provided for @accountFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountFilterLabel;

  /// No description provided for @allAccountsLabel.
  ///
  /// In en, this message translates to:
  /// **'All accounts'**
  String get allAccountsLabel;

  /// No description provided for @categoryFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryFilterLabel;

  /// No description provided for @allCategoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategoriesLabel;

  /// No description provided for @sortByLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortByLabel;

  /// No description provided for @sortDateNewestLabel.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortDateNewestLabel;

  /// No description provided for @sortDateOldestLabel.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortDateOldestLabel;

  /// No description provided for @sortAmountHighLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount: high to low'**
  String get sortAmountHighLabel;

  /// No description provided for @sortAmountLowLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount: low to high'**
  String get sortAmountLowLabel;

  /// No description provided for @clearFiltersButton.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFiltersButton;

  /// No description provided for @noMatchingTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get noMatchingTransactionsTitle;

  /// No description provided for @noMatchingTransactionsMessage.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters.'**
  String get noMatchingTransactionsMessage;

  /// No description provided for @transferToLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer to {account}'**
  String transferToLabel(String account);

  /// No description provided for @transferFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From {account}'**
  String transferFromLabel(String account);

  /// No description provided for @unknownAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown account'**
  String get unknownAccountLabel;

  /// No description provided for @uncategorizedLabel.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorizedLabel;

  /// No description provided for @transactionFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get transactionFormEditTitle;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @fromAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get fromAccountLabel;

  /// No description provided for @accountFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountFieldLabel;

  /// No description provided for @unavailableAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Unavailable account — choose another'**
  String get unavailableAccountLabel;

  /// No description provided for @pleaseSelectAccountError.
  ///
  /// In en, this message translates to:
  /// **'Please select an account.'**
  String get pleaseSelectAccountError;

  /// No description provided for @toAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get toAccountLabel;

  /// No description provided for @pickFromAccountFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Pick a from account first'**
  String get pickFromAccountFirstMessage;

  /// No description provided for @transferSameCurrencyHelperText.
  ///
  /// In en, this message translates to:
  /// **'Must be the same currency as the from account'**
  String get transferSameCurrencyHelperText;

  /// No description provided for @pleaseSelectDestinationAccountError.
  ///
  /// In en, this message translates to:
  /// **'Please select a destination account.'**
  String get pleaseSelectDestinationAccountError;

  /// No description provided for @cantTransferToSameAccountError.
  ///
  /// In en, this message translates to:
  /// **'Can\'t transfer to the same account.'**
  String get cantTransferToSameAccountError;

  /// No description provided for @transferSameCurrencyError.
  ///
  /// In en, this message translates to:
  /// **'Must be the same currency as the from account.'**
  String get transferSameCurrencyError;

  /// No description provided for @categoryFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryFieldLabel;

  /// No description provided for @unavailableCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Unavailable category — choose another'**
  String get unavailableCategoryLabel;

  /// No description provided for @pleaseSelectCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Please select a category.'**
  String get pleaseSelectCategoryError;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @noteOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptionalLabel;

  /// No description provided for @saveTransactionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not save the transaction. Please try again.'**
  String get saveTransactionFailedMessage;

  /// No description provided for @archivedSuffixFormat.
  ///
  /// In en, this message translates to:
  /// **'{name} (Archived)'**
  String archivedSuffixFormat(String name);

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @exportReportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get exportReportTooltip;

  /// No description provided for @exportReportSubject.
  ///
  /// In en, this message translates to:
  /// **'Cashly report — {month}'**
  String exportReportSubject(String month);

  /// No description provided for @exportReportFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not export the report. Please try again.'**
  String get exportReportFailedMessage;

  /// No description provided for @convertedTotalsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Converted total'**
  String get convertedTotalsCardTitle;

  /// No description provided for @convertedTotalsCaption.
  ///
  /// In en, this message translates to:
  /// **'Approximate total across all your currencies, shown in {currency}.'**
  String convertedTotalsCaption(String currency);

  /// No description provided for @convertedTotalsRatesAsOf.
  ///
  /// In en, this message translates to:
  /// **'Rates as of {date} · Rates by ExchangeRate-API'**
  String convertedTotalsRatesAsOf(String date);

  /// No description provided for @convertedTotalsPartialWarning.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t include {currencies} — no exchange rate available.'**
  String convertedTotalsPartialWarning(String currencies);

  /// No description provided for @nothingToReportYetTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to report yet'**
  String get nothingToReportYetTitle;

  /// No description provided for @nothingToReportYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Once you record income or expenses for this month, you\'ll see monthly summaries, spending breakdowns, and trends here.'**
  String get nothingToReportYetMessage;

  /// No description provided for @incomeExpenseTrendSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Income vs Expense Trend'**
  String get incomeExpenseTrendSectionTitle;

  /// No description provided for @spendingByCategorySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get spendingByCategorySectionTitle;

  /// No description provided for @budgetVsActualSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget vs Actual'**
  String get budgetVsActualSectionTitle;

  /// No description provided for @seeAllButton.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAllButton;

  /// No description provided for @netLabel.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get netLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @monthIncomeExpenseSummaryMessage.
  ///
  /// In en, this message translates to:
  /// **'{month} — Income {income}, Expense {expense}'**
  String monthIncomeExpenseSummaryMessage(
    String month,
    String income,
    String expense,
  );

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearanceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSectionTitle;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeSystemLabel.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystemLabel;

  /// No description provided for @themeLightLabel.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLightLabel;

  /// No description provided for @themeDarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDarkLabel;

  /// No description provided for @themeUpdateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not update your theme.'**
  String get themeUpdateFailedMessage;

  /// No description provided for @securitySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySectionTitle;

  /// No description provided for @appLockToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLockToggleLabel;

  /// No description provided for @appLockToggleHelperMessage.
  ///
  /// In en, this message translates to:
  /// **'Require your fingerprint, face, or device PIN to open Cashly.'**
  String get appLockToggleHelperMessage;

  /// No description provided for @appLockUnsupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Set up a fingerprint, face unlock, or screen lock on this device to use app lock.'**
  String get appLockUnsupportedMessage;

  /// No description provided for @appLockUpdateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not update app lock. Please try again.'**
  String get appLockUpdateFailedMessage;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Cashly is locked'**
  String get appLockTitle;

  /// No description provided for @appLockReasonMessage.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to open Cashly'**
  String get appLockReasonMessage;

  /// No description provided for @appLockFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get appLockFailedMessage;

  /// No description provided for @appLockUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Authentication isn\'t available right now. Please try again.'**
  String get appLockUnavailableMessage;

  /// No description provided for @appLockUnlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get appLockUnlockButton;

  /// No description provided for @notificationsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSectionTitle;

  /// No description provided for @notificationsToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget & balance alerts'**
  String get notificationsToggleLabel;

  /// No description provided for @notificationsToggleHelperMessage.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a budget goes over its limit, an account balance goes negative, or a savings goal contribution is due — even when Cashly isn\'t open.'**
  String get notificationsToggleHelperMessage;

  /// No description provided for @notificationsUpdateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not update notifications. Please try again.'**
  String get notificationsUpdateFailedMessage;

  /// No description provided for @notificationsPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for Cashly in your device settings.'**
  String get notificationsPermissionDeniedMessage;

  /// No description provided for @budgetExceededNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded'**
  String get budgetExceededNotificationTitle;

  /// No description provided for @budgetExceededNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve gone over your {category} budget for this month.'**
  String budgetExceededNotificationBody(String category);

  /// No description provided for @negativeBalanceNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Account balance negative'**
  String get negativeBalanceNotificationTitle;

  /// No description provided for @negativeBalanceNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your {account} balance has gone negative.'**
  String negativeBalanceNotificationBody(String account);

  /// No description provided for @goalReminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings goal reminder'**
  String get goalReminderNotificationTitle;

  /// No description provided for @goalReminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Time for your {frequency} contribution to \"{goalName}\".'**
  String goalReminderNotificationBody(String frequency, String goalName);

  /// No description provided for @defaultsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Defaults'**
  String get defaultsSectionTitle;

  /// No description provided for @defaultCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get defaultCurrencyLabel;

  /// No description provided for @defaultCurrencyHelperMessage.
  ///
  /// In en, this message translates to:
  /// **'Used to pre-select the currency when you create a new account or budget.'**
  String get defaultCurrencyHelperMessage;

  /// No description provided for @defaultCurrencyUpdateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not update your default currency.'**
  String get defaultCurrencyUpdateFailedMessage;

  /// No description provided for @currencyDisplayFormat.
  ///
  /// In en, this message translates to:
  /// **'{code} — {name}'**
  String currencyDisplayFormat(String code, String name);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @editNameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editNameDialogTitle;

  /// No description provided for @nameUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Name updated.'**
  String get nameUpdatedMessage;

  /// No description provided for @nameUpdateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not update your name.'**
  String get nameUpdateFailedMessage;

  /// No description provided for @deleteUserAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteUserAccountTitle;

  /// No description provided for @deleteUserAccountMessageWithPassword.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all of your data — accounts, transactions, categories, and budgets. This cannot be undone.'**
  String get deleteUserAccountMessageWithPassword;

  /// No description provided for @deleteUserAccountMessageGoogle.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all of your data — accounts, transactions, categories, and budgets. This cannot be undone. You\'ll be asked to confirm with Google on the next step.'**
  String get deleteUserAccountMessageGoogle;

  /// No description provided for @confirmYourPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPasswordLabel;

  /// No description provided for @deleteAccountConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountConfirmButton;

  /// No description provided for @deleteUserAccountFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account.'**
  String get deleteUserAccountFailedMessage;

  /// No description provided for @addYourNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get addYourNameLabel;

  /// No description provided for @emailVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerifiedLabel;

  /// No description provided for @notVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get notVerifiedLabel;

  /// No description provided for @memberSinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSinceLabel;

  /// No description provided for @deleteAccountButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountButtonLabel;

  /// No description provided for @iconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get iconLabel;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @smartMoneyScoreCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Cashly Smart Money Score'**
  String get smartMoneyScoreCardTitle;

  /// No description provided for @smartMoneyScoreCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Balance movement leads. Habits provide the context.'**
  String get smartMoneyScoreCardSubtitle;

  /// No description provided for @smartMoneyScoreWhatIsShapingLabel.
  ///
  /// In en, this message translates to:
  /// **'What is shaping this month'**
  String get smartMoneyScoreWhatIsShapingLabel;

  /// No description provided for @smartMoneyScorePracticalNextStepLabel.
  ///
  /// In en, this message translates to:
  /// **'A practical next step'**
  String get smartMoneyScorePracticalNextStepLabel;

  /// No description provided for @smartMoneyScoreWhyThisScore.
  ///
  /// In en, this message translates to:
  /// **'Why this score?'**
  String get smartMoneyScoreWhyThisScore;

  /// No description provided for @smartMoneyScoreComparedWithOpening.
  ///
  /// In en, this message translates to:
  /// **'Compared with your month opening balance'**
  String get smartMoneyScoreComparedWithOpening;

  /// No description provided for @smartMoneyScoreNeutralBaseline.
  ///
  /// In en, this message translates to:
  /// **'Using a neutral baseline until enough data is available'**
  String get smartMoneyScoreNeutralBaseline;

  /// No description provided for @smartMoneyScoreMonthlyHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY SCORE · / {max}'**
  String smartMoneyScoreMonthlyHeroLabel(int max);

  /// No description provided for @smartMoneyScoreStatusNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data'**
  String get smartMoneyScoreStatusNotEnoughData;

  /// No description provided for @smartMoneyScoreStatusExcellentGrowth.
  ///
  /// In en, this message translates to:
  /// **'Excellent Growth'**
  String get smartMoneyScoreStatusExcellentGrowth;

  /// No description provided for @smartMoneyScoreStatusGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get smartMoneyScoreStatusGrowing;

  /// No description provided for @smartMoneyScoreStatusStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get smartMoneyScoreStatusStable;

  /// No description provided for @smartMoneyScoreStatusDeclining.
  ///
  /// In en, this message translates to:
  /// **'Declining'**
  String get smartMoneyScoreStatusDeclining;

  /// No description provided for @smartMoneyScoreStatusNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get smartMoneyScoreStatusNeedsAttention;

  /// No description provided for @smartMoneyScoreStatusExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get smartMoneyScoreStatusExcellent;

  /// No description provided for @smartMoneyScoreStatusGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get smartMoneyScoreStatusGood;

  /// No description provided for @smartMoneyScoreStatusFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get smartMoneyScoreStatusFair;

  /// No description provided for @smartMoneyScoreStatusHighRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get smartMoneyScoreStatusHighRisk;

  /// No description provided for @financialInsightPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get financialInsightPeriodToday;

  /// No description provided for @financialInsightPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get financialInsightPeriodWeek;

  /// No description provided for @financialInsightPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get financialInsightPeriodMonth;

  /// No description provided for @smartMoneyScoreBudgetNoneSet.
  ///
  /// In en, this message translates to:
  /// **'No budgets set'**
  String get smartMoneyScoreBudgetNoneSet;

  /// No description provided for @smartMoneyScoreBudgetOverCount.
  ///
  /// In en, this message translates to:
  /// **'{count} over budget'**
  String smartMoneyScoreBudgetOverCount(int count);

  /// No description provided for @smartMoneyScoreBudgetNearlyFullCount.
  ///
  /// In en, this message translates to:
  /// **'{count} nearly full'**
  String smartMoneyScoreBudgetNearlyFullCount(int count);

  /// No description provided for @smartMoneyScoreBudgetOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get smartMoneyScoreBudgetOnTrack;

  /// No description provided for @smartMoneyScoreBreakdownSheetDescription.
  ///
  /// In en, this message translates to:
  /// **'The monthly score is calculated from the same synced financial data shown in your dashboard. Balance movement is always the main factor.'**
  String get smartMoneyScoreBreakdownSheetDescription;

  /// No description provided for @smartMoneyScoreBreakdownUnavailableFallback.
  ///
  /// In en, this message translates to:
  /// **'Cashly needs a reliable month opening balance before it can give a full comparison. The score stays neutral rather than guessing.'**
  String get smartMoneyScoreBreakdownUnavailableFallback;

  /// No description provided for @smartMoneyScoreSectionBalanceMovement.
  ///
  /// In en, this message translates to:
  /// **'Balance movement'**
  String get smartMoneyScoreSectionBalanceMovement;

  /// No description provided for @smartMoneyScoreSectionMonthActivity.
  ///
  /// In en, this message translates to:
  /// **'This month\'s financial activity'**
  String get smartMoneyScoreSectionMonthActivity;

  /// No description provided for @smartMoneyScoreSectionFormula.
  ///
  /// In en, this message translates to:
  /// **'Formula'**
  String get smartMoneyScoreSectionFormula;

  /// No description provided for @smartMoneyScoreRowOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get smartMoneyScoreRowOpeningBalance;

  /// No description provided for @smartMoneyScoreRowCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get smartMoneyScoreRowCurrentBalance;

  /// No description provided for @smartMoneyScoreRowBalanceChange.
  ///
  /// In en, this message translates to:
  /// **'Balance change'**
  String get smartMoneyScoreRowBalanceChange;

  /// No description provided for @smartMoneyScoreRowBalanceGrowthContribution.
  ///
  /// In en, this message translates to:
  /// **'Balance-growth contribution'**
  String get smartMoneyScoreRowBalanceGrowthContribution;

  /// No description provided for @smartMoneyScoreRowIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get smartMoneyScoreRowIncome;

  /// No description provided for @smartMoneyScoreRowExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get smartMoneyScoreRowExpenses;

  /// No description provided for @smartMoneyScoreRowNetCashFlowSavings.
  ///
  /// In en, this message translates to:
  /// **'Net cash flow / savings'**
  String get smartMoneyScoreRowNetCashFlowSavings;

  /// No description provided for @smartMoneyScoreRowBudgetPerformance.
  ///
  /// In en, this message translates to:
  /// **'Budget performance'**
  String get smartMoneyScoreRowBudgetPerformance;

  /// No description provided for @smartMoneyScoreRowPreviousPeriodComparison.
  ///
  /// In en, this message translates to:
  /// **'Previous-period comparison'**
  String get smartMoneyScoreRowPreviousPeriodComparison;

  /// No description provided for @smartMoneyScoreRowOverdueBills.
  ///
  /// In en, this message translates to:
  /// **'Overdue bills'**
  String get smartMoneyScoreRowOverdueBills;

  /// No description provided for @smartMoneyScoreRowStartingScore.
  ///
  /// In en, this message translates to:
  /// **'Starting score'**
  String get smartMoneyScoreRowStartingScore;

  /// No description provided for @smartMoneyScoreRowBehaviourModifier.
  ///
  /// In en, this message translates to:
  /// **'Behaviour modifier'**
  String get smartMoneyScoreRowBehaviourModifier;

  /// No description provided for @smartMoneyScoreRowFinalMonthlyScore.
  ///
  /// In en, this message translates to:
  /// **'Final monthly score'**
  String get smartMoneyScoreRowFinalMonthlyScore;

  /// No description provided for @smartMoneyScoreValueNotIncludedYet.
  ///
  /// In en, this message translates to:
  /// **'Not included yet'**
  String get smartMoneyScoreValueNotIncludedYet;

  /// No description provided for @smartMoneyScoreValueNeutralUntilBaseline.
  ///
  /// In en, this message translates to:
  /// **'Neutral until a baseline is available'**
  String get smartMoneyScoreValueNeutralUntilBaseline;

  /// No description provided for @smartMoneyScoreValueBehaviourModifierPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} points (capped at ±10)'**
  String smartMoneyScoreValueBehaviourModifierPoints(String points);

  /// No description provided for @smartMoneyScorePointsSuffix.
  ///
  /// In en, this message translates to:
  /// **'{points} points'**
  String smartMoneyScorePointsSuffix(String points);

  /// No description provided for @smartMoneyScoreValueNoComparisonYet.
  ///
  /// In en, this message translates to:
  /// **'No comparison yet'**
  String get smartMoneyScoreValueNoComparisonYet;

  /// No description provided for @smartMoneyScoreImpactIncomePositive.
  ///
  /// In en, this message translates to:
  /// **'Income is ahead of expenses.'**
  String get smartMoneyScoreImpactIncomePositive;

  /// No description provided for @smartMoneyScoreImpactIncomeNegative.
  ///
  /// In en, this message translates to:
  /// **'Expenses are ahead of income.'**
  String get smartMoneyScoreImpactIncomeNegative;

  /// No description provided for @smartMoneyScoreImpactIncomeNeutral.
  ///
  /// In en, this message translates to:
  /// **'Income and expenses are currently even or unavailable.'**
  String get smartMoneyScoreImpactIncomeNeutral;

  /// No description provided for @smartMoneyScoreImpactSavingsPositive.
  ///
  /// In en, this message translates to:
  /// **'Positive cash flow supports the score.'**
  String get smartMoneyScoreImpactSavingsPositive;

  /// No description provided for @smartMoneyScoreImpactSavingsNegative.
  ///
  /// In en, this message translates to:
  /// **'Negative cash flow lowers the behaviour modifier slightly.'**
  String get smartMoneyScoreImpactSavingsNegative;

  /// No description provided for @smartMoneyScoreImpactSavingsNeutral.
  ///
  /// In en, this message translates to:
  /// **'No cash-flow modifier was applied.'**
  String get smartMoneyScoreImpactSavingsNeutral;

  /// No description provided for @smartMoneyScoreImpactBudgetPositive.
  ///
  /// In en, this message translates to:
  /// **'Current budgets remain on track.'**
  String get smartMoneyScoreImpactBudgetPositive;

  /// No description provided for @smartMoneyScoreImpactBudgetNegative.
  ///
  /// In en, this message translates to:
  /// **'Budget room is tight or a budget is exceeded.'**
  String get smartMoneyScoreImpactBudgetNegative;

  /// No description provided for @smartMoneyScoreImpactBudgetNeutral.
  ///
  /// In en, this message translates to:
  /// **'No active budget modifier was applied.'**
  String get smartMoneyScoreImpactBudgetNeutral;

  /// No description provided for @smartMoneyScoreImpactTrendPositive.
  ///
  /// In en, this message translates to:
  /// **'Spending is lower than the comparable period.'**
  String get smartMoneyScoreImpactTrendPositive;

  /// No description provided for @smartMoneyScoreImpactTrendNegative.
  ///
  /// In en, this message translates to:
  /// **'Spending is notably higher than the comparable period.'**
  String get smartMoneyScoreImpactTrendNegative;

  /// No description provided for @smartMoneyScoreImpactTrendNeutral.
  ///
  /// In en, this message translates to:
  /// **'There is not enough comparable spending data yet.'**
  String get smartMoneyScoreImpactTrendNeutral;

  /// No description provided for @smartMoneyScoreImpactBillsSupporting.
  ///
  /// In en, this message translates to:
  /// **'No verified bill or reminder record is available, so no bill penalty was added.'**
  String get smartMoneyScoreImpactBillsSupporting;

  /// No description provided for @smartMoneyScoreMetricNetCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Net cash flow'**
  String get smartMoneyScoreMetricNetCashFlow;

  /// No description provided for @smartMoneyScoreMetricComparedLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Compared with last month'**
  String get smartMoneyScoreMetricComparedLastMonth;

  /// No description provided for @smartMoneyScoreMetricExpensesChange.
  ///
  /// In en, this message translates to:
  /// **'{percent} expenses'**
  String smartMoneyScoreMetricExpensesChange(String percent);

  /// No description provided for @smartMoneyScoreFormulaFootnote.
  ///
  /// In en, this message translates to:
  /// **'Monthly score = clamp(0–150, 100 + balance change % + financial behaviour modifier).'**
  String get smartMoneyScoreFormulaFootnote;

  /// No description provided for @financialInsightMsgSteadySpendingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your spending is looking steady today.'**
  String get financialInsightMsgSteadySpendingHeadline;

  /// No description provided for @financialInsightMsgSteadySpendingExplanation.
  ///
  /// In en, this message translates to:
  /// **'Keep logging transactions and Cashly will make each insight more personal.'**
  String get financialInsightMsgSteadySpendingExplanation;

  /// No description provided for @financialInsightMsgNegativeBalanceHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your total balance is below zero.'**
  String get financialInsightMsgNegativeBalanceHeadline;

  /// No description provided for @financialInsightMsgNegativeBalanceExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your total {currency} balance is {amount}. Bringing that shortfall above zero is the clearest next step.'**
  String financialInsightMsgNegativeBalanceExplanation(
    String currency,
    String amount,
  );

  /// No description provided for @financialInsightMsgPlanEssentialExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan the next essential expense first'**
  String get financialInsightMsgPlanEssentialExpenseTitle;

  /// No description provided for @financialInsightMsgPlanEssentialExpenseDetail.
  ///
  /// In en, this message translates to:
  /// **'Focusing on one necessary expense at a time can help rebuild a positive buffer without judging past choices.'**
  String get financialInsightMsgPlanEssentialExpenseDetail;

  /// No description provided for @financialInsightMsgCategoryOverBudgetHeadline.
  ///
  /// In en, this message translates to:
  /// **'{category} is over its monthly budget.'**
  String financialInsightMsgCategoryOverBudgetHeadline(String category);

  /// No description provided for @financialInsightMsgCategoryOverBudgetExplanation.
  ///
  /// In en, this message translates to:
  /// **'You have spent {spent} against a {limit} plan.'**
  String financialInsightMsgCategoryOverBudgetExplanation(
    String spent,
    String limit,
  );

  /// No description provided for @financialInsightMsgPauseCategorySpendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause {category} spending for today'**
  String financialInsightMsgPauseCategorySpendingTitle(String category);

  /// No description provided for @financialInsightMsgPauseCategorySpendingDetail.
  ///
  /// In en, this message translates to:
  /// **'A short pause protects the rest of this month\'s plan without judging past choices.'**
  String get financialInsightMsgPauseCategorySpendingDetail;

  /// No description provided for @financialInsightMsgCategoryNeedsRoomHeadline.
  ///
  /// In en, this message translates to:
  /// **'{category} needs a little room this month.'**
  String financialInsightMsgCategoryNeedsRoomHeadline(String category);

  /// No description provided for @financialInsightMsgCategoryNeedsRoomExplanation.
  ///
  /// In en, this message translates to:
  /// **'You have used {percent} of its {limit} budget.'**
  String financialInsightMsgCategoryNeedsRoomExplanation(
    String percent,
    String limit,
  );

  /// No description provided for @financialInsightMsgSetRestOfMonthLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a rest-of-month limit for {category}'**
  String financialInsightMsgSetRestOfMonthLimitTitle(String category);

  /// No description provided for @financialInsightMsgSetRestOfMonthLimitDetail.
  ///
  /// In en, this message translates to:
  /// **'Keeping the next purchases within {remaining} will keep this budget on track.'**
  String financialInsightMsgSetRestOfMonthLimitDetail(String remaining);

  /// No description provided for @financialInsightMsgCategoryHigherThanUsualHeadline.
  ///
  /// In en, this message translates to:
  /// **'{category} is higher than your usual pace.'**
  String financialInsightMsgCategoryHigherThanUsualHeadline(String category);

  /// No description provided for @financialInsightMsgCategoryHigherThanUsualExplanation.
  ///
  /// In en, this message translates to:
  /// **'It is {changePercent} above the comparable period, so it is worth a quick check-in.'**
  String financialInsightMsgCategoryHigherThanUsualExplanation(
    String changePercent,
  );

  /// No description provided for @financialInsightMsgReviewNextCategoryPurchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your next {category} purchase'**
  String financialInsightMsgReviewNextCategoryPurchaseTitle(String category);

  /// No description provided for @financialInsightMsgReviewNextCategoryPurchaseDetail.
  ///
  /// In en, this message translates to:
  /// **'A small swap or delay can soften this increase while you decide whether it was a one-off.'**
  String get financialInsightMsgReviewNextCategoryPurchaseDetail;

  /// No description provided for @financialInsightMsgTodaySpendingFasterHeadline.
  ///
  /// In en, this message translates to:
  /// **'Today is spending faster than this week\'s pace.'**
  String get financialInsightMsgTodaySpendingFasterHeadline;

  /// No description provided for @financialInsightMsgTodaySpendingFasterExplanation.
  ///
  /// In en, this message translates to:
  /// **'That can happen — one intentional check before another purchase keeps the day in your control.'**
  String get financialInsightMsgTodaySpendingFasterExplanation;

  /// No description provided for @financialInsightMsgCheckNextExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the next expense before you buy'**
  String get financialInsightMsgCheckNextExpenseTitle;

  /// No description provided for @financialInsightMsgCheckNextExpenseDetail.
  ///
  /// In en, this message translates to:
  /// **'A quick pause can keep today closer to your usual pace without changing what has already happened.'**
  String get financialInsightMsgCheckNextExpenseDetail;

  /// No description provided for @financialInsightMsgSpendingAheadOfIncomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'This month\'s spending is ahead of income so far.'**
  String get financialInsightMsgSpendingAheadOfIncomeHeadline;

  /// No description provided for @financialInsightMsgSpendingAheadOfIncomeExplanation.
  ///
  /// In en, this message translates to:
  /// **'This is a trend to watch, not a verdict — one or two intentional choices can still change the month.'**
  String get financialInsightMsgSpendingAheadOfIncomeExplanation;

  /// No description provided for @financialInsightMsgChooseLowPriorityExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one low-priority expense to delay'**
  String get financialInsightMsgChooseLowPriorityExpenseTitle;

  /// No description provided for @financialInsightMsgChooseLowPriorityExpenseDetail.
  ///
  /// In en, this message translates to:
  /// **'Focus on the next choice only; reducing one flexible cost can bring the month closer to balance.'**
  String get financialInsightMsgChooseLowPriorityExpenseDetail;

  /// No description provided for @financialInsightMsgBalanceZeroHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your available balance is at zero.'**
  String get financialInsightMsgBalanceZeroHeadline;

  /// No description provided for @financialInsightMsgBalanceThinHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your balance buffer is getting tight.'**
  String get financialInsightMsgBalanceThinHeadline;

  /// No description provided for @financialInsightMsgBalanceLimitedHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your balance could use a little more room.'**
  String get financialInsightMsgBalanceLimitedHeadline;

  /// No description provided for @financialInsightMsgBalanceSteadyHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your balance is looking steady.'**
  String get financialInsightMsgBalanceSteadyHeadline;

  /// No description provided for @financialInsightMsgBalanceZeroExplanation.
  ///
  /// In en, this message translates to:
  /// **'There is no {currency} buffer left after recent activity. Choosing the next expense carefully can help create room again.'**
  String financialInsightMsgBalanceZeroExplanation(String currency);

  /// No description provided for @financialInsightMsgBalanceThinExplanation.
  ///
  /// In en, this message translates to:
  /// **'At your recent spending pace, this {currency} balance covers about {days} days. Protecting one essential expense first can help.'**
  String financialInsightMsgBalanceThinExplanation(String currency, int days);

  /// No description provided for @financialInsightMsgBalanceLimitedExplanation.
  ///
  /// In en, this message translates to:
  /// **'At your recent spending pace, this {currency} balance covers about {days} days. A small rest-of-week plan can preserve that room.'**
  String financialInsightMsgBalanceLimitedExplanation(
    String currency,
    int days,
  );

  /// No description provided for @financialInsightMsgBalanceSteadyExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your balance is supporting your current pace.'**
  String get financialInsightMsgBalanceSteadyExplanation;

  /// No description provided for @financialInsightMsgProtectEssentialExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect the next essential expense'**
  String get financialInsightMsgProtectEssentialExpenseTitle;

  /// No description provided for @financialInsightMsgProtectEssentialExpenseDetail.
  ///
  /// In en, this message translates to:
  /// **'Choosing the next necessary cost first can help create space before adding anything optional.'**
  String get financialInsightMsgProtectEssentialExpenseDetail;

  /// No description provided for @financialInsightMsgReserveNextDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Reserve the next {days} days of essentials'**
  String financialInsightMsgReserveNextDaysTitle(int days);

  /// No description provided for @financialInsightMsgReserveNextDaysDetail.
  ///
  /// In en, this message translates to:
  /// **'Keeping that small buffer for needs first gives your balance more room to recover.'**
  String get financialInsightMsgReserveNextDaysDetail;

  /// No description provided for @financialInsightMsgSetShortRestOfWeekLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a short rest-of-week limit'**
  String get financialInsightMsgSetShortRestOfWeekLimitTitle;

  /// No description provided for @financialInsightMsgSetShortRestOfWeekLimitDetail.
  ///
  /// In en, this message translates to:
  /// **'A small limit for flexible spending can keep your current balance working for longer.'**
  String get financialInsightMsgSetShortRestOfWeekLimitDetail;

  /// No description provided for @financialInsightMsgKeepExpenseIntentionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your next expense intentional'**
  String get financialInsightMsgKeepExpenseIntentionalTitle;

  /// No description provided for @financialInsightMsgKeepExpenseIntentionalBalanceDetail.
  ///
  /// In en, this message translates to:
  /// **'Your balance is supporting the current pace. A quick check before spending helps it stay that way.'**
  String get financialInsightMsgKeepExpenseIntentionalBalanceDetail;

  /// No description provided for @financialInsightMsgKeepExpenseIntentionalPaceDetail.
  ///
  /// In en, this message translates to:
  /// **'Your current pace is healthy. A quick check before a purchase helps it stay that way.'**
  String get financialInsightMsgKeepExpenseIntentionalPaceDetail;

  /// No description provided for @financialInsightMsgOnboardingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Let\'s build your first spending pattern.'**
  String get financialInsightMsgOnboardingHeadline;

  /// No description provided for @financialInsightMsgOnboardingExplanation.
  ///
  /// In en, this message translates to:
  /// **'Add a few income or expense entries and Cashly will turn them into personal daily, weekly, and monthly check-ins.'**
  String get financialInsightMsgOnboardingExplanation;

  /// No description provided for @financialInsightMsgLogNextExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Log your next expense'**
  String get financialInsightMsgLogNextExpenseTitle;

  /// No description provided for @financialInsightMsgLogNextExpenseDetail.
  ///
  /// In en, this message translates to:
  /// **'Even a small everyday purchase gives the assistant a better starting point.'**
  String get financialInsightMsgLogNextExpenseDetail;

  /// No description provided for @financialInsightMsgNotEnoughActivityTodayReason.
  ///
  /// In en, this message translates to:
  /// **'There is not enough recent activity to score today\'s trend yet.'**
  String get financialInsightMsgNotEnoughActivityTodayReason;

  /// No description provided for @financialInsightMsgNotEnoughActivityWeekReason.
  ///
  /// In en, this message translates to:
  /// **'There is not enough recent activity to score this week\'s trend yet.'**
  String get financialInsightMsgNotEnoughActivityWeekReason;

  /// No description provided for @financialInsightMsgNotEnoughActivityMonthReason.
  ///
  /// In en, this message translates to:
  /// **'There is not enough recent activity to score this month\'s trend yet.'**
  String get financialInsightMsgNotEnoughActivityMonthReason;

  /// No description provided for @financialInsightMsgBalanceImpactNegativeReason.
  ///
  /// In en, this message translates to:
  /// **'Your total {currency} balance is below zero, so rebuilding a positive buffer is the priority.'**
  String financialInsightMsgBalanceImpactNegativeReason(String currency);

  /// No description provided for @financialInsightMsgBalanceImpactEmptyReason.
  ///
  /// In en, this message translates to:
  /// **'Your active {currency} balance is at zero after recent activity.'**
  String financialInsightMsgBalanceImpactEmptyReason(String currency);

  /// No description provided for @financialInsightMsgBalanceImpactLowReason.
  ///
  /// In en, this message translates to:
  /// **'Your total {currency} balance covers about {days} days at your recent spending pace.'**
  String financialInsightMsgBalanceImpactLowReason(String currency, int days);

  /// No description provided for @financialInsightMsgBalanceImpactHealthyReason.
  ///
  /// In en, this message translates to:
  /// **'Your total {currency} balance covers more than a month at your recent spending pace.'**
  String financialInsightMsgBalanceImpactHealthyReason(String currency);

  /// No description provided for @financialInsightMsgCategoryOverBudgetReasonToday.
  ///
  /// In en, this message translates to:
  /// **'{category} is already over its monthly budget.'**
  String financialInsightMsgCategoryOverBudgetReasonToday(String category);

  /// No description provided for @financialInsightMsgCategoryNearBudgetReasonToday.
  ///
  /// In en, this message translates to:
  /// **'{category} has little budget room left this month.'**
  String financialInsightMsgCategoryNearBudgetReasonToday(String category);

  /// No description provided for @financialInsightMsgTodaySpikeReason.
  ///
  /// In en, this message translates to:
  /// **'Today\'s spending is more than twice your earlier daily pace this week.'**
  String get financialInsightMsgTodaySpikeReason;

  /// No description provided for @financialInsightMsgTodayComparableIncreaseReason.
  ///
  /// In en, this message translates to:
  /// **'Today\'s spending is {changePercent} above yesterday\'s comparable total.'**
  String financialInsightMsgTodayComparableIncreaseReason(String changePercent);

  /// No description provided for @financialInsightMsgNoActivityTodayReason.
  ///
  /// In en, this message translates to:
  /// **'No income or expense has been recorded today.'**
  String get financialInsightMsgNoActivityTodayReason;

  /// No description provided for @financialInsightMsgIncomeCoversTodayReason.
  ///
  /// In en, this message translates to:
  /// **'Today\'s recorded income covers today\'s spending.'**
  String get financialInsightMsgIncomeCoversTodayReason;

  /// No description provided for @financialInsightMsgCategoryOverBudgetReasonWeek.
  ///
  /// In en, this message translates to:
  /// **'{category} is over budget, so this week needs a gentler pace.'**
  String financialInsightMsgCategoryOverBudgetReasonWeek(String category);

  /// No description provided for @financialInsightMsgCategoryNearBudgetReasonWeek.
  ///
  /// In en, this message translates to:
  /// **'{category} is close to its monthly limit.'**
  String financialInsightMsgCategoryNearBudgetReasonWeek(String category);

  /// No description provided for @financialInsightMsgCategoryPacedBudgetReasonWeek.
  ///
  /// In en, this message translates to:
  /// **'{category} is ahead of its expected monthly pace.'**
  String financialInsightMsgCategoryPacedBudgetReasonWeek(String category);

  /// No description provided for @financialInsightMsgWeeklyCategorySpikeReason.
  ///
  /// In en, this message translates to:
  /// **'{category} is {changePercent} above the comparable week.'**
  String financialInsightMsgWeeklyCategorySpikeReason(
    String category,
    String changePercent,
  );

  /// No description provided for @financialInsightMsgWeekComparableIncreaseReason.
  ///
  /// In en, this message translates to:
  /// **'This week\'s spending is {changePercent} above last week\'s comparable total.'**
  String financialInsightMsgWeekComparableIncreaseReason(String changePercent);

  /// No description provided for @financialInsightMsgWeekComparableDecreaseReason.
  ///
  /// In en, this message translates to:
  /// **'This week is spending less than the comparable previous week.'**
  String get financialInsightMsgWeekComparableDecreaseReason;

  /// No description provided for @financialInsightMsgCategoryOverBudgetReasonMonth.
  ///
  /// In en, this message translates to:
  /// **'{category} is {percent} over budget.'**
  String financialInsightMsgCategoryOverBudgetReasonMonth(
    String category,
    String percent,
  );

  /// No description provided for @financialInsightMsgCategoryNearBudgetReasonMonth.
  ///
  /// In en, this message translates to:
  /// **'{category} has {remaining} remaining.'**
  String financialInsightMsgCategoryNearBudgetReasonMonth(
    String category,
    String remaining,
  );

  /// No description provided for @financialInsightMsgCategoryPacedBudgetReasonMonth.
  ///
  /// In en, this message translates to:
  /// **'{category} is spending faster than its monthly plan.'**
  String financialInsightMsgCategoryPacedBudgetReasonMonth(String category);

  /// No description provided for @financialInsightMsgSpendingOverIncomeReasonMonth.
  ///
  /// In en, this message translates to:
  /// **'Month-to-date spending is {expense} versus {income} income.'**
  String financialInsightMsgSpendingOverIncomeReasonMonth(
    String expense,
    String income,
  );

  /// No description provided for @financialInsightMsgIncomeCoversMonthReason.
  ///
  /// In en, this message translates to:
  /// **'Income currently covers this month\'s recorded spending.'**
  String get financialInsightMsgIncomeCoversMonthReason;

  /// No description provided for @financialInsightMsgMonthComparableIncreaseReason.
  ///
  /// In en, this message translates to:
  /// **'Month-to-date spending is {changePercent} above the comparable previous month.'**
  String financialInsightMsgMonthComparableIncreaseReason(String changePercent);

  /// No description provided for @financialInsightMsgMonthComparableDecreaseReason.
  ///
  /// In en, this message translates to:
  /// **'Month-to-date spending is lower than the comparable previous period.'**
  String get financialInsightMsgMonthComparableDecreaseReason;

  /// No description provided for @financialInsightMsgSteadyReasonToday.
  ///
  /// In en, this message translates to:
  /// **'Today is within a healthy spending pace.'**
  String get financialInsightMsgSteadyReasonToday;

  /// No description provided for @financialInsightMsgSteadyReasonWeek.
  ///
  /// In en, this message translates to:
  /// **'This week is tracking close to your recent pace.'**
  String get financialInsightMsgSteadyReasonWeek;

  /// No description provided for @financialInsightMsgSteadyReasonMonth.
  ///
  /// In en, this message translates to:
  /// **'This month is within the plan recorded in Cashly.'**
  String get financialInsightMsgSteadyReasonMonth;

  /// No description provided for @financialInsightMsgShortHorizonNoActiveAccountToday.
  ///
  /// In en, this message translates to:
  /// **'Today has no active account balance to compare yet, so Cashly is using current balance, budget, and spending signals.'**
  String get financialInsightMsgShortHorizonNoActiveAccountToday;

  /// No description provided for @financialInsightMsgShortHorizonNoActiveAccountWeek.
  ///
  /// In en, this message translates to:
  /// **'This week has no active account balance to compare yet, so Cashly is using current balance, budget, and spending signals.'**
  String get financialInsightMsgShortHorizonNoActiveAccountWeek;

  /// No description provided for @financialInsightMsgShortHorizonCrossCurrencyToday.
  ///
  /// In en, this message translates to:
  /// **'A transfer between currencies occurred today. Cashly is keeping its balance comparison neutral until an exchange-rate basis is available.'**
  String get financialInsightMsgShortHorizonCrossCurrencyToday;

  /// No description provided for @financialInsightMsgShortHorizonCrossCurrencyWeek.
  ///
  /// In en, this message translates to:
  /// **'A transfer between currencies occurred this week. Cashly is keeping its balance comparison neutral until an exchange-rate basis is available.'**
  String get financialInsightMsgShortHorizonCrossCurrencyWeek;

  /// No description provided for @financialInsightMsgShortHorizonAccountAddedToday.
  ///
  /// In en, this message translates to:
  /// **'An account was added today, so Cashly cannot safely reconstruct that opening balance yet.'**
  String get financialInsightMsgShortHorizonAccountAddedToday;

  /// No description provided for @financialInsightMsgShortHorizonAccountAddedWeek.
  ///
  /// In en, this message translates to:
  /// **'An account was added this week, so Cashly cannot safely reconstruct that opening balance yet.'**
  String get financialInsightMsgShortHorizonAccountAddedWeek;

  /// No description provided for @financialInsightMsgShortHorizonUnverifiableToday.
  ///
  /// In en, this message translates to:
  /// **'Cashly could not verify the balance values for today, so its balance comparison is neutral.'**
  String get financialInsightMsgShortHorizonUnverifiableToday;

  /// No description provided for @financialInsightMsgShortHorizonUnverifiableWeek.
  ///
  /// In en, this message translates to:
  /// **'Cashly could not verify the balance values for this week, so its balance comparison is neutral.'**
  String get financialInsightMsgShortHorizonUnverifiableWeek;

  /// No description provided for @financialInsightMsgShortHorizonZeroOpeningToday.
  ///
  /// In en, this message translates to:
  /// **'Today began at zero with no recorded income or expense, so Cashly is using current balance, budget, and spending signals.'**
  String get financialInsightMsgShortHorizonZeroOpeningToday;

  /// No description provided for @financialInsightMsgShortHorizonZeroOpeningWeek.
  ///
  /// In en, this message translates to:
  /// **'This week began at zero with no recorded income or expense, so Cashly is using current balance, budget, and spending signals.'**
  String get financialInsightMsgShortHorizonZeroOpeningWeek;

  /// No description provided for @financialInsightMsgShortHorizonIncreasedToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s balance increased by {percent}, contributing {points} to the score alongside budget and spending signals.'**
  String financialInsightMsgShortHorizonIncreasedToday(
    String percent,
    String points,
  );

  /// No description provided for @financialInsightMsgShortHorizonIncreasedWeek.
  ///
  /// In en, this message translates to:
  /// **'This week\'s balance increased by {percent}, contributing {points} to the score alongside budget and spending signals.'**
  String financialInsightMsgShortHorizonIncreasedWeek(
    String percent,
    String points,
  );

  /// No description provided for @financialInsightMsgShortHorizonDecreasedToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s balance decreased by {percent}, contributing {points} to the score alongside budget and spending signals.'**
  String financialInsightMsgShortHorizonDecreasedToday(
    String percent,
    String points,
  );

  /// No description provided for @financialInsightMsgShortHorizonDecreasedWeek.
  ///
  /// In en, this message translates to:
  /// **'This week\'s balance decreased by {percent}, contributing {points} to the score alongside budget and spending signals.'**
  String financialInsightMsgShortHorizonDecreasedWeek(
    String percent,
    String points,
  );

  /// No description provided for @financialInsightMsgShortHorizonStayedLevelToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s balance stayed level, contributing {points} to the score alongside budget and spending signals.'**
  String financialInsightMsgShortHorizonStayedLevelToday(String points);

  /// No description provided for @financialInsightMsgShortHorizonStayedLevelWeek.
  ///
  /// In en, this message translates to:
  /// **'This week\'s balance stayed level, contributing {points} to the score alongside budget and spending signals.'**
  String financialInsightMsgShortHorizonStayedLevelWeek(String points);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'lo'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'lo':
      return AppLocalizationsLo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
