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
  /// **'Get notified when a budget goes over its limit, an account balance goes negative, or a savings goal contribution is due. Only while the app is open.'**
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
