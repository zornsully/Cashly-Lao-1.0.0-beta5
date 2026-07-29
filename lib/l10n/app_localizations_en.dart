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
  String get accountCurrencyLockedHelper =>
      'Currency can\'t be changed after an account is created.';

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

  @override
  String get smartMoneyScoreCardTitle => 'Cashly Smart Money Score';

  @override
  String get smartMoneyScoreCardSubtitle =>
      'Balance movement leads. Habits provide the context.';

  @override
  String get smartMoneyScoreWhatIsShapingLabel => 'What is shaping this month';

  @override
  String get smartMoneyScorePracticalNextStepLabel => 'A practical next step';

  @override
  String get smartMoneyScoreWhyThisScore => 'Why this score?';

  @override
  String get smartMoneyScoreComparedWithOpening =>
      'Compared with your month opening balance';

  @override
  String get smartMoneyScoreNeutralBaseline =>
      'Using a neutral baseline until enough data is available';

  @override
  String smartMoneyScoreMonthlyHeroLabel(int max) {
    return 'MONTHLY SCORE · / $max';
  }

  @override
  String get smartMoneyScoreStatusNotEnoughData => 'Not enough data';

  @override
  String get smartMoneyScoreStatusExcellentGrowth => 'Excellent Growth';

  @override
  String get smartMoneyScoreStatusGrowing => 'Growing';

  @override
  String get smartMoneyScoreStatusStable => 'Stable';

  @override
  String get smartMoneyScoreStatusDeclining => 'Declining';

  @override
  String get smartMoneyScoreStatusNeedsAttention => 'Needs Attention';

  @override
  String get smartMoneyScoreStatusExcellent => 'Excellent';

  @override
  String get smartMoneyScoreStatusGood => 'Good';

  @override
  String get smartMoneyScoreStatusFair => 'Fair';

  @override
  String get smartMoneyScoreStatusHighRisk => 'High Risk';

  @override
  String get financialInsightPeriodToday => 'Today';

  @override
  String get financialInsightPeriodWeek => 'Week';

  @override
  String get financialInsightPeriodMonth => 'Month';

  @override
  String get smartMoneyScoreBudgetNoneSet => 'No budgets set';

  @override
  String smartMoneyScoreBudgetOverCount(int count) {
    return '$count over budget';
  }

  @override
  String smartMoneyScoreBudgetNearlyFullCount(int count) {
    return '$count nearly full';
  }

  @override
  String get smartMoneyScoreBudgetOnTrack => 'On track';

  @override
  String get smartMoneyScoreBreakdownSheetDescription =>
      'The monthly score is calculated from the same synced financial data shown in your dashboard. Balance movement is always the main factor.';

  @override
  String get smartMoneyScoreBreakdownUnavailableFallback =>
      'Cashly needs a reliable month opening balance before it can give a full comparison. The score stays neutral rather than guessing.';

  @override
  String get smartMoneyScoreSectionBalanceMovement => 'Balance movement';

  @override
  String get smartMoneyScoreSectionMonthActivity =>
      'This month\'s financial activity';

  @override
  String get smartMoneyScoreSectionFormula => 'Formula';

  @override
  String get smartMoneyScoreRowOpeningBalance => 'Opening balance';

  @override
  String get smartMoneyScoreRowCurrentBalance => 'Current balance';

  @override
  String get smartMoneyScoreRowBalanceChange => 'Balance change';

  @override
  String get smartMoneyScoreRowBalanceGrowthContribution =>
      'Balance-growth contribution';

  @override
  String get smartMoneyScoreRowIncome => 'Income';

  @override
  String get smartMoneyScoreRowExpenses => 'Expenses';

  @override
  String get smartMoneyScoreRowNetCashFlowSavings => 'Net cash flow / savings';

  @override
  String get smartMoneyScoreRowBudgetPerformance => 'Budget performance';

  @override
  String get smartMoneyScoreRowPreviousPeriodComparison =>
      'Previous-period comparison';

  @override
  String get smartMoneyScoreRowOverdueBills => 'Overdue bills';

  @override
  String get smartMoneyScoreRowStartingScore => 'Starting score';

  @override
  String get smartMoneyScoreRowBehaviourModifier => 'Behaviour modifier';

  @override
  String get smartMoneyScoreRowFinalMonthlyScore => 'Final monthly score';

  @override
  String get smartMoneyScoreValueNotIncludedYet => 'Not included yet';

  @override
  String get smartMoneyScoreValueNeutralUntilBaseline =>
      'Neutral until a baseline is available';

  @override
  String smartMoneyScoreValueBehaviourModifierPoints(String points) {
    return '$points points (capped at ±10)';
  }

  @override
  String smartMoneyScorePointsSuffix(String points) {
    return '$points points';
  }

  @override
  String get smartMoneyScoreValueNoComparisonYet => 'No comparison yet';

  @override
  String get smartMoneyScoreImpactIncomePositive =>
      'Income is ahead of expenses.';

  @override
  String get smartMoneyScoreImpactIncomeNegative =>
      'Expenses are ahead of income.';

  @override
  String get smartMoneyScoreImpactIncomeNeutral =>
      'Income and expenses are currently even or unavailable.';

  @override
  String get smartMoneyScoreImpactSavingsPositive =>
      'Positive cash flow supports the score.';

  @override
  String get smartMoneyScoreImpactSavingsNegative =>
      'Negative cash flow lowers the behaviour modifier slightly.';

  @override
  String get smartMoneyScoreImpactSavingsNeutral =>
      'No cash-flow modifier was applied.';

  @override
  String get smartMoneyScoreImpactBudgetPositive =>
      'Current budgets remain on track.';

  @override
  String get smartMoneyScoreImpactBudgetNegative =>
      'Budget room is tight or a budget is exceeded.';

  @override
  String get smartMoneyScoreImpactBudgetNeutral =>
      'No active budget modifier was applied.';

  @override
  String get smartMoneyScoreImpactTrendPositive =>
      'Spending is lower than the comparable period.';

  @override
  String get smartMoneyScoreImpactTrendNegative =>
      'Spending is notably higher than the comparable period.';

  @override
  String get smartMoneyScoreImpactTrendNeutral =>
      'There is not enough comparable spending data yet.';

  @override
  String get smartMoneyScoreImpactBillsSupporting =>
      'No verified bill or reminder record is available, so no bill penalty was added.';

  @override
  String get smartMoneyScoreMetricNetCashFlow => 'Net cash flow';

  @override
  String get smartMoneyScoreMetricComparedLastMonth =>
      'Compared with last month';

  @override
  String smartMoneyScoreMetricExpensesChange(String percent) {
    return '$percent expenses';
  }

  @override
  String get smartMoneyScoreFormulaFootnote =>
      'Monthly score = clamp(0–150, 100 + balance change % + financial behaviour modifier).';

  @override
  String get financialInsightMsgSteadySpendingHeadline =>
      'Your spending is looking steady today.';

  @override
  String get financialInsightMsgSteadySpendingExplanation =>
      'Keep logging transactions and Cashly will make each insight more personal.';

  @override
  String get financialInsightMsgNegativeBalanceHeadline =>
      'Your total balance is below zero.';

  @override
  String financialInsightMsgNegativeBalanceExplanation(
    String currency,
    String amount,
  ) {
    return 'Your total $currency balance is $amount. Bringing that shortfall above zero is the clearest next step.';
  }

  @override
  String get financialInsightMsgPlanEssentialExpenseTitle =>
      'Plan the next essential expense first';

  @override
  String get financialInsightMsgPlanEssentialExpenseDetail =>
      'Focusing on one necessary expense at a time can help rebuild a positive buffer without judging past choices.';

  @override
  String financialInsightMsgCategoryOverBudgetHeadline(String category) {
    return '$category is over its monthly budget.';
  }

  @override
  String financialInsightMsgCategoryOverBudgetExplanation(
    String spent,
    String limit,
  ) {
    return 'You have spent $spent against a $limit plan.';
  }

  @override
  String financialInsightMsgPauseCategorySpendingTitle(String category) {
    return 'Pause $category spending for today';
  }

  @override
  String get financialInsightMsgPauseCategorySpendingDetail =>
      'A short pause protects the rest of this month\'s plan without judging past choices.';

  @override
  String financialInsightMsgCategoryNeedsRoomHeadline(String category) {
    return '$category needs a little room this month.';
  }

  @override
  String financialInsightMsgCategoryNeedsRoomExplanation(
    String percent,
    String limit,
  ) {
    return 'You have used $percent of its $limit budget.';
  }

  @override
  String financialInsightMsgSetRestOfMonthLimitTitle(String category) {
    return 'Set a rest-of-month limit for $category';
  }

  @override
  String financialInsightMsgSetRestOfMonthLimitDetail(String remaining) {
    return 'Keeping the next purchases within $remaining will keep this budget on track.';
  }

  @override
  String financialInsightMsgCategoryHigherThanUsualHeadline(String category) {
    return '$category is higher than your usual pace.';
  }

  @override
  String financialInsightMsgCategoryHigherThanUsualExplanation(
    String changePercent,
  ) {
    return 'It is $changePercent above the comparable period, so it is worth a quick check-in.';
  }

  @override
  String financialInsightMsgReviewNextCategoryPurchaseTitle(String category) {
    return 'Review your next $category purchase';
  }

  @override
  String get financialInsightMsgReviewNextCategoryPurchaseDetail =>
      'A small swap or delay can soften this increase while you decide whether it was a one-off.';

  @override
  String get financialInsightMsgTodaySpendingFasterHeadline =>
      'Today is spending faster than this week\'s pace.';

  @override
  String get financialInsightMsgTodaySpendingFasterExplanation =>
      'That can happen — one intentional check before another purchase keeps the day in your control.';

  @override
  String get financialInsightMsgCheckNextExpenseTitle =>
      'Check the next expense before you buy';

  @override
  String get financialInsightMsgCheckNextExpenseDetail =>
      'A quick pause can keep today closer to your usual pace without changing what has already happened.';

  @override
  String get financialInsightMsgSpendingAheadOfIncomeHeadline =>
      'This month\'s spending is ahead of income so far.';

  @override
  String get financialInsightMsgSpendingAheadOfIncomeExplanation =>
      'This is a trend to watch, not a verdict — one or two intentional choices can still change the month.';

  @override
  String get financialInsightMsgChooseLowPriorityExpenseTitle =>
      'Choose one low-priority expense to delay';

  @override
  String get financialInsightMsgChooseLowPriorityExpenseDetail =>
      'Focus on the next choice only; reducing one flexible cost can bring the month closer to balance.';

  @override
  String get financialInsightMsgBalanceZeroHeadline =>
      'Your available balance is at zero.';

  @override
  String get financialInsightMsgBalanceThinHeadline =>
      'Your balance buffer is getting tight.';

  @override
  String get financialInsightMsgBalanceLimitedHeadline =>
      'Your balance could use a little more room.';

  @override
  String get financialInsightMsgBalanceSteadyHeadline =>
      'Your balance is looking steady.';

  @override
  String financialInsightMsgBalanceZeroExplanation(String currency) {
    return 'There is no $currency buffer left after recent activity. Choosing the next expense carefully can help create room again.';
  }

  @override
  String financialInsightMsgBalanceThinExplanation(String currency, int days) {
    return 'At your recent spending pace, this $currency balance covers about $days days. Protecting one essential expense first can help.';
  }

  @override
  String financialInsightMsgBalanceLimitedExplanation(
    String currency,
    int days,
  ) {
    return 'At your recent spending pace, this $currency balance covers about $days days. A small rest-of-week plan can preserve that room.';
  }

  @override
  String get financialInsightMsgBalanceSteadyExplanation =>
      'Your balance is supporting your current pace.';

  @override
  String get financialInsightMsgProtectEssentialExpenseTitle =>
      'Protect the next essential expense';

  @override
  String get financialInsightMsgProtectEssentialExpenseDetail =>
      'Choosing the next necessary cost first can help create space before adding anything optional.';

  @override
  String financialInsightMsgReserveNextDaysTitle(int days) {
    return 'Reserve the next $days days of essentials';
  }

  @override
  String get financialInsightMsgReserveNextDaysDetail =>
      'Keeping that small buffer for needs first gives your balance more room to recover.';

  @override
  String get financialInsightMsgSetShortRestOfWeekLimitTitle =>
      'Set a short rest-of-week limit';

  @override
  String get financialInsightMsgSetShortRestOfWeekLimitDetail =>
      'A small limit for flexible spending can keep your current balance working for longer.';

  @override
  String get financialInsightMsgKeepExpenseIntentionalTitle =>
      'Keep your next expense intentional';

  @override
  String get financialInsightMsgKeepExpenseIntentionalBalanceDetail =>
      'Your balance is supporting the current pace. A quick check before spending helps it stay that way.';

  @override
  String get financialInsightMsgKeepExpenseIntentionalPaceDetail =>
      'Your current pace is healthy. A quick check before a purchase helps it stay that way.';

  @override
  String get financialInsightMsgOnboardingHeadline =>
      'Let\'s build your first spending pattern.';

  @override
  String get financialInsightMsgOnboardingExplanation =>
      'Add a few income or expense entries and Cashly will turn them into personal daily, weekly, and monthly check-ins.';

  @override
  String get financialInsightMsgLogNextExpenseTitle => 'Log your next expense';

  @override
  String get financialInsightMsgLogNextExpenseDetail =>
      'Even a small everyday purchase gives the assistant a better starting point.';

  @override
  String get financialInsightMsgNotEnoughActivityTodayReason =>
      'There is not enough recent activity to score today\'s trend yet.';

  @override
  String get financialInsightMsgNotEnoughActivityWeekReason =>
      'There is not enough recent activity to score this week\'s trend yet.';

  @override
  String get financialInsightMsgNotEnoughActivityMonthReason =>
      'There is not enough recent activity to score this month\'s trend yet.';

  @override
  String financialInsightMsgBalanceImpactNegativeReason(String currency) {
    return 'Your total $currency balance is below zero, so rebuilding a positive buffer is the priority.';
  }

  @override
  String financialInsightMsgBalanceImpactEmptyReason(String currency) {
    return 'Your active $currency balance is at zero after recent activity.';
  }

  @override
  String financialInsightMsgBalanceImpactLowReason(String currency, int days) {
    return 'Your total $currency balance covers about $days days at your recent spending pace.';
  }

  @override
  String financialInsightMsgBalanceImpactHealthyReason(String currency) {
    return 'Your total $currency balance covers more than a month at your recent spending pace.';
  }

  @override
  String financialInsightMsgCategoryOverBudgetReasonToday(String category) {
    return '$category is already over its monthly budget.';
  }

  @override
  String financialInsightMsgCategoryNearBudgetReasonToday(String category) {
    return '$category has little budget room left this month.';
  }

  @override
  String get financialInsightMsgTodaySpikeReason =>
      'Today\'s spending is more than twice your earlier daily pace this week.';

  @override
  String financialInsightMsgTodayComparableIncreaseReason(
    String changePercent,
  ) {
    return 'Today\'s spending is $changePercent above yesterday\'s comparable total.';
  }

  @override
  String get financialInsightMsgNoActivityTodayReason =>
      'No income or expense has been recorded today.';

  @override
  String get financialInsightMsgIncomeCoversTodayReason =>
      'Today\'s recorded income covers today\'s spending.';

  @override
  String financialInsightMsgCategoryOverBudgetReasonWeek(String category) {
    return '$category is over budget, so this week needs a gentler pace.';
  }

  @override
  String financialInsightMsgCategoryNearBudgetReasonWeek(String category) {
    return '$category is close to its monthly limit.';
  }

  @override
  String financialInsightMsgCategoryPacedBudgetReasonWeek(String category) {
    return '$category is ahead of its expected monthly pace.';
  }

  @override
  String financialInsightMsgWeeklyCategorySpikeReason(
    String category,
    String changePercent,
  ) {
    return '$category is $changePercent above the comparable week.';
  }

  @override
  String financialInsightMsgWeekComparableIncreaseReason(String changePercent) {
    return 'This week\'s spending is $changePercent above last week\'s comparable total.';
  }

  @override
  String get financialInsightMsgWeekComparableDecreaseReason =>
      'This week is spending less than the comparable previous week.';

  @override
  String financialInsightMsgCategoryOverBudgetReasonMonth(
    String category,
    String percent,
  ) {
    return '$category is $percent over budget.';
  }

  @override
  String financialInsightMsgCategoryNearBudgetReasonMonth(
    String category,
    String remaining,
  ) {
    return '$category has $remaining remaining.';
  }

  @override
  String financialInsightMsgCategoryPacedBudgetReasonMonth(String category) {
    return '$category is spending faster than its monthly plan.';
  }

  @override
  String financialInsightMsgSpendingOverIncomeReasonMonth(
    String expense,
    String income,
  ) {
    return 'Month-to-date spending is $expense versus $income income.';
  }

  @override
  String get financialInsightMsgIncomeCoversMonthReason =>
      'Income currently covers this month\'s recorded spending.';

  @override
  String financialInsightMsgMonthComparableIncreaseReason(
    String changePercent,
  ) {
    return 'Month-to-date spending is $changePercent above the comparable previous month.';
  }

  @override
  String get financialInsightMsgMonthComparableDecreaseReason =>
      'Month-to-date spending is lower than the comparable previous period.';

  @override
  String get financialInsightMsgSteadyReasonToday =>
      'Today is within a healthy spending pace.';

  @override
  String get financialInsightMsgSteadyReasonWeek =>
      'This week is tracking close to your recent pace.';

  @override
  String get financialInsightMsgSteadyReasonMonth =>
      'This month is within the plan recorded in Cashly.';

  @override
  String get financialInsightMsgShortHorizonNoActiveAccountToday =>
      'Today has no active account balance to compare yet, so Cashly is using current balance, budget, and spending signals.';

  @override
  String get financialInsightMsgShortHorizonNoActiveAccountWeek =>
      'This week has no active account balance to compare yet, so Cashly is using current balance, budget, and spending signals.';

  @override
  String get financialInsightMsgShortHorizonCrossCurrencyToday =>
      'A transfer between currencies occurred today. Cashly is keeping its balance comparison neutral until an exchange-rate basis is available.';

  @override
  String get financialInsightMsgShortHorizonCrossCurrencyWeek =>
      'A transfer between currencies occurred this week. Cashly is keeping its balance comparison neutral until an exchange-rate basis is available.';

  @override
  String get financialInsightMsgShortHorizonAccountAddedToday =>
      'An account was added today, so Cashly cannot safely reconstruct that opening balance yet.';

  @override
  String get financialInsightMsgShortHorizonAccountAddedWeek =>
      'An account was added this week, so Cashly cannot safely reconstruct that opening balance yet.';

  @override
  String get financialInsightMsgShortHorizonUnverifiableToday =>
      'Cashly could not verify the balance values for today, so its balance comparison is neutral.';

  @override
  String get financialInsightMsgShortHorizonUnverifiableWeek =>
      'Cashly could not verify the balance values for this week, so its balance comparison is neutral.';

  @override
  String get financialInsightMsgShortHorizonZeroOpeningToday =>
      'Today began at zero with no recorded income or expense, so Cashly is using current balance, budget, and spending signals.';

  @override
  String get financialInsightMsgShortHorizonZeroOpeningWeek =>
      'This week began at zero with no recorded income or expense, so Cashly is using current balance, budget, and spending signals.';

  @override
  String financialInsightMsgShortHorizonIncreasedToday(
    String percent,
    String points,
  ) {
    return 'Today\'s balance increased by $percent, contributing $points to the score alongside budget and spending signals.';
  }

  @override
  String financialInsightMsgShortHorizonIncreasedWeek(
    String percent,
    String points,
  ) {
    return 'This week\'s balance increased by $percent, contributing $points to the score alongside budget and spending signals.';
  }

  @override
  String financialInsightMsgShortHorizonDecreasedToday(
    String percent,
    String points,
  ) {
    return 'Today\'s balance decreased by $percent, contributing $points to the score alongside budget and spending signals.';
  }

  @override
  String financialInsightMsgShortHorizonDecreasedWeek(
    String percent,
    String points,
  ) {
    return 'This week\'s balance decreased by $percent, contributing $points to the score alongside budget and spending signals.';
  }

  @override
  String financialInsightMsgShortHorizonStayedLevelToday(String points) {
    return 'Today\'s balance stayed level, contributing $points to the score alongside budget and spending signals.';
  }

  @override
  String financialInsightMsgShortHorizonStayedLevelWeek(String points) {
    return 'This week\'s balance stayed level, contributing $points to the score alongside budget and spending signals.';
  }
}
