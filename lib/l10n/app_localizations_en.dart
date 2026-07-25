// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Cashly';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get splashTimeoutMessage =>
      'This is taking longer than expected. Check your device\'s network connection and try again.';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to keep track of your money.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordRequiredError => 'Password is required.';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get signIn => 'Sign in';

  @override
  String get loginFailedMessage => 'Could not sign in. Please try again.';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get signUpLink => 'Sign up';

  @override
  String get orDividerLabel => 'Or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get googleSignInFailedMessage =>
      'Could not sign in with Google. Please try again.';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle =>
      'Start budgeting smarter in a couple of minutes.';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get registerFailedMessage =>
      'Could not create your account. Please try again.';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we\'ll send you a reset link.';

  @override
  String get sendResetLinkButton => 'Send reset link';

  @override
  String get resetEmailFailedMessage =>
      'Could not send the reset email. Please try again.';

  @override
  String get checkEmailTitle => 'Check your email';

  @override
  String checkEmailSubtitle(String email) {
    return 'We\'ve sent a password reset link to $email.';
  }

  @override
  String get backToSignInButton => 'Back to sign in';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String verifyEmailSubtitle(String email) {
    return 'We\'ve sent a verification link to $email. Click it, then continue below.';
  }

  @override
  String get verifiedButton => 'I\'ve verified my email';

  @override
  String get resendEmailButton => 'Resend email';

  @override
  String resendEmailCountdownButton(int seconds) {
    return 'Resend email (${seconds}s)';
  }

  @override
  String get verificationEmailSentMessage => 'Verification email sent.';

  @override
  String get resendFailedMessage =>
      'Could not resend the email. Please try again.';

  @override
  String get notVerifiedYetMessage => 'We couldn\'t confirm verification yet.';

  @override
  String get signOutButton => 'Sign out';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get offlineBannerMessage =>
      'Offline — changes will sync when you\'re back online';

  @override
  String get reportsTooltip => 'Reports';

  @override
  String get previousMonthTooltip => 'Previous month';

  @override
  String get nextMonthTooltip => 'Next month';

  @override
  String get showPasswordTooltip => 'Show password';

  @override
  String get hidePasswordTooltip => 'Hide password';

  @override
  String get editDisplayNameTooltip => 'Edit name';

  @override
  String get deleteTransactionTitle => 'Delete transaction?';

  @override
  String get deleteTransactionMessage =>
      'This permanently deletes the transaction and reverses its effect on the account\'s balance. This cannot be undone.';

  @override
  String get deleteTransactionFailedMessage =>
      'Could not delete the transaction.';

  @override
  String get welcomeToCashly => 'Welcome to Cashly';

  @override
  String get addFirstAccountMessage =>
      'Add your first account to start seeing your finances summarized here.';

  @override
  String get addAccountButton => 'Add account';

  @override
  String get recentTransactionsTitle => 'Recent Transactions';

  @override
  String get noTransactionsThisMonth => 'No transactions yet this month.';

  @override
  String get spendingByCategoryTitle => 'Spending by Category';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get accountBalancesTitle => 'Account Balances';

  @override
  String get seeAll => 'See all';

  @override
  String totalBalanceLabel(String currencyCode) {
    return 'Total Balance ($currencyCode)';
  }

  @override
  String get incomeMonthLabel => 'Income (month)';

  @override
  String get expenseMonthLabel => 'Expense (month)';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageLao => 'ລາວ';

  @override
  String get languageUpdateFailedMessage => 'Could not update your language.';

  @override
  String get emailRequiredError => 'Email is required.';

  @override
  String get emailInvalidError => 'Enter a valid email address.';

  @override
  String get passwordTooShortError => 'Password must be at least 8 characters.';

  @override
  String get passwordNeedsUppercaseError =>
      'Include at least one uppercase letter.';

  @override
  String get passwordNeedsNumberError => 'Include at least one number.';

  @override
  String get confirmPasswordRequiredError => 'Confirm your password.';

  @override
  String get passwordsDoNotMatchError => 'Passwords do not match.';

  @override
  String get nameRequiredError => 'Name is required.';

  @override
  String get nameTooShortError => 'Name must be at least 2 characters.';

  @override
  String fieldRequiredError(String label) {
    return '$label is required.';
  }

  @override
  String get amountRequiredError => 'Amount is required.';

  @override
  String get amountInvalidError => 'Enter a valid number.';

  @override
  String get amountMustBePositiveError => 'Amount must be greater than zero.';

  @override
  String get incomeLabel => 'Income';

  @override
  String get expenseLabel => 'Expense';

  @override
  String get transferLabel => 'Transfer';

  @override
  String get archivedBadgeLabel => 'Archived';

  @override
  String get defaultBadgeLabel => 'Default';

  @override
  String get archiveMenuItem => 'Archive';

  @override
  String get unarchiveMenuItem => 'Unarchive';

  @override
  String get hideArchivedTooltip => 'Hide archived';

  @override
  String get showArchivedTooltip => 'Show archived';

  @override
  String get saveChangesButton => 'Save changes';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get noAccountsYetTitle => 'No accounts yet';

  @override
  String get noAccountsYetMessage =>
      'Add a cash, wallet, bank, credit card, or savings account to start tracking your money.';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String deleteAccountMessage(String name) {
    return 'This permanently deletes \"$name\". This cannot be undone.';
  }

  @override
  String get deleteAccountFailedMessage => 'Could not delete the account.';

  @override
  String get updateAccountFailedMessage => 'Could not update the account.';

  @override
  String get accountFormEditTitle => 'Edit account';

  @override
  String get accountNameLabel => 'Account name';

  @override
  String get accountTypeLabel => 'Account type';

  @override
  String get currentBalanceLabel => 'Current balance';

  @override
  String get initialBalanceLabel => 'Initial balance';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get saveAccountFailedMessage =>
      'Could not save the account. Please try again.';

  @override
  String get accountTypeCashLabel => 'Cash';

  @override
  String get accountTypeWalletLabel => 'Wallet';

  @override
  String get accountTypeBankLabel => 'Bank';

  @override
  String get accountTypeCreditCardLabel => 'Credit Card';

  @override
  String get accountTypeSavingsLabel => 'Savings';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get noExpenseCategoriesYetTitle => 'No expense categories yet';

  @override
  String get noIncomeCategoriesYetTitle => 'No income categories yet';

  @override
  String get addCategoryToStartMessage =>
      'Add one to start tagging your transactions.';

  @override
  String get addCategoryButton => 'Add category';

  @override
  String get deleteCategoryTitle => 'Delete category?';

  @override
  String deleteCategoryMessage(String name) {
    return 'This permanently deletes \"$name\". This cannot be undone.';
  }

  @override
  String get deleteCategoryFailedMessage => 'Could not delete the category.';

  @override
  String get updateCategoryFailedMessage => 'Could not update the category.';

  @override
  String get reorderCategoriesFailedMessage => 'Could not save the new order.';

  @override
  String get categoryFormEditTitle => 'Edit category';

  @override
  String get categoryNameLabel => 'Category name';

  @override
  String get categoryTypeLabel => 'Type';

  @override
  String get saveCategoryFailedMessage =>
      'Could not save the category. Please try again.';

  @override
  String get budgetTitle => 'Budget';

  @override
  String get deleteBudgetTitle => 'Delete budget?';

  @override
  String deleteBudgetMessage(String name) {
    return 'This removes the budget for \"$name\" this month. This cannot be undone.';
  }

  @override
  String get deleteBudgetFailedMessage => 'Could not delete the budget.';

  @override
  String get addExpenseCategoryFirstMessage =>
      'Add an expense category first, then set a budget for it.';

  @override
  String get noBudgetSetLabel => 'No budget set';

  @override
  String get setBudgetButton => 'Set budget';

  @override
  String get budgetFormEditTitle => 'Edit budget';

  @override
  String get categoryAndMonthLockedMessage =>
      'Category and month can\'t be changed here — delete and re-create the budget instead.';

  @override
  String get monthlyLimitLabel => 'Monthly limit';

  @override
  String get budgetCurrencyRestrictionMessage =>
      'Only transactions in this currency count toward this budget.';

  @override
  String get deleteBudgetTooltip => 'Delete budget';

  @override
  String overspentByMessage(String amount) {
    return 'Over by $amount';
  }

  @override
  String remainingAmountMessage(String amount) {
    return '$amount remaining';
  }

  @override
  String get saveBudgetFailedMessage =>
      'Could not save the budget. Please try again.';

  @override
  String get savingsGoalsTitle => 'Savings Goals';

  @override
  String get savingsGoalsTooltip => 'Savings goals';

  @override
  String get noSavingsGoalsYetTitle => 'No savings goals yet';

  @override
  String get noSavingsGoalsYetMessage =>
      'Set a target and link an account to start tracking progress toward it.';

  @override
  String get addGoalButton => 'Add goal';

  @override
  String get goalFormEditTitle => 'Edit goal';

  @override
  String get goalNameLabel => 'Goal name';

  @override
  String get targetAmountLabel => 'Target amount';

  @override
  String get linkedAccountLabel => 'Linked account';

  @override
  String get linkedAccountLockedMessage =>
      'Linked account can\'t be changed here — delete and re-create the goal instead.';

  @override
  String get createNewAccountOption => '+ Add a new account';

  @override
  String get accountAlreadyBacksGoalError =>
      'This account already backs another active savings goal.';

  @override
  String get noEligibleAccountsMessage =>
      'All your accounts already back another active goal — add a new one to continue.';

  @override
  String get autoContributionSectionTitle => 'Auto contribution';

  @override
  String get autoContributionToggleLabel => 'Remind me to contribute';

  @override
  String get autoContributionAmountLabel => 'Contribution amount';

  @override
  String get autoContributionFrequencyLabel => 'Frequency';

  @override
  String get goalFrequencyWeeklyLabel => 'Weekly';

  @override
  String get goalFrequencyBiweeklyLabel => 'Every 2 weeks';

  @override
  String get goalFrequencyMonthlyLabel => 'Monthly';

  @override
  String get saveGoalFailedMessage =>
      'Could not save the goal. Please try again.';

  @override
  String get deleteGoalTitle => 'Delete goal?';

  @override
  String get deleteGoalMessage =>
      'This deletes the goal. It doesn\'t affect the linked account or its balance. This cannot be undone.';

  @override
  String get deleteGoalFailedMessage => 'Could not delete the goal.';

  @override
  String get contributeButton => 'Contribute';

  @override
  String get contributionSourceAccountLabel => 'From account';

  @override
  String get contributionAmountLabel => 'Amount';

  @override
  String get confirmContributionButton => 'Confirm contribution';

  @override
  String get contributionFailedMessage =>
      'Could not save the contribution. Please try again.';

  @override
  String contributionDueBannerMessage(String amount) {
    return 'Your $amount contribution is due.';
  }

  @override
  String get goalCompletedBadgeLabel => 'Completed';

  @override
  String get goalDueBadgeLabel => 'Due';

  @override
  String estimatedCompletionScheduledMessage(String date) {
    return 'On track to finish by $date';
  }

  @override
  String estimatedCompletionTrailingAverageMessage(String date) {
    return 'Estimated to finish around $date at your recent pace';
  }

  @override
  String get estimatedCompletionInsufficientDataMessage =>
      'Add a few contributions to see an estimated finish date.';

  @override
  String get estimatedCompletionCompletedMessage =>
      'You\'ve reached your goal.';

  @override
  String get accountActivityTitle => 'Account activity';

  @override
  String get noAccountActivityYetMessage =>
      'Contributions and other transactions on the linked account will show up here.';

  @override
  String get goalCelebrationTitle => 'Goal reached!';

  @override
  String goalCelebrationMessage(String goalName) {
    return 'You\'ve hit your \"$goalName\" goal.';
  }

  @override
  String get goalNotFoundMessage => 'This goal no longer exists.';

  @override
  String get linkedAccountArchivedMessage =>
      'This goal\'s linked account is archived.';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get transactionsTabLabel => 'Transactions';

  @override
  String noTransactionsInMonthTitle(String month) {
    return 'No transactions in $month';
  }

  @override
  String get addFirstTransactionMessage =>
      'Add your first income or expense for this month.';

  @override
  String get addTransactionButton => 'Add transaction';

  @override
  String get searchTransactionsHint => 'Search transactions';

  @override
  String get searchTooltip => 'Search';

  @override
  String get closeSearchTooltip => 'Close search';

  @override
  String get filterSortTooltip => 'Filter & sort';

  @override
  String get filterSortSheetTitle => 'Filter & sort';

  @override
  String get typeFilterLabel => 'Type';

  @override
  String get allTypesLabel => 'All types';

  @override
  String get accountFilterLabel => 'Account';

  @override
  String get allAccountsLabel => 'All accounts';

  @override
  String get categoryFilterLabel => 'Category';

  @override
  String get allCategoriesLabel => 'All categories';

  @override
  String get sortByLabel => 'Sort by';

  @override
  String get sortDateNewestLabel => 'Newest first';

  @override
  String get sortDateOldestLabel => 'Oldest first';

  @override
  String get sortAmountHighLabel => 'Amount: high to low';

  @override
  String get sortAmountLowLabel => 'Amount: low to high';

  @override
  String get clearFiltersButton => 'Clear filters';

  @override
  String get noMatchingTransactionsTitle => 'No matching transactions';

  @override
  String get noMatchingTransactionsMessage =>
      'Try adjusting your search or filters.';

  @override
  String transferToLabel(String account) {
    return 'Transfer to $account';
  }

  @override
  String transferFromLabel(String account) {
    return 'From $account';
  }

  @override
  String get unknownAccountLabel => 'Unknown account';

  @override
  String get uncategorizedLabel => 'Uncategorized';

  @override
  String get transactionFormEditTitle => 'Edit transaction';

  @override
  String get amountLabel => 'Amount';

  @override
  String get fromAccountLabel => 'From account';

  @override
  String get accountFieldLabel => 'Account';

  @override
  String get unavailableAccountLabel => 'Unavailable account — choose another';

  @override
  String get pleaseSelectAccountError => 'Please select an account.';

  @override
  String get toAccountLabel => 'To account';

  @override
  String get pickFromAccountFirstMessage => 'Pick a from account first';

  @override
  String get transferSameCurrencyHelperText =>
      'Must be the same currency as the from account';

  @override
  String get pleaseSelectDestinationAccountError =>
      'Please select a destination account.';

  @override
  String get cantTransferToSameAccountError =>
      'Can\'t transfer to the same account.';

  @override
  String get transferSameCurrencyError =>
      'Must be the same currency as the from account.';

  @override
  String get categoryFieldLabel => 'Category';

  @override
  String get unavailableCategoryLabel =>
      'Unavailable category — choose another';

  @override
  String get pleaseSelectCategoryError => 'Please select a category.';

  @override
  String get dateLabel => 'Date';

  @override
  String get noteOptionalLabel => 'Note (optional)';

  @override
  String get saveTransactionFailedMessage =>
      'Could not save the transaction. Please try again.';

  @override
  String archivedSuffixFormat(String name) {
    return '$name (Archived)';
  }

  @override
  String get reportsTitle => 'Reports';

  @override
  String get exportReportTooltip => 'Export as CSV';

  @override
  String exportReportSubject(String month) {
    return 'Cashly report — $month';
  }

  @override
  String get exportReportFailedMessage =>
      'Could not export the report. Please try again.';

  @override
  String get convertedTotalsCardTitle => 'Converted total';

  @override
  String convertedTotalsCaption(String currency) {
    return 'Approximate total across all your currencies, shown in $currency.';
  }

  @override
  String convertedTotalsRatesAsOf(String date) {
    return 'Rates as of $date · Rates by ExchangeRate-API';
  }

  @override
  String get nothingToReportYetTitle => 'Nothing to report yet';

  @override
  String get nothingToReportYetMessage =>
      'Once you record income or expenses for this month, you\'ll see monthly summaries, spending breakdowns, and trends here.';

  @override
  String get incomeExpenseTrendSectionTitle => 'Income vs Expense Trend';

  @override
  String get spendingByCategorySectionTitle => 'Spending by Category';

  @override
  String get budgetVsActualSectionTitle => 'Budget vs Actual';

  @override
  String get seeAllButton => 'See all';

  @override
  String get netLabel => 'Net';

  @override
  String get totalLabel => 'Total';

  @override
  String monthIncomeExpenseSummaryMessage(
    String month,
    String income,
    String expense,
  ) {
    return '$month — Income $income, Expense $expense';
  }

  @override
  String get save => 'Save';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSectionTitle => 'Appearance';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystemLabel => 'System';

  @override
  String get themeLightLabel => 'Light';

  @override
  String get themeDarkLabel => 'Dark';

  @override
  String get themeUpdateFailedMessage => 'Could not update your theme.';

  @override
  String get securitySectionTitle => 'Security';

  @override
  String get appLockToggleLabel => 'App lock';

  @override
  String get appLockToggleHelperMessage =>
      'Require your fingerprint, face, or device PIN to open Cashly.';

  @override
  String get appLockUnsupportedMessage =>
      'Set up a fingerprint, face unlock, or screen lock on this device to use app lock.';

  @override
  String get appLockUpdateFailedMessage =>
      'Could not update app lock. Please try again.';

  @override
  String get appLockTitle => 'Cashly is locked';

  @override
  String get appLockReasonMessage => 'Authenticate to open Cashly';

  @override
  String get appLockFailedMessage => 'Authentication failed. Please try again.';

  @override
  String get appLockUnavailableMessage =>
      'Authentication isn\'t available right now. Please try again.';

  @override
  String get appLockUnlockButton => 'Unlock';

  @override
  String get notificationsSectionTitle => 'Notifications';

  @override
  String get notificationsToggleLabel => 'Budget & balance alerts';

  @override
  String get notificationsToggleHelperMessage =>
      'Get notified when a budget goes over its limit, an account balance goes negative, or a savings goal contribution is due — even when Cashly isn\'t open.';

  @override
  String get notificationsUpdateFailedMessage =>
      'Could not update notifications. Please try again.';

  @override
  String get notificationsPermissionDeniedMessage =>
      'Notifications are turned off for Cashly in your device settings.';

  @override
  String get budgetExceededNotificationTitle => 'Budget exceeded';

  @override
  String budgetExceededNotificationBody(String category) {
    return 'You\'ve gone over your $category budget for this month.';
  }

  @override
  String get negativeBalanceNotificationTitle => 'Account balance negative';

  @override
  String negativeBalanceNotificationBody(String account) {
    return 'Your $account balance has gone negative.';
  }

  @override
  String get goalReminderNotificationTitle => 'Savings goal reminder';

  @override
  String goalReminderNotificationBody(String frequency, String goalName) {
    return 'Time for your $frequency contribution to \"$goalName\".';
  }

  @override
  String get defaultsSectionTitle => 'Defaults';

  @override
  String get defaultCurrencyLabel => 'Default currency';

  @override
  String get defaultCurrencyHelperMessage =>
      'Used to pre-select the currency when you create a new account or budget.';

  @override
  String get defaultCurrencyUpdateFailedMessage =>
      'Could not update your default currency.';

  @override
  String currencyDisplayFormat(String code, String name) {
    return '$code — $name';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get editNameDialogTitle => 'Edit name';

  @override
  String get nameUpdatedMessage => 'Name updated.';

  @override
  String get nameUpdateFailedMessage => 'Could not update your name.';

  @override
  String get deleteUserAccountTitle => 'Delete account?';

  @override
  String get deleteUserAccountMessageWithPassword =>
      'This permanently deletes your account and all of your data — accounts, transactions, categories, and budgets. This cannot be undone.';

  @override
  String get deleteUserAccountMessageGoogle =>
      'This permanently deletes your account and all of your data — accounts, transactions, categories, and budgets. This cannot be undone. You\'ll be asked to confirm with Google on the next step.';

  @override
  String get confirmYourPasswordLabel => 'Confirm your password';

  @override
  String get deleteAccountConfirmButton => 'Delete Account';

  @override
  String get deleteUserAccountFailedMessage => 'Could not delete your account.';

  @override
  String get addYourNameLabel => 'Add your name';

  @override
  String get emailVerifiedLabel => 'Email verified';

  @override
  String get notVerifiedLabel => 'Not verified';

  @override
  String get memberSinceLabel => 'Member since';

  @override
  String get deleteAccountButtonLabel => 'Delete account';

  @override
  String get iconLabel => 'Icon';

  @override
  String get colorLabel => 'Color';
}
