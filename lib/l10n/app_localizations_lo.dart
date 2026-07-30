// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lao (`lo`).
class AppLocalizationsLo extends AppLocalizations {
  AppLocalizationsLo([String locale = 'lo']) : super(locale);

  @override
  String get appName => 'Cashly';

  @override
  String get errorGenericTitle => 'ມີບາງຢ່າງຜິດພາດ';

  @override
  String get retry => 'ລອງໃໝ່';

  @override
  String get cancel => 'ຍົກເລີກ';

  @override
  String get delete => 'ລຶບ';

  @override
  String get splashTimeoutMessage =>
      'ນີ້ໃຊ້ເວລາດົນກວ່າທີ່ຄາດໄວ້. ກະລຸນາກວດສອບການເຊື່ອມຕໍ່ອິນເຕີເນັດຂອງທ່ານ ແລະລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get loginTitle => 'ຍິນດີຕ້ອນຮັບກັບຄືນ';

  @override
  String get loginSubtitle => 'ເຂົ້າສູ່ລະບົບເພື່ອຕິດຕາມເງິນຂອງທ່ານ.';

  @override
  String get emailLabel => 'ອີເມວ';

  @override
  String get passwordLabel => 'ລະຫັດຜ່ານ';

  @override
  String get passwordRequiredError => 'ກະລຸນາປ້ອນລະຫັດຜ່ານ.';

  @override
  String get forgotPasswordLink => 'ລືມລະຫັດຜ່ານ?';

  @override
  String get signIn => 'ເຂົ້າສູ່ລະບົບ';

  @override
  String get loginFailedMessage =>
      'ບໍ່ສາມາດເຂົ້າສູ່ລະບົບໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get noAccountPrompt => 'ບໍ່ມີບັນຊີ?';

  @override
  String get signUpLink => 'ສະໝັກສະມາຊິກ';

  @override
  String get orDividerLabel => 'ຫຼື';

  @override
  String get continueWithGoogle => 'ດຳເນີນການຕໍ່ດ້ວຍ Google';

  @override
  String get googleSignInFailedMessage =>
      'ບໍ່ສາມາດເຂົ້າສູ່ລະບົບດ້ວຍ Google ໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get registerTitle => 'ສ້າງບັນຊີຂອງທ່ານ';

  @override
  String get registerSubtitle =>
      'ເລີ່ມຕົ້ນການວາງແຜນງົບປະມານແບບສະຫຼາດພາຍໃນສອງສາມນາທີ.';

  @override
  String get fullNameLabel => 'ຊື່ເຕັມ';

  @override
  String get confirmPasswordLabel => 'ຢືນຢັນລະຫັດຜ່ານ';

  @override
  String get createAccountButton => 'ສ້າງບັນຊີ';

  @override
  String get registerFailedMessage =>
      'ບໍ່ສາມາດສ້າງບັນຊີຂອງທ່ານໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get haveAccountPrompt => 'ມີບັນຊີແລ້ວບໍ?';

  @override
  String get forgotPasswordTitle => 'ຕັ້ງລະຫັດຜ່ານໃໝ່';

  @override
  String get forgotPasswordSubtitle =>
      'ປ້ອນອີເມວຂອງທ່ານ ແລະພວກເຮົາຈະສົ່ງລິ້ງຕັ້ງລະຫັດຜ່ານໃໝ່ໃຫ້.';

  @override
  String get sendResetLinkButton => 'ສົ່ງລິ້ງຕັ້ງລະຫັດຜ່ານໃໝ່';

  @override
  String get resetEmailFailedMessage =>
      'ບໍ່ສາມາດສົ່ງອີເມວຕັ້ງລະຫັດຜ່ານໃໝ່ໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get checkEmailTitle => 'ກວດສອບອີເມວຂອງທ່ານ';

  @override
  String checkEmailSubtitle(String email) {
    return 'ພວກເຮົາໄດ້ສົ່ງລິ້ງຕັ້ງລະຫັດຜ່ານໃໝ່ໄປທີ່ $email ແລ້ວ.';
  }

  @override
  String get backToSignInButton => 'ກັບໄປໜ້າເຂົ້າສູ່ລະບົບ';

  @override
  String get verifyEmailTitle => 'ຢືນຢັນອີເມວຂອງທ່ານ';

  @override
  String verifyEmailSubtitle(String email) {
    return 'ພວກເຮົາໄດ້ສົ່ງລິ້ງຢືນຢັນໄປທີ່ $email ແລ້ວ. ກົດລິ້ງນັ້ນ ແລ້ວສືບຕໍ່ດ້ານລຸ່ມ.';
  }

  @override
  String get verifiedButton => 'ຂ້ອຍໄດ້ຢືນຢັນອີເມວແລ້ວ';

  @override
  String get resendEmailButton => 'ສົ່ງອີເມວອີກຄັ້ງ';

  @override
  String resendEmailCountdownButton(int seconds) {
    return 'ສົ່ງອີເມວອີກຄັ້ງ ($secondsວິ)';
  }

  @override
  String get verificationEmailSentMessage => 'ສົ່ງອີເມວຢືນຢັນແລ້ວ.';

  @override
  String get resendFailedMessage =>
      'ບໍ່ສາມາດສົ່ງອີເມວອີກຄັ້ງໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get notVerifiedYetMessage => 'ພວກເຮົາຍັງບໍ່ສາມາດຢືນຢັນໄດ້.';

  @override
  String get signOutButton => 'ອອກຈາກລະບົບ';

  @override
  String get dashboardTitle => 'ໜ້າຫຼັກ';

  @override
  String get offlineBannerMessage =>
      'ອອບໄລນ໌ — ຂໍ້ມູນຈະຊິງຄ໌ອັດຕະໂນມັດເມື່ອທ່ານກັບມາອອນລາຍ';

  @override
  String get reportsTooltip => 'ບົດລາຍງານ';

  @override
  String get previousMonthTooltip => 'ເດືອນກ່ອນໜ້າ';

  @override
  String get nextMonthTooltip => 'ເດືອນຖັດໄປ';

  @override
  String get showPasswordTooltip => 'ສະແດງລະຫັດຜ່ານ';

  @override
  String get hidePasswordTooltip => 'ເຊື່ອງລະຫັດຜ່ານ';

  @override
  String get editDisplayNameTooltip => 'ແກ້ໄຂຊື່';

  @override
  String get deleteTransactionTitle => 'ລຶບລາຍການທຸລະກຳ?';

  @override
  String get deleteTransactionMessage =>
      'ການດຳເນີນການນີ້ຈະລຶບລາຍການທຸລະກຳຢ່າງຖາວອນ ແລະ ຍ້ອນຄືນຜົນກະທົບຕໍ່ຍອດເງິນຂອງບັນຊີ. ບໍ່ສາມາດຍົກເລີກໄດ້.';

  @override
  String get deleteTransactionFailedMessage => 'ບໍ່ສາມາດລຶບລາຍການທຸລະກຳໄດ້.';

  @override
  String get welcomeToCashly => 'ຍິນດີຕ້ອນຮັບສູ່ Cashly';

  @override
  String get addFirstAccountMessage =>
      'ເພີ່ມບັນຊີທຳອິດຂອງທ່ານເພື່ອເລີ່ມເບິ່ງສະຫຼຸບການເງິນຂອງທ່ານທີ່ນີ້.';

  @override
  String get addAccountButton => 'ເພີ່ມບັນຊີ';

  @override
  String get recentTransactionsTitle => 'ລາຍການທຸລະກຳຫຼ້າສຸດ';

  @override
  String get noTransactionsThisMonth => 'ຍັງບໍ່ມີລາຍການທຸລະກຳໃນເດືອນນີ້.';

  @override
  String get spendingByCategoryTitle => 'ລາຍຈ່າຍຕາມໝວດໝູ່';

  @override
  String get budgetsTitle => 'ງົບປະມານ';

  @override
  String get accountBalancesTitle => 'ຍອດເງິນໃນບັນຊີ';

  @override
  String get seeAll => 'ເບິ່ງທັງໝົດ';

  @override
  String totalBalanceLabel(String currencyCode) {
    return 'ຍອດເງິນລວມ ($currencyCode)';
  }

  @override
  String get incomeMonthLabel => 'ລາຍຮັບ (ເດືອນ)';

  @override
  String get expenseMonthLabel => 'ລາຍຈ່າຍ (ເດືອນ)';

  @override
  String get dashboardHeaderSubtitle =>
      'ມຸມມອງທີ່ຈະແຈ້ງກ່ຽວກັບເງິນຂອງທ່ານໃນເດືອນນີ້.';

  @override
  String get dashboardQuickActionAddIncome => 'ເພີ່ມລາຍຮັບ';

  @override
  String get dashboardQuickActionAddExpense => 'ເພີ່ມລາຍຈ່າຍ';

  @override
  String get dashboardQuickActionTransferMoney => 'ໂອນເງິນ';

  @override
  String get dashboardQuickActionCreateBudget => 'ສ້າງງົບປະມານ';

  @override
  String get dashboardMetricTotalBalance => 'ຍອດເງິນລວມ';

  @override
  String get dashboardMetricTotalBalanceCaption =>
      'ອັບເດດແບບສົດຈາກທຸກບັນຊີທີ່ໃຊ້ງານ';

  @override
  String dashboardMetricAlsoBalance(String currencyCode, String amount) {
    return 'ພ້ອມທັງ $currencyCode $amount';
  }

  @override
  String get dashboardMetricMonthlyIncome => 'ລາຍຮັບປະຈຳເດືອນ';

  @override
  String get dashboardMetricMonthlyExpenses => 'ລາຍຈ່າຍປະຈຳເດືອນ';

  @override
  String get dashboardMetricNetCashFlow => 'ກະແສເງິນສົດສຸດທິ';

  @override
  String get dashboardMetricThisMonthCaption => 'ເດືອນປະຕິທິນນີ້';

  @override
  String get dashboardMetricNetCaption => 'ລາຍຮັບຫັກລາຍຈ່າຍ';

  @override
  String get dashboardChooseCurrencyTooltip => 'ເລືອກສະກຸນເງິນ';

  @override
  String get dashboardNotificationsTooltip => 'ການແຈ້ງເຕືອນ';

  @override
  String get dashboardNotificationsEmptyMessage =>
      'ທ່ານໄດ້ຮັບຂໍ້ມູນລ່າສຸດແລ້ວ.';

  @override
  String get dashboardIncomeExpensePanelTitle => 'ລາຍຮັບ ແລະ ລາຍຈ່າຍ';

  @override
  String get dashboardTrendEmptyMessage =>
      'ຍັງບໍ່ມີກິດຈະກຳພຽງພໍທີ່ຈະສະແດງແນວໂນ້ມ.';

  @override
  String get dashboardTrendLast6Months => '6 ເດືອນຫຼ້າສຸດ';

  @override
  String get dashboardCategoryEmptyMessage =>
      'ບໍ່ມີໝວດໝູ່ລາຍຈ່າຍທີ່ບັນທຶກໄວ້ໃນເດືອນນີ້.';

  @override
  String get dashboardCategoryBreakdownLabel => 'ການແບ່ງແຍກຕາມໝວດໝູ່';

  @override
  String get dashboardBudgetsEmptyMessage =>
      'ບໍ່ມີງົບປະມານທີ່ໃຊ້ງານໃນເດືອນນີ້.';

  @override
  String get languageSectionTitle => 'ພາສາ';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageLao => 'ລາວ';

  @override
  String get languageUpdateFailedMessage => 'ບໍ່ສາມາດປ່ຽນພາສາໄດ້.';

  @override
  String get emailRequiredError => 'ກະລຸນາປ້ອນອີເມວ.';

  @override
  String get emailInvalidError => 'ກະລຸນາປ້ອນອີເມວທີ່ຖືກຕ້ອງ.';

  @override
  String get passwordTooShortError => 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 8 ໂຕອັກສອນ.';

  @override
  String get passwordNeedsUppercaseError => 'ຕ້ອງມີໂຕພິມໃຫຍ່ຢ່າງໜ້ອຍໜຶ່ງໂຕ.';

  @override
  String get passwordNeedsNumberError => 'ຕ້ອງມີໂຕເລກຢ່າງໜ້ອຍໜຶ່ງໂຕ.';

  @override
  String get confirmPasswordRequiredError => 'ກະລຸນາຢືນຢັນລະຫັດຜ່ານຂອງທ່ານ.';

  @override
  String get passwordsDoNotMatchError => 'ລະຫັດຜ່ານບໍ່ກົງກັນ.';

  @override
  String get nameRequiredError => 'ກະລຸນາປ້ອນຊື່.';

  @override
  String get nameTooShortError => 'ຊື່ຕ້ອງມີຢ່າງໜ້ອຍ 2 ໂຕອັກສອນ.';

  @override
  String fieldRequiredError(String label) {
    return 'ກະລຸນາປ້ອນ $label.';
  }

  @override
  String get amountRequiredError => 'ກະລຸນາປ້ອນຈຳນວນເງິນ.';

  @override
  String get amountInvalidError => 'ກະລຸນາປ້ອນຕົວເລກທີ່ຖືກຕ້ອງ.';

  @override
  String get amountMustBePositiveError => 'ຈຳນວນເງິນຕ້ອງຫຼາຍກວ່າສູນ.';

  @override
  String get incomeLabel => 'ລາຍຮັບ';

  @override
  String get expenseLabel => 'ລາຍຈ່າຍ';

  @override
  String get transferLabel => 'ໂອນເງິນ';

  @override
  String get archivedBadgeLabel => 'ເກັບໄວ້';

  @override
  String get defaultBadgeLabel => 'ຄ່າເລີ່ມຕົ້ນ';

  @override
  String get negativeBalanceBadgeLabel => 'ຕິດລົບ';

  @override
  String accountPercentOfTotalBalance(String percent) {
    return '$percent% ຂອງທັງໝົດ';
  }

  @override
  String get archiveMenuItem => 'ເກັບຖາວອນ';

  @override
  String get unarchiveMenuItem => 'ຍົກເລີກການເກັບຖາວອນ';

  @override
  String get hideArchivedTooltip => 'ເຊື່ອງລາຍການທີ່ເກັບໄວ້';

  @override
  String get showArchivedTooltip => 'ສະແດງລາຍການທີ່ເກັບໄວ້';

  @override
  String get saveChangesButton => 'ບັນທຶກການປ່ຽນແປງ';

  @override
  String get accountsTitle => 'ບັນຊີ';

  @override
  String get noAccountsYetTitle => 'ຍັງບໍ່ມີບັນຊີ';

  @override
  String get noAccountsYetMessage =>
      'ເພີ່ມບັນຊີເງິນສົດ, ກະເປົາເງິນ, ທະນາຄານ, ບັດເຄຣດິດ ຫຼືເງິນຝາກ ເພື່ອເລີ່ມຕິດຕາມເງິນຂອງທ່ານ.';

  @override
  String get deleteAccountTitle => 'ລຶບບັນຊີ?';

  @override
  String deleteAccountMessage(String name) {
    return 'ການດຳເນີນການນີ້ຈະລຶບ \"$name\" ຢ່າງຖາວອນ. ບໍ່ສາມາດຍົກເລີກໄດ້.';
  }

  @override
  String get deleteAccountFailedMessage => 'ບໍ່ສາມາດລຶບບັນຊີໄດ້.';

  @override
  String get updateAccountFailedMessage => 'ບໍ່ສາມາດອັບເດດບັນຊີໄດ້.';

  @override
  String get accountFormEditTitle => 'ແກ້ໄຂບັນຊີ';

  @override
  String get accountNameLabel => 'ຊື່ບັນຊີ';

  @override
  String get accountTypeLabel => 'ປະເພດບັນຊີ';

  @override
  String get currentBalanceLabel => 'ຍອດເງິນປັດຈຸບັນ';

  @override
  String get initialBalanceLabel => 'ຍອດເງິນເລີ່ມຕົ້ນ';

  @override
  String get currencyLabel => 'ສະກຸນເງິນ';

  @override
  String get accountCurrencyLockedHelper =>
      'ບໍ່ສາມາດປ່ຽນສະກຸນເງິນໄດ້ຫຼັງຈາກສ້າງບັນຊີແລ້ວ.';

  @override
  String get saveAccountFailedMessage =>
      'ບໍ່ສາມາດບັນທຶກບັນຊີໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get accountTypeCashLabel => 'ເງິນສົດ';

  @override
  String get accountTypeWalletLabel => 'ກະເປົາເງິນ';

  @override
  String get accountTypeBankLabel => 'ທະນາຄານ';

  @override
  String get accountTypeCreditCardLabel => 'ບັດເຄຣດິດ';

  @override
  String get accountTypeSavingsLabel => 'ເງິນຝາກ';

  @override
  String get categoriesTitle => 'ໝວດໝູ່';

  @override
  String get noExpenseCategoriesYetTitle => 'ຍັງບໍ່ມີໝວດໝູ່ລາຍຈ່າຍ';

  @override
  String get noIncomeCategoriesYetTitle => 'ຍັງບໍ່ມີໝວດໝູ່ລາຍຮັບ';

  @override
  String get addCategoryToStartMessage =>
      'ເພີ່ມໝວດໝູ່ໜຶ່ງເພື່ອເລີ່ມຕິດປ້າຍລາຍການທຸລະກຳຂອງທ່ານ.';

  @override
  String get addCategoryButton => 'ເພີ່ມໝວດໝູ່';

  @override
  String get deleteCategoryTitle => 'ລຶບໝວດໝູ່?';

  @override
  String deleteCategoryMessage(String name) {
    return 'ການດຳເນີນການນີ້ຈະລຶບ \"$name\" ຢ່າງຖາວອນ. ບໍ່ສາມາດຍົກເລີກໄດ້.';
  }

  @override
  String get deleteCategoryFailedMessage => 'ບໍ່ສາມາດລຶບໝວດໝູ່ໄດ້.';

  @override
  String get updateCategoryFailedMessage => 'ບໍ່ສາມາດອັບເດດໝວດໝູ່ໄດ້.';

  @override
  String get reorderCategoriesFailedMessage => 'ບໍ່ສາມາດບັນທຶກລຳດັບໃໝ່ໄດ້.';

  @override
  String get categoryFormEditTitle => 'ແກ້ໄຂໝວດໝູ່';

  @override
  String get defaultCategoryLockedHelper =>
      'ໝວດໝູ່ເລີ່ມຕົ້ນບໍ່ສາມາດລຶບໄດ້ ແຕ່ທ່ານຍັງສາມາດປ່ຽນຊື່ ຫຼື ປ່ຽນໄອຄອນ ແລະ ສີໄດ້.';

  @override
  String get categoryNameLabel => 'ຊື່ໝວດໝູ່';

  @override
  String get categoryTypeLabel => 'ປະເພດ';

  @override
  String get saveCategoryFailedMessage =>
      'ບໍ່ສາມາດບັນທຶກໝວດໝູ່ໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get budgetTitle => 'ງົບປະມານ';

  @override
  String get deleteBudgetTitle => 'ລຶບງົບປະມານ?';

  @override
  String deleteBudgetMessage(String name) {
    return 'ການດຳເນີນການນີ້ຈະລຶບງົບປະມານສຳລັບ \"$name\" ຂອງເດືອນນີ້. ບໍ່ສາມາດຍົກເລີກໄດ້.';
  }

  @override
  String get deleteBudgetFailedMessage => 'ບໍ່ສາມາດລຶບງົບປະມານໄດ້.';

  @override
  String get addExpenseCategoryFirstMessage =>
      'ເພີ່ມໝວດໝູ່ລາຍຈ່າຍກ່ອນ, ແລ້ວຈຶ່ງຕັ້ງງົບປະມານໃຫ້ມັນ.';

  @override
  String get noBudgetSetLabel => 'ຍັງບໍ່ໄດ້ຕັ້ງງົບປະມານ';

  @override
  String get setBudgetButton => 'ຕັ້ງງົບປະມານ';

  @override
  String get budgetFormEditTitle => 'ແກ້ໄຂງົບປະມານ';

  @override
  String get categoryAndMonthLockedMessage =>
      'ບໍ່ສາມາດປ່ຽນໝວດໝູ່ ແລະ ເດືອນຢູ່ບ່ອນນີ້ໄດ້ — ກະລຸນາລຶບແລ້ວສ້າງງົບປະມານໃໝ່ແທນ.';

  @override
  String get monthlyLimitLabel => 'ຂອບເຂດລາຍເດືອນ';

  @override
  String get budgetCurrencyRestrictionMessage =>
      'ມີແຕ່ລາຍການທຸລະກຳໃນສະກຸນເງິນນີ້ເທົ່ານັ້ນທີ່ນັບເຂົ້າໃນງົບປະມານນີ້.';

  @override
  String get deleteBudgetTooltip => 'ລຶບງົບປະມານ';

  @override
  String overspentByMessage(String amount) {
    return 'ເກີນ $amount';
  }

  @override
  String remainingAmountMessage(String amount) {
    return 'ເຫຼືອ $amount';
  }

  @override
  String get saveBudgetFailedMessage =>
      'ບໍ່ສາມາດບັນທຶກງົບປະມານໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String budgetPercentUsedLabel(String percent) {
    return '$percent% ໃຊ້ແລ້ວ';
  }

  @override
  String get budgetedTotalLabel => 'ງົບປະມານ';

  @override
  String get spentTotalLabel => 'ໃຊ້ຈ່າຍ';

  @override
  String get remainingTotalLabel => 'ເຫຼືອ';

  @override
  String get savingsGoalsTitle => 'ເປົ້າໝາຍການເກັບເງິນ';

  @override
  String get savingsGoalsTooltip => 'ເປົ້າໝາຍການເກັບເງິນ';

  @override
  String get noSavingsGoalsYetTitle => 'ຍັງບໍ່ມີເປົ້າໝາຍການເກັບເງິນ';

  @override
  String get noSavingsGoalsYetMessage =>
      'ຕັ້ງເປົ້າໝາຍ ແລະ ເຊື່ອມຕໍ່ບັນຊີໜຶ່ງເພື່ອເລີ່ມຕິດຕາມຄວາມຄືບໜ້າ.';

  @override
  String get addGoalButton => 'ເພີ່ມເປົ້າໝາຍ';

  @override
  String get goalFormEditTitle => 'ແກ້ໄຂເປົ້າໝາຍ';

  @override
  String get goalNameLabel => 'ຊື່ເປົ້າໝາຍ';

  @override
  String get targetAmountLabel => 'ຈຳນວນເປົ້າໝາຍ';

  @override
  String get linkedAccountLabel => 'ບັນຊີທີ່ເຊື່ອມຕໍ່';

  @override
  String get linkedAccountLockedMessage =>
      'ບໍ່ສາມາດປ່ຽນບັນຊີທີ່ເຊື່ອມຕໍ່ຢູ່ບ່ອນນີ້ໄດ້ — ກະລຸນາລຶບແລ້ວສ້າງເປົ້າໝາຍໃໝ່ແທນ.';

  @override
  String get createNewAccountOption => '+ ເພີ່ມບັນຊີໃໝ່';

  @override
  String get accountAlreadyBacksGoalError =>
      'ບັນຊີນີ້ຮອງຮັບເປົ້າໝາຍການເກັບເງິນອື່ນທີ່ກຳລັງໃຊ້ງານຢູ່ແລ້ວ.';

  @override
  String get noEligibleAccountsMessage =>
      'ບັນຊີທັງໝົດຂອງທ່ານຮອງຮັບເປົ້າໝາຍອື່ນຢູ່ແລ້ວ — ກະລຸນາເພີ່ມບັນຊີໃໝ່ເພື່ອສືບຕໍ່.';

  @override
  String get autoContributionSectionTitle => 'ຝາກເງິນອັດຕະໂນມັດ';

  @override
  String get autoContributionToggleLabel => 'ແຈ້ງເຕືອນໃຫ້ຝາກເງິນ';

  @override
  String get autoContributionAmountLabel => 'ຈຳນວນເງິນທີ່ຝາກ';

  @override
  String get autoContributionFrequencyLabel => 'ຄວາມຖີ່';

  @override
  String get goalFrequencyWeeklyLabel => 'ລາຍອາທິດ';

  @override
  String get goalFrequencyBiweeklyLabel => 'ທຸກ 2 ອາທິດ';

  @override
  String get goalFrequencyMonthlyLabel => 'ລາຍເດືອນ';

  @override
  String get saveGoalFailedMessage =>
      'ບໍ່ສາມາດບັນທຶກເປົ້າໝາຍໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get deleteGoalTitle => 'ລຶບເປົ້າໝາຍ?';

  @override
  String get deleteGoalMessage =>
      'ການດຳເນີນການນີ້ຈະລຶບເປົ້າໝາຍ. ມັນບໍ່ມີຜົນກະທົບຕໍ່ບັນຊີທີ່ເຊື່ອມຕໍ່ ຫຼື ຍອດເງິນຂອງມັນ. ບໍ່ສາມາດຍົກເລີກໄດ້.';

  @override
  String get deleteGoalFailedMessage => 'ບໍ່ສາມາດລຶບເປົ້າໝາຍໄດ້.';

  @override
  String get contributeButton => 'ຝາກເງິນ';

  @override
  String get contributionSourceAccountLabel => 'ບັນຊີຕົ້ນທາງ';

  @override
  String get contributionAmountLabel => 'ຈຳນວນເງິນ';

  @override
  String get confirmContributionButton => 'ຢືນຢັນການຝາກເງິນ';

  @override
  String get contributionFailedMessage =>
      'ບໍ່ສາມາດບັນທຶກການຝາກເງິນໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String contributionDueBannerMessage(String amount) {
    return 'ເຖິງກຳນົດຝາກເງິນ $amount ຂອງທ່ານແລ້ວ.';
  }

  @override
  String get goalCompletedBadgeLabel => 'ສຳເລັດແລ້ວ';

  @override
  String get goalDueBadgeLabel => 'ຄົບກຳນົດ';

  @override
  String estimatedCompletionScheduledMessage(String date) {
    return 'ຄາດວ່າຈະສຳເລັດພາຍໃນ $date';
  }

  @override
  String estimatedCompletionTrailingAverageMessage(String date) {
    return 'ຄາດວ່າຈະສຳເລັດປະມານ $date ຕາມອັດຕາການຝາກເງິນຫຼ້າສຸດຂອງທ່ານ';
  }

  @override
  String get estimatedCompletionInsufficientDataMessage =>
      'ຝາກເງິນສອງສາມຄັ້ງເພື່ອເບິ່ງວັນທີຄາດວ່າຈະສຳເລັດ.';

  @override
  String get estimatedCompletionCompletedMessage =>
      'ທ່ານໄດ້ບັນລຸເປົ້າໝາຍຂອງທ່ານແລ້ວ.';

  @override
  String get accountActivityTitle => 'ກິດຈະກຳຂອງບັນຊີ';

  @override
  String get noAccountActivityYetMessage =>
      'ການຝາກເງິນ ແລະ ລາຍການທຸລະກຳອື່ນໆຂອງບັນຊີທີ່ເຊື່ອມຕໍ່ຈະສະແດງຢູ່ບ່ອນນີ້.';

  @override
  String get goalCelebrationTitle => 'ບັນລຸເປົ້າໝາຍແລ້ວ!';

  @override
  String goalCelebrationMessage(String goalName) {
    return 'ທ່ານໄດ້ບັນລຸເປົ້າໝາຍ \"$goalName\" ຂອງທ່ານແລ້ວ.';
  }

  @override
  String get goalNotFoundMessage => 'ເປົ້າໝາຍນີ້ບໍ່ມີອີກຕໍ່ໄປແລ້ວ.';

  @override
  String get linkedAccountArchivedMessage =>
      'ບັນຊີທີ່ເຊື່ອມຕໍ່ກັບເປົ້າໝາຍນີ້ຖືກເກັບໄວ້ແລ້ວ.';

  @override
  String get transactionsTitle => 'ລາຍການທຸລະກຳ';

  @override
  String get transactionsTabLabel => 'ທຸລະກຳ';

  @override
  String noTransactionsInMonthTitle(String month) {
    return 'ບໍ່ມີລາຍການທຸລະກຳໃນ $month';
  }

  @override
  String get addFirstTransactionMessage =>
      'ເພີ່ມລາຍຮັບ ຫຼື ລາຍຈ່າຍທຳອິດຂອງທ່ານສຳລັບເດືອນນີ້.';

  @override
  String get addTransactionButton => 'ເພີ່ມລາຍການທຸລະກຳ';

  @override
  String get searchTransactionsHint => 'ຄົ້ນຫາລາຍການທຸລະກຳ';

  @override
  String get searchTooltip => 'ຄົ້ນຫາ';

  @override
  String get closeSearchTooltip => 'ປິດການຄົ້ນຫາ';

  @override
  String get filterSortTooltip => 'ກັ່ນຕອງ ແລະ ຈັດຮຽງ';

  @override
  String get moreActionsTooltip => 'ຕົວເລືອກເພີ່ມເຕີມ';

  @override
  String get editMenuItem => 'ແກ້ໄຂ';

  @override
  String get duplicateMenuItem => 'ສຳເນົາ';

  @override
  String get transactionCountLabel => 'ລາຍການທຸລະກຳ';

  @override
  String get filterSortSheetTitle => 'ກັ່ນຕອງ ແລະ ຈັດຮຽງ';

  @override
  String get typeFilterLabel => 'ປະເພດ';

  @override
  String get allTypesLabel => 'ທຸກປະເພດ';

  @override
  String get accountFilterLabel => 'ບັນຊີ';

  @override
  String get allAccountsLabel => 'ທຸກບັນຊີ';

  @override
  String get categoryFilterLabel => 'ໝວດໝູ່';

  @override
  String get allCategoriesLabel => 'ທຸກໝວດໝູ່';

  @override
  String get sortByLabel => 'ຈັດຮຽງຕາມ';

  @override
  String get sortDateNewestLabel => 'ໃໝ່ສຸດ';

  @override
  String get sortDateOldestLabel => 'ເກົ່າສຸດ';

  @override
  String get sortAmountHighLabel => 'ຈຳນວນເງິນ: ຫຼາຍໄປໜ້ອຍ';

  @override
  String get sortAmountLowLabel => 'ຈຳນວນເງິນ: ໜ້ອຍໄປຫຼາຍ';

  @override
  String get clearFiltersButton => 'ລ້າງການກັ່ນຕອງ';

  @override
  String get noMatchingTransactionsTitle => 'ບໍ່ພົບລາຍການທຸລະກຳທີ່ກົງກັນ';

  @override
  String get noMatchingTransactionsMessage =>
      'ລອງປັບການຄົ້ນຫາ ຫຼື ການກັ່ນຕອງຂອງທ່ານ.';

  @override
  String transferToLabel(String account) {
    return 'ໂອນໄປຫາ $account';
  }

  @override
  String transferFromLabel(String account) {
    return 'ຈາກ $account';
  }

  @override
  String get unknownAccountLabel => 'ບັນຊີບໍ່ຮູ້ຈັກ';

  @override
  String get uncategorizedLabel => 'ບໍ່ມີໝວດໝູ່';

  @override
  String get transactionFormEditTitle => 'ແກ້ໄຂລາຍການທຸລະກຳ';

  @override
  String get amountLabel => 'ຈຳນວນເງິນ';

  @override
  String get fromAccountLabel => 'ບັນຊີຕົ້ນທາງ';

  @override
  String get accountFieldLabel => 'ບັນຊີ';

  @override
  String get unavailableAccountLabel => 'ບັນຊີບໍ່ສາມາດໃຊ້ໄດ້ — ກະລຸນາເລືອກອື່ນ';

  @override
  String get pleaseSelectAccountError => 'ກະລຸນາເລືອກບັນຊີ.';

  @override
  String get toAccountLabel => 'ບັນຊີປາຍທາງ';

  @override
  String get pickFromAccountFirstMessage => 'ກະລຸນາເລືອກບັນຊີຕົ້ນທາງກ່ອນ';

  @override
  String get transferSameCurrencyHelperText =>
      'ຕ້ອງເປັນສະກຸນເງິນດຽວກັນກັບບັນຊີຕົ້ນທາງ';

  @override
  String get pleaseSelectDestinationAccountError => 'ກະລຸນາເລືອກບັນຊີປາຍທາງ.';

  @override
  String get cantTransferToSameAccountError => 'ບໍ່ສາມາດໂອນໄປບັນຊີດຽວກັນໄດ້.';

  @override
  String get transferSameCurrencyError =>
      'ຕ້ອງເປັນສະກຸນເງິນດຽວກັນກັບບັນຊີຕົ້ນທາງ.';

  @override
  String get categoryFieldLabel => 'ໝວດໝູ່';

  @override
  String get unavailableCategoryLabel =>
      'ໝວດໝູ່ບໍ່ສາມາດໃຊ້ໄດ້ — ກະລຸນາເລືອກອື່ນ';

  @override
  String get pleaseSelectCategoryError => 'ກະລຸນາເລືອກໝວດໝູ່.';

  @override
  String get dateLabel => 'ວັນທີ';

  @override
  String get noteOptionalLabel => 'ໝາຍເຫດ (ບໍ່ບັງຄັບ)';

  @override
  String get saveTransactionFailedMessage =>
      'ບໍ່ສາມາດບັນທຶກລາຍການທຸລະກຳໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String archivedSuffixFormat(String name) {
    return '$name (ເກັບຖາວອນ)';
  }

  @override
  String get reportsTitle => 'ລາຍງານ';

  @override
  String get exportReportTooltip => 'ສົ່ງອອກເປັນ CSV';

  @override
  String exportReportSubject(String month) {
    return 'ບົດລາຍງານ Cashly — $month';
  }

  @override
  String get exportReportFailedMessage =>
      'ບໍ່ສາມາດສົ່ງອອກບົດລາຍງານໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get convertedTotalsCardTitle => 'ຍອດລວມທີ່ແປງແລ້ວ';

  @override
  String convertedTotalsCaption(String currency) {
    return 'ຍອດລວມໂດຍປະມານຂອງທຸກສະກຸນເງິນ, ສະແດງເປັນ $currency.';
  }

  @override
  String convertedTotalsRatesAsOf(String date) {
    return 'ອັດຕາແລກປ່ຽນ ນັບແຕ່ $date · ອັດຕາໂດຍ ExchangeRate-API';
  }

  @override
  String convertedTotalsPartialWarning(String currencies) {
    return 'ບໍ່ລວມ $currencies — ບໍ່ມີອັດຕາແລກປ່ຽນ.';
  }

  @override
  String get nothingToReportYetTitle => 'ຍັງບໍ່ມີຫຍັງໃຫ້ລາຍງານ';

  @override
  String get nothingToReportYetMessage =>
      'ເມື່ອທ່ານບັນທຶກລາຍຮັບ ຫຼື ລາຍຈ່າຍສຳລັບເດືອນນີ້, ທ່ານຈະເຫັນສະຫຼຸບປະຈຳເດືອນ, ການແບ່ງແຍກລາຍຈ່າຍ ແລະ ແນວໂນ້ມຢູ່ບ່ອນນີ້.';

  @override
  String get incomeExpenseTrendSectionTitle => 'ແນວໂນ້ມລາຍຮັບ ແລະ ລາຍຈ່າຍ';

  @override
  String get spendingByCategorySectionTitle => 'ລາຍຈ່າຍຕາມໝວດໝູ່';

  @override
  String get budgetVsActualSectionTitle => 'ງົບປະມານທຽບກັບຕົວຈິງ';

  @override
  String get seeAllButton => 'ເບິ່ງທັງໝົດ';

  @override
  String get netLabel => 'ສຸດທິ';

  @override
  String get totalLabel => 'ລວມ';

  @override
  String monthIncomeExpenseSummaryMessage(
    String month,
    String income,
    String expense,
  ) {
    return '$month — ລາຍຮັບ $income, ລາຍຈ່າຍ $expense';
  }

  @override
  String get save => 'ບັນທຶກ';

  @override
  String get settingsTitle => 'ຕັ້ງຄ່າ';

  @override
  String get appearanceSectionTitle => 'ຮູບລັກສະນະ';

  @override
  String get themeLabel => 'ຮູບແບບ';

  @override
  String get themeSystemLabel => 'ລະບົບ';

  @override
  String get themeLightLabel => 'ສະຫວ່າງ';

  @override
  String get themeDarkLabel => 'ມືດ';

  @override
  String get themeUpdateFailedMessage => 'ບໍ່ສາມາດອັບເດດຮູບແບບຂອງທ່ານໄດ້.';

  @override
  String get securitySectionTitle => 'ຄວາມປອດໄພ';

  @override
  String get appLockToggleLabel => 'ລັອກແອັບ';

  @override
  String get appLockToggleHelperMessage =>
      'ຕ້ອງໃຊ້ລາຍນິ້ວມື, ໃບໜ້າ, ຫຼື ລະຫັດ PIN ຂອງອຸປະກອນເພື່ອເປີດ Cashly.';

  @override
  String get appLockUnsupportedMessage =>
      'ຕັ້ງຄ່າລາຍນິ້ວມື, ປົດລັອກໃບໜ້າ, ຫຼື ລັອກໜ້າຈໍໃນອຸປະກອນນີ້ເພື່ອໃຊ້ການລັອກແອັບ.';

  @override
  String get appLockUpdateFailedMessage =>
      'ບໍ່ສາມາດອັບເດດການລັອກແອັບໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get disableAppLockTitle => 'ປິດການລັອກແອັບບໍ?';

  @override
  String get disableAppLockMessage =>
      'ຜູ້ທີ່ສາມາດເຂົ້າເຖິງອຸປະກອນຂອງທ່ານຈະສາມາດເປີດ Cashly ໄດ້ໂດຍບໍ່ຕ້ອງຢືນຢັນຕົວຕົນ.';

  @override
  String get turnOffButton => 'ປິດ';

  @override
  String get securityUnavailableOnWebMessage =>
      'ການລັອກແອັບ ແລະ ການແຈ້ງເຕືອນບໍ່ສາມາດໃຊ້ໄດ້ໃນເວັບແອັບ. ກະລຸນາໃຊ້ແອັບມືຖືເພື່ອຈັດການ.';

  @override
  String get appLockTitle => 'Cashly ຖືກລັອກ';

  @override
  String get appLockReasonMessage => 'ຢືນຢັນຕົວຕົນເພື່ອເປີດ Cashly';

  @override
  String get appLockFailedMessage =>
      'ການຢືນຢັນຕົວຕົນລົ້ມເຫຼວ. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get appLockUnavailableMessage =>
      'ການຢືນຢັນຕົວຕົນບໍ່ສາມາດໃຊ້ໄດ້ໃນຕອນນີ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get appLockUnlockButton => 'ປົດລັອກ';

  @override
  String get notificationsSectionTitle => 'ການແຈ້ງເຕືອນ';

  @override
  String get notificationsToggleLabel => 'ການແຈ້ງເຕືອນງົບປະມານ ແລະ ຍອດເງິນ';

  @override
  String get notificationsToggleHelperMessage =>
      'ຮັບການແຈ້ງເຕືອນເມື່ອງົບປະມານເກີນຂອບເຂດ, ຍອດເງິນບັນຊີຕິດລົບ, ຫຼື ເຖິງກຳນົດຝາກເງິນເຂົ້າເປົ້າໝາຍການເກັບເງິນ — ເຖິງແມ່ນຕອນທີ່ບໍ່ໄດ້ເປີດແອັບ Cashly ຢູ່ກໍ່ຕາມ.';

  @override
  String get notificationsUpdateFailedMessage =>
      'ບໍ່ສາມາດອັບເດດການແຈ້ງເຕືອນໄດ້. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get notificationsPermissionDeniedMessage =>
      'ການແຈ້ງເຕືອນສຳລັບ Cashly ຖືກປິດຢູ່ໃນການຕັ້ງຄ່າອຸປະກອນຂອງທ່ານ.';

  @override
  String get budgetExceededNotificationTitle => 'ງົບປະມານເກີນຂອບເຂດ';

  @override
  String budgetExceededNotificationBody(String category) {
    return 'ທ່ານໃຊ້ຈ່າຍເກີນງົບປະມານ $category ສຳລັບເດືອນນີ້ແລ້ວ.';
  }

  @override
  String get negativeBalanceNotificationTitle => 'ຍອດເງິນບັນຊີຕິດລົບ';

  @override
  String negativeBalanceNotificationBody(String account) {
    return 'ຍອດເງິນບັນຊີ $account ຂອງທ່ານຕິດລົບແລ້ວ.';
  }

  @override
  String get goalReminderNotificationTitle => 'ແຈ້ງເຕືອນເປົ້າໝາຍການເກັບເງິນ';

  @override
  String goalReminderNotificationBody(String frequency, String goalName) {
    return 'ເຖິງເວລາຝາກເງິນ $frequency ເຂົ້າ \"$goalName\" ຂອງທ່ານແລ້ວ.';
  }

  @override
  String get defaultsSectionTitle => 'ຄ່າເລີ່ມຕົ້ນ';

  @override
  String get defaultCurrencyLabel => 'ສະກຸນເງິນເລີ່ມຕົ້ນ';

  @override
  String get defaultCurrencyHelperMessage =>
      'ໃຊ້ເພື່ອເລືອກສະກຸນເງິນລ່ວງໜ້າເມື່ອທ່ານສ້າງບັນຊີ ຫຼື ງົບປະມານໃໝ່.';

  @override
  String get defaultCurrencyUpdateFailedMessage =>
      'ບໍ່ສາມາດອັບເດດສະກຸນເງິນເລີ່ມຕົ້ນຂອງທ່ານໄດ້.';

  @override
  String currencyDisplayFormat(String code, String name) {
    return '$code — $name';
  }

  @override
  String get accountSectionTitle => 'ບັນຊີ';

  @override
  String get manageAccountLabel => 'ຈັດການບັນຊີຂອງທ່ານ';

  @override
  String get manageAccountHelperMessage => 'ຊື່, ອີເມວ, ແລະ ການລຶບບັນຊີ.';

  @override
  String get aboutSectionTitle => 'ກ່ຽວກັບ';

  @override
  String appVersionLabel(String version) {
    return 'ເວີຊັນ $version';
  }

  @override
  String get privacyPolicyLabel => 'ນະໂຍບາຍຄວາມເປັນສ່ວນຕົວ';

  @override
  String get termsOfServiceLabel => 'ເງື່ອນໄຂການໃຫ້ບໍລິການ';

  @override
  String get profileTitle => 'ໂປຣໄຟລ໌';

  @override
  String get editNameDialogTitle => 'ແກ້ໄຂຊື່';

  @override
  String get nameUpdatedMessage => 'ອັບເດດຊື່ແລ້ວ.';

  @override
  String get nameUpdateFailedMessage => 'ບໍ່ສາມາດອັບເດດຊື່ຂອງທ່ານໄດ້.';

  @override
  String get deleteUserAccountTitle => 'ລຶບບັນຊີ?';

  @override
  String get deleteUserAccountMessageWithPassword =>
      'ການດຳເນີນການນີ້ຈະລຶບບັນຊີ ແລະ ຂໍ້ມູນທັງໝົດຂອງທ່ານຢ່າງຖາວອນ — ບັນຊີ, ລາຍການທຸລະກຳ, ໝວດໝູ່ ແລະ ງົບປະມານ. ບໍ່ສາມາດຍົກເລີກໄດ້.';

  @override
  String get deleteUserAccountMessageGoogle =>
      'ການດຳເນີນການນີ້ຈະລຶບບັນຊີ ແລະ ຂໍ້ມູນທັງໝົດຂອງທ່ານຢ່າງຖາວອນ — ບັນຊີ, ລາຍການທຸລະກຳ, ໝວດໝູ່ ແລະ ງົບປະມານ. ບໍ່ສາມາດຍົກເລີກໄດ້. ທ່ານຈະຖືກຂໍໃຫ້ຢືນຢັນກັບ Google ໃນຂັ້ນຕອນຕໍ່ໄປ.';

  @override
  String get confirmYourPasswordLabel => 'ຢືນຢັນລະຫັດຜ່ານຂອງທ່ານ';

  @override
  String get deleteAccountConfirmButton => 'ລຶບບັນຊີ';

  @override
  String get deleteUserAccountFailedMessage => 'ບໍ່ສາມາດລຶບບັນຊີຂອງທ່ານໄດ້.';

  @override
  String get addYourNameLabel => 'ເພີ່ມຊື່ຂອງທ່ານ';

  @override
  String get emailVerifiedLabel => 'ອີເມວຢືນຢັນແລ້ວ';

  @override
  String get notVerifiedLabel => 'ຍັງບໍ່ໄດ້ຢືນຢັນ';

  @override
  String get memberSinceLabel => 'ສະມາຊິກຕັ້ງແຕ່';

  @override
  String get deleteAccountButtonLabel => 'ລຶບບັນຊີ';

  @override
  String get iconLabel => 'ໄອຄອນ';

  @override
  String get colorLabel => 'ສີ';

  @override
  String get smartMoneyScoreCardTitle => 'ຄະແນນການເງິນອັດສະລິຍະ Cashly';

  @override
  String get smartMoneyScoreCardSubtitle =>
      'ການເໜັງເໜືອຍອດເງິນນຳພາ. ພຶດຕິກຳໃຫ້ບໍລິບົດ.';

  @override
  String get smartMoneyScoreWhatIsShapingLabel =>
      'ສິ່ງທີ່ກຳລັງສ້າງຜົນກະທົບໃນເດືອນນີ້';

  @override
  String get smartMoneyScorePracticalNextStepLabel =>
      'ຂັ້ນຕອນຕໍ່ໄປທີ່ປະຕິບັດໄດ້';

  @override
  String get smartMoneyScoreWhyThisScore => 'ເປັນຫຍັງຈຶ່ງໄດ້ຄະແນນນີ້?';

  @override
  String get smartMoneyScoreComparedWithOpening =>
      'ທຽບກັບຍອດເງິນເປີດເດືອນຂອງທ່ານ';

  @override
  String get smartMoneyScoreNeutralBaseline =>
      'ນຳໃຊ້ພື້ນຖານເປັນກາງຈົນກວ່າຈະມີຂໍ້ມູນພຽງພໍ';

  @override
  String smartMoneyScoreMonthlyHeroLabel(int max) {
    return 'ຄະແນນລາຍເດືອນ · / $max';
  }

  @override
  String get smartMoneyScoreStatusNotEnoughData => 'ຂໍ້ມູນບໍ່ພຽງພໍ';

  @override
  String get smartMoneyScoreStatusExcellentGrowth => 'ການເຕີບໂຕດີເລີດ';

  @override
  String get smartMoneyScoreStatusGrowing => 'ກຳລັງເຕີບໂຕ';

  @override
  String get smartMoneyScoreStatusStable => 'ຄົງທີ່';

  @override
  String get smartMoneyScoreStatusDeclining => 'ຫຼຸດລົງ';

  @override
  String get smartMoneyScoreStatusNeedsAttention => 'ຕ້ອງການຄວາມສົນໃຈ';

  @override
  String get smartMoneyScoreStatusExcellent => 'ດີເລີດ';

  @override
  String get smartMoneyScoreStatusGood => 'ດີ';

  @override
  String get smartMoneyScoreStatusFair => 'ພໍໃຊ້';

  @override
  String get smartMoneyScoreStatusHighRisk => 'ຄວາມສ່ຽງສູງ';

  @override
  String get financialInsightPeriodToday => 'ມື້ນີ້';

  @override
  String get financialInsightPeriodWeek => 'ອາທິດ';

  @override
  String get financialInsightPeriodMonth => 'ເດືອນ';

  @override
  String get smartMoneyScoreBudgetNoneSet => 'ຍັງບໍ່ໄດ້ຕັ້ງງົບປະມານ';

  @override
  String smartMoneyScoreBudgetOverCount(int count) {
    return '$count ເກີນງົບປະມານ';
  }

  @override
  String smartMoneyScoreBudgetNearlyFullCount(int count) {
    return '$count ໃກ້ເຕັມ';
  }

  @override
  String get smartMoneyScoreBudgetOnTrack => 'ຕາມແຜນ';

  @override
  String get smartMoneyScoreBreakdownSheetDescription =>
      'ຄະແນນລາຍເດືອນຄຳນວນຈາກຂໍ້ມູນການເງິນຊຸດດຽວກັນກັບທີ່ສະແດງຢູ່ໜ້າຫຼັກຂອງທ່ານ. ການເໜັງເໜືອຍອດເງິນແມ່ນປັດໄຈຫຼັກສະເໝີ.';

  @override
  String get smartMoneyScoreBreakdownUnavailableFallback =>
      'Cashly ຕ້ອງການຍອດເງິນເປີດເດືອນທີ່ໜ້າເຊື່ອຖືກ່ອນຈຶ່ງຈະປຽບທຽບໄດ້ຢ່າງເຕັມທີ່. ຄະແນນຈະຄົງເປັນກາງແທນທີ່ຈະຄາດເດົາ.';

  @override
  String get smartMoneyScoreSectionBalanceMovement => 'ການເໜັງເໜືອຍອດເງິນ';

  @override
  String get smartMoneyScoreSectionMonthActivity => 'ກິດຈະກຳການເງິນຂອງເດືອນນີ້';

  @override
  String get smartMoneyScoreSectionFormula => 'ສູດຄຳນວນ';

  @override
  String get smartMoneyScoreRowOpeningBalance => 'ຍອດເງິນເປີດ';

  @override
  String get smartMoneyScoreRowCurrentBalance => 'ຍອດເງິນປັດຈຸບັນ';

  @override
  String get smartMoneyScoreRowBalanceChange => 'ການປ່ຽນແປງຍອດເງິນ';

  @override
  String get smartMoneyScoreRowBalanceGrowthContribution =>
      'ການປະກອບສ່ວນຂອງການເຕີບໂຕຍອດເງິນ';

  @override
  String get smartMoneyScoreRowIncome => 'ລາຍຮັບ';

  @override
  String get smartMoneyScoreRowExpenses => 'ລາຍຈ່າຍ';

  @override
  String get smartMoneyScoreRowNetCashFlowSavings =>
      'ກະແສເງິນສົດສຸດທິ / ເງິນອອມ';

  @override
  String get smartMoneyScoreRowBudgetPerformance => 'ຜົນງານງົບປະມານ';

  @override
  String get smartMoneyScoreRowPreviousPeriodComparison =>
      'ການປຽບທຽບກັບໄລຍະກ່ອນ';

  @override
  String get smartMoneyScoreRowOverdueBills => 'ໃບບິນຄ້າງຈ່າຍ';

  @override
  String get smartMoneyScoreRowStartingScore => 'ຄະແນນເລີ່ມຕົ້ນ';

  @override
  String get smartMoneyScoreRowBehaviourModifier => 'ຕົວປັບພຶດຕິກຳ';

  @override
  String get smartMoneyScoreRowFinalMonthlyScore => 'ຄະແນນລາຍເດືອນສຸດທ້າຍ';

  @override
  String get smartMoneyScoreValueNotIncludedYet => 'ຍັງບໍ່ໄດ້ລວມ';

  @override
  String get smartMoneyScoreValueNeutralUntilBaseline =>
      'ເປັນກາງຈົນກວ່າຈະມີພື້ນຖານ';

  @override
  String smartMoneyScoreValueBehaviourModifierPoints(String points) {
    return '$points ຄະແນນ (ຈຳກັດທີ່ ±10)';
  }

  @override
  String smartMoneyScorePointsSuffix(String points) {
    return '$points ຄະແນນ';
  }

  @override
  String get smartMoneyScoreValueNoComparisonYet => 'ຍັງບໍ່ມີການປຽບທຽບ';

  @override
  String get smartMoneyScoreImpactIncomePositive => 'ລາຍຮັບນຳໜ້າລາຍຈ່າຍ.';

  @override
  String get smartMoneyScoreImpactIncomeNegative => 'ລາຍຈ່າຍນຳໜ້າລາຍຮັບ.';

  @override
  String get smartMoneyScoreImpactIncomeNeutral =>
      'ລາຍຮັບ ແລະ ລາຍຈ່າຍປັດຈຸບັນເທົ່າກັນ ຫຼື ບໍ່ມີຂໍ້ມູນ.';

  @override
  String get smartMoneyScoreImpactSavingsPositive =>
      'ກະແສເງິນສົດເປັນບວກຊ່ວຍໜູນຄະແນນ.';

  @override
  String get smartMoneyScoreImpactSavingsNegative =>
      'ກະແສເງິນສົດເປັນລົບຫຼຸດຕົວປັບພຶດຕິກຳເລັກນ້ອຍ.';

  @override
  String get smartMoneyScoreImpactSavingsNeutral =>
      'ບໍ່ໄດ້ນຳໃຊ້ຕົວປັບກະແສເງິນສົດ.';

  @override
  String get smartMoneyScoreImpactBudgetPositive =>
      'ງົບປະມານປັດຈຸບັນຍັງຄົງຕາມແຜນ.';

  @override
  String get smartMoneyScoreImpactBudgetNegative =>
      'ພື້ນທີ່ງົບປະມານແໜ້ນ ຫຼື ເກີນງົບປະມານ.';

  @override
  String get smartMoneyScoreImpactBudgetNeutral => 'ບໍ່ໄດ້ນຳໃຊ້ຕົວປັບງົບປະມານ.';

  @override
  String get smartMoneyScoreImpactTrendPositive =>
      'ການໃຊ້ຈ່າຍຕ່ຳກວ່າໄລຍະທຽບເທົ່າ.';

  @override
  String get smartMoneyScoreImpactTrendNegative =>
      'ການໃຊ້ຈ່າຍສູງກວ່າໄລຍະທຽບເທົ່າຢ່າງເຫັນໄດ້ຊັດ.';

  @override
  String get smartMoneyScoreImpactTrendNeutral =>
      'ຍັງບໍ່ມີຂໍ້ມູນການໃຊ້ຈ່າຍທຽບເທົ່າພຽງພໍ.';

  @override
  String get smartMoneyScoreImpactBillsSupporting =>
      'ບໍ່ມີບັນທຶກໃບບິນ ຫຼື ການແຈ້ງເຕືອນທີ່ຢືນຢັນແລ້ວ, ດັ່ງນັ້ນຈຶ່ງບໍ່ໄດ້ຫັກຄະແນນໃບບິນ.';

  @override
  String get smartMoneyScoreMetricNetCashFlow => 'ກະແສເງິນສົດສຸດທິ';

  @override
  String get smartMoneyScoreMetricComparedLastMonth => 'ທຽບກັບເດືອນກ່ອນ';

  @override
  String smartMoneyScoreMetricExpensesChange(String percent) {
    return '$percent ລາຍຈ່າຍ';
  }

  @override
  String get smartMoneyScoreFormulaFootnote =>
      'ຄະແນນລາຍເດືອນ = clamp(0–150, 100 + % ການປ່ຽນແປງຍອດເງິນ + ຕົວປັບພຶດຕິກຳການເງິນ).';

  @override
  String get financialInsightMsgSteadySpendingHeadline =>
      'ການໃຊ້ຈ່າຍຂອງທ່ານມື້ນີ້ຄົງທີ່ດີ.';

  @override
  String get financialInsightMsgSteadySpendingExplanation =>
      'ສືບຕໍ່ບັນທຶກລາຍການທຸລະກຳ ແລ້ວ Cashly ຈະເຮັດໃຫ້ແຕ່ລະຄວາມເຂົ້າໃຈເປັນສ່ວນຕົວຫຼາຍຂຶ້ນ.';

  @override
  String get financialInsightMsgNegativeBalanceHeadline =>
      'ຍອດເງິນລວມຂອງທ່ານຕ່ຳກວ່າສູນ.';

  @override
  String financialInsightMsgNegativeBalanceExplanation(
    String currency,
    String amount,
  ) {
    return 'ຍອດເງິນລວມ $currency ຂອງທ່ານແມ່ນ $amount. ການເຮັດໃຫ້ຍອດຂາດນັ້ນກັບຄືນເປັນບວກແມ່ນຂັ້ນຕອນຕໍ່ໄປທີ່ຊັດເຈນທີ່ສຸດ.';
  }

  @override
  String get financialInsightMsgPlanEssentialExpenseTitle =>
      'ວາງແຜນລາຍຈ່າຍທີ່ຈຳເປັນຕໍ່ໄປກ່ອນ';

  @override
  String get financialInsightMsgPlanEssentialExpenseDetail =>
      'ການເນັ້ນໃສ່ລາຍຈ່າຍທີ່ຈຳເປັນເທື່ອລະອັນຊ່ວຍສ້າງເງິນສະຫງວນທີ່ເປັນບວກຄືນ ໂດຍບໍ່ຕັດສິນທາງເລືອກທີ່ຜ່ານມາ.';

  @override
  String financialInsightMsgCategoryOverBudgetHeadline(String category) {
    return '$category ເກີນງົບປະມານປະຈຳເດືອນແລ້ວ.';
  }

  @override
  String financialInsightMsgCategoryOverBudgetExplanation(
    String spent,
    String limit,
  ) {
    return 'ທ່ານໄດ້ໃຊ້ຈ່າຍ $spent ຈາກແຜນ $limit.';
  }

  @override
  String financialInsightMsgPauseCategorySpendingTitle(String category) {
    return 'ຢຸດການໃຊ້ຈ່າຍ $category ສຳລັບມື້ນີ້';
  }

  @override
  String get financialInsightMsgPauseCategorySpendingDetail =>
      'ການຢຸດພັກສັ້ນໆຊ່ວຍປົກປ້ອງແຜນທີ່ເຫຼືອຂອງເດືອນນີ້ ໂດຍບໍ່ຕັດສິນທາງເລືອກທີ່ຜ່ານມາ.';

  @override
  String financialInsightMsgCategoryNeedsRoomHeadline(String category) {
    return '$category ຕ້ອງການພື້ນທີ່ເລັກນ້ອຍໃນເດືອນນີ້.';
  }

  @override
  String financialInsightMsgCategoryNeedsRoomExplanation(
    String percent,
    String limit,
  ) {
    return 'ທ່ານໄດ້ໃຊ້ $percent ຂອງງົບປະມານ $limit.';
  }

  @override
  String financialInsightMsgSetRestOfMonthLimitTitle(String category) {
    return 'ຕັ້ງຂີດຈຳກັດສ່ວນທີ່ເຫຼືອຂອງເດືອນສຳລັບ $category';
  }

  @override
  String financialInsightMsgSetRestOfMonthLimitDetail(String remaining) {
    return 'ການຮັກສາການຊື້ຄັ້ງຕໍ່ໄປພາຍໃນ $remaining ຈະຮັກສາງົບປະມານນີ້ໃຫ້ຢູ່ໃນແຜນ.';
  }

  @override
  String financialInsightMsgCategoryHigherThanUsualHeadline(String category) {
    return '$category ສູງກວ່າອັດຕາປົກກະຕິຂອງທ່ານ.';
  }

  @override
  String financialInsightMsgCategoryHigherThanUsualExplanation(
    String changePercent,
  ) {
    return 'ມັນສູງກວ່າໄລຍະທຽບເທົ່າ $changePercent ດັ່ງນັ້ນຄວນກວດເບິ່ງໄວໆ.';
  }

  @override
  String financialInsightMsgReviewNextCategoryPurchaseTitle(String category) {
    return 'ກວດສອບການຊື້ $category ຄັ້ງຕໍ່ໄປຂອງທ່ານ';
  }

  @override
  String get financialInsightMsgReviewNextCategoryPurchaseDetail =>
      'ການປ່ຽນແທນ ຫຼື ຊັກຊ້າເລັກນ້ອຍສາມາດຫຼຸດຜ່ອນການເພີ່ມຂຶ້ນນີ້ ໃນຂະນະທີ່ທ່ານຕັດສິນໃຈວ່າມັນເປັນຄັ້ງດຽວຫຼືບໍ່.';

  @override
  String get financialInsightMsgTodaySpendingFasterHeadline =>
      'ມື້ນີ້ໃຊ້ຈ່າຍໄວກວ່າອັດຕາຂອງອາທິດນີ້.';

  @override
  String get financialInsightMsgTodaySpendingFasterExplanation =>
      'ມັນສາມາດເກີດຂຶ້ນໄດ້ — ການກວດເບິ່ງຢ່າງຕັ້ງໃຈກ່ອນການຊື້ຄັ້ງຕໍ່ໄປຈະຮັກສາການຄວບຄຸມມື້ນີ້ໄວ້.';

  @override
  String get financialInsightMsgCheckNextExpenseTitle =>
      'ກວດເບິ່ງລາຍຈ່າຍຄັ້ງຕໍ່ໄປກ່ອນຊື້';

  @override
  String get financialInsightMsgCheckNextExpenseDetail =>
      'ການຢຸດພັກໄວໆສາມາດຮັກສາມື້ນີ້ໃຫ້ໃກ້ຄຽງອັດຕາປົກກະຕິ ໂດຍບໍ່ປ່ຽນແປງສິ່ງທີ່ເກີດຂຶ້ນແລ້ວ.';

  @override
  String get financialInsightMsgSpendingAheadOfIncomeHeadline =>
      'ການໃຊ້ຈ່າຍຂອງເດືອນນີ້ນຳໜ້າລາຍຮັບຈົນຮອດຕອນນີ້.';

  @override
  String get financialInsightMsgSpendingAheadOfIncomeExplanation =>
      'ນີ້ແມ່ນແນວໂນ້ມທີ່ຄວນຕິດຕາມ ບໍ່ແມ່ນຄຳຕັດສິນ — ທາງເລືອກຕັ້ງໃຈໜຶ່ງ ຫຼື ສອງຢ່າງຍັງສາມາດປ່ຽນເດືອນນີ້ໄດ້.';

  @override
  String get financialInsightMsgChooseLowPriorityExpenseTitle =>
      'ເລືອກລາຍຈ່າຍທີ່ບໍ່ສຳຄັນໜຶ່ງອັນເພື່ອຊັກຊ້າ';

  @override
  String get financialInsightMsgChooseLowPriorityExpenseDetail =>
      'ເນັ້ນໃສ່ທາງເລືອກຕໍ່ໄປເທົ່ານັ້ນ; ການຫຼຸດຄ່າໃຊ້ຈ່າຍທີ່ປັບໄດ້ໜຶ່ງອັນສາມາດເຮັດໃຫ້ເດືອນນີ້ດຸ່ນດ່ຽງຂຶ້ນ.';

  @override
  String get financialInsightMsgBalanceZeroHeadline =>
      'ຍອດເງິນທີ່ໃຊ້ໄດ້ຂອງທ່ານແມ່ນສູນ.';

  @override
  String get financialInsightMsgBalanceThinHeadline =>
      'ເງິນສະຫງວນຍອດເງິນຂອງທ່ານກຳລັງແໜ້ນ.';

  @override
  String get financialInsightMsgBalanceLimitedHeadline =>
      'ຍອດເງິນຂອງທ່ານຕ້ອງການພື້ນທີ່ເພີ່ມເຕີມເລັກນ້ອຍ.';

  @override
  String get financialInsightMsgBalanceSteadyHeadline =>
      'ຍອດເງິນຂອງທ່ານຄົງທີ່ດີ.';

  @override
  String financialInsightMsgBalanceZeroExplanation(String currency) {
    return 'ບໍ່ມີເງິນສະຫງວນ $currency ເຫຼືອຢູ່ຫຼັງຈາກກິດຈະກຳຫຼ້າສຸດ. ການເລືອກລາຍຈ່າຍຕໍ່ໄປຢ່າງລະມັດລະວັງຊ່ວຍສ້າງພື້ນທີ່ຄືນໄດ້.';
  }

  @override
  String financialInsightMsgBalanceThinExplanation(String currency, int days) {
    return 'ຕາມອັດຕາການໃຊ້ຈ່າຍຫຼ້າສຸດຂອງທ່ານ ຍອດເງິນ $currency ນີ້ຄຸ້ມຄອງປະມານ $days ມື້. ການປົກປ້ອງລາຍຈ່າຍທີ່ຈຳເປັນໜຶ່ງອັນກ່ອນຈະຊ່ວຍໄດ້.';
  }

  @override
  String financialInsightMsgBalanceLimitedExplanation(
    String currency,
    int days,
  ) {
    return 'ຕາມອັດຕາການໃຊ້ຈ່າຍຫຼ້າສຸດຂອງທ່ານ ຍອດເງິນ $currency ນີ້ຄຸ້ມຄອງປະມານ $days ມື້. ແຜນສ່ວນທີ່ເຫຼືອຂອງອາທິດແບບນ້ອຍໆສາມາດຮັກສາພື້ນທີ່ນັ້ນໄວ້.';
  }

  @override
  String get financialInsightMsgBalanceSteadyExplanation =>
      'ຍອດເງິນຂອງທ່ານກຳລັງຮອງຮັບອັດຕາປັດຈຸບັນ.';

  @override
  String get financialInsightMsgProtectEssentialExpenseTitle =>
      'ປົກປ້ອງລາຍຈ່າຍທີ່ຈຳເປັນຕໍ່ໄປ';

  @override
  String get financialInsightMsgProtectEssentialExpenseDetail =>
      'ການເລືອກຄ່າໃຊ້ຈ່າຍທີ່ຈຳເປັນຕໍ່ໄປກ່ອນຊ່ວຍສ້າງພື້ນທີ່ກ່ອນເພີ່ມສິ່ງທີ່ບໍ່ຈຳເປັນ.';

  @override
  String financialInsightMsgReserveNextDaysTitle(int days) {
    return 'ສະຫງວນສິ່ງຈຳເປັນສຳລັບ $days ມື້ຕໍ່ໄປ';
  }

  @override
  String get financialInsightMsgReserveNextDaysDetail =>
      'ການຮັກສາເງິນສະຫງວນນ້ອຍນັ້ນສຳລັບຄວາມຈຳເປັນກ່ອນ ໃຫ້ຍອດເງິນຂອງທ່ານມີພື້ນທີ່ຟື້ນຕົວຫຼາຍຂຶ້ນ.';

  @override
  String get financialInsightMsgSetShortRestOfWeekLimitTitle =>
      'ຕັ້ງຂີດຈຳກັດສ່ວນທີ່ເຫຼືອຂອງອາທິດແບບສັ້ນ';

  @override
  String get financialInsightMsgSetShortRestOfWeekLimitDetail =>
      'ຂີດຈຳກັດນ້ອຍໆສຳລັບການໃຊ້ຈ່າຍທີ່ປັບໄດ້ຊ່ວຍໃຫ້ຍອດເງິນປັດຈຸບັນຂອງທ່ານໃຊ້ໄດ້ດົນຂຶ້ນ.';

  @override
  String get financialInsightMsgKeepExpenseIntentionalTitle =>
      'ຮັກສາລາຍຈ່າຍຕໍ່ໄປຂອງທ່ານໃຫ້ຕັ້ງໃຈ';

  @override
  String get financialInsightMsgKeepExpenseIntentionalBalanceDetail =>
      'ຍອດເງິນຂອງທ່ານກຳລັງຮອງຮັບອັດຕາປັດຈຸບັນ. ການກວດເບິ່ງໄວໆກ່ອນໃຊ້ຈ່າຍຊ່ວຍໃຫ້ມັນຄົງຢູ່ແບບນັ້ນ.';

  @override
  String get financialInsightMsgKeepExpenseIntentionalPaceDetail =>
      'ອັດຕາປັດຈຸບັນຂອງທ່ານແມ່ນດີ. ການກວດເບິ່ງໄວໆກ່ອນຊື້ຊ່ວຍໃຫ້ມັນຄົງຢູ່ແບບນັ້ນ.';

  @override
  String get financialInsightMsgOnboardingHeadline =>
      'ມາສ້າງຮູບແບບການໃຊ້ຈ່າຍທຳອິດຂອງທ່ານກັນ.';

  @override
  String get financialInsightMsgOnboardingExplanation =>
      'ເພີ່ມລາຍການລາຍຮັບ ຫຼື ລາຍຈ່າຍສອງສາມລາຍການ ແລ້ວ Cashly ຈະປ່ຽນມັນເປັນການກວດເບິ່ງປະຈຳວັນ, ອາທິດ, ແລະ ເດືອນສ່ວນຕົວ.';

  @override
  String get financialInsightMsgLogNextExpenseTitle =>
      'ບັນທຶກລາຍຈ່າຍຕໍ່ໄປຂອງທ່ານ';

  @override
  String get financialInsightMsgLogNextExpenseDetail =>
      'ແມ່ນແຕ່ການຊື້ປະຈຳວັນນ້ອຍໆກໍ່ໃຫ້ຈຸດເລີ່ມຕົ້ນທີ່ດີກວ່າແກ່ຜູ້ຊ່ວຍ.';

  @override
  String get financialInsightMsgNotEnoughActivityTodayReason =>
      'ຍັງບໍ່ມີກິດຈະກຳຫຼ້າສຸດພຽງພໍທີ່ຈະໃຫ້ຄະແນນແນວໂນ້ມມື້ນີ້.';

  @override
  String get financialInsightMsgNotEnoughActivityWeekReason =>
      'ຍັງບໍ່ມີກິດຈະກຳຫຼ້າສຸດພຽງພໍທີ່ຈະໃຫ້ຄະແນນແນວໂນ້ມອາທິດນີ້.';

  @override
  String get financialInsightMsgNotEnoughActivityMonthReason =>
      'ຍັງບໍ່ມີກິດຈະກຳຫຼ້າສຸດພຽງພໍທີ່ຈະໃຫ້ຄະແນນແນວໂນ້ມເດືອນນີ້.';

  @override
  String financialInsightMsgBalanceImpactNegativeReason(String currency) {
    return 'ຍອດເງິນລວມ $currency ຂອງທ່ານຕ່ຳກວ່າສູນ ດັ່ງນັ້ນການສ້າງເງິນສະຫງວນທີ່ເປັນບວກຄືນແມ່ນບູລິມະສິດ.';
  }

  @override
  String financialInsightMsgBalanceImpactEmptyReason(String currency) {
    return 'ຍອດເງິນ $currency ທີ່ໃຊ້ງານຂອງທ່ານແມ່ນສູນຫຼັງຈາກກິດຈະກຳຫຼ້າສຸດ.';
  }

  @override
  String financialInsightMsgBalanceImpactLowReason(String currency, int days) {
    return 'ຍອດເງິນລວມ $currency ຂອງທ່ານຄຸ້ມຄອງປະມານ $days ມື້ຕາມອັດຕາການໃຊ້ຈ່າຍຫຼ້າສຸດ.';
  }

  @override
  String financialInsightMsgBalanceImpactHealthyReason(String currency) {
    return 'ຍອດເງິນລວມ $currency ຂອງທ່ານຄຸ້ມຄອງຫຼາຍກວ່າໜຶ່ງເດືອນຕາມອັດຕາການໃຊ້ຈ່າຍຫຼ້າສຸດ.';
  }

  @override
  String financialInsightMsgCategoryOverBudgetReasonToday(String category) {
    return '$category ເກີນງົບປະມານປະຈຳເດືອນແລ້ວ.';
  }

  @override
  String financialInsightMsgCategoryNearBudgetReasonToday(String category) {
    return '$category ມີພື້ນທີ່ງົບປະມານເຫຼືອໜ້ອຍໃນເດືອນນີ້.';
  }

  @override
  String get financialInsightMsgTodaySpikeReason =>
      'ການໃຊ້ຈ່າຍມື້ນີ້ຫຼາຍກວ່າສອງເທົ່າຂອງອັດຕາປະຈຳວັນກ່ອນໜ້າຂອງອາທິດນີ້.';

  @override
  String financialInsightMsgTodayComparableIncreaseReason(
    String changePercent,
  ) {
    return 'ການໃຊ້ຈ່າຍມື້ນີ້ສູງກວ່າຍອດລວມທຽບເທົ່າຂອງມື້ວານ $changePercent.';
  }

  @override
  String get financialInsightMsgNoActivityTodayReason =>
      'ບໍ່ມີການບັນທຶກລາຍຮັບ ຫຼື ລາຍຈ່າຍໃນມື້ນີ້.';

  @override
  String get financialInsightMsgIncomeCoversTodayReason =>
      'ລາຍຮັບທີ່ບັນທຶກມື້ນີ້ຄຸ້ມຄອງການໃຊ້ຈ່າຍມື້ນີ້.';

  @override
  String financialInsightMsgCategoryOverBudgetReasonWeek(String category) {
    return '$category ເກີນງົບປະມານ ດັ່ງນັ້ນອາທິດນີ້ຕ້ອງການອັດຕາທີ່ຊ້າລົງ.';
  }

  @override
  String financialInsightMsgCategoryNearBudgetReasonWeek(String category) {
    return '$category ໃກ້ຮອດຂີດຈຳກັດປະຈຳເດືອນແລ້ວ.';
  }

  @override
  String financialInsightMsgCategoryPacedBudgetReasonWeek(String category) {
    return '$category ນຳໜ້າອັດຕາປະຈຳເດືອນທີ່ຄາດໄວ້.';
  }

  @override
  String financialInsightMsgWeeklyCategorySpikeReason(
    String category,
    String changePercent,
  ) {
    return '$category ສູງກວ່າອາທິດທຽບເທົ່າ $changePercent.';
  }

  @override
  String financialInsightMsgWeekComparableIncreaseReason(String changePercent) {
    return 'ການໃຊ້ຈ່າຍອາທິດນີ້ສູງກວ່າຍອດລວມທຽບເທົ່າຂອງອາທິດກ່ອນ $changePercent.';
  }

  @override
  String get financialInsightMsgWeekComparableDecreaseReason =>
      'ອາທິດນີ້ໃຊ້ຈ່າຍໜ້ອຍກວ່າອາທິດທຽບເທົ່າກ່ອນໜ້າ.';

  @override
  String financialInsightMsgCategoryOverBudgetReasonMonth(
    String category,
    String percent,
  ) {
    return '$category ເກີນງົບປະມານ $percent.';
  }

  @override
  String financialInsightMsgCategoryNearBudgetReasonMonth(
    String category,
    String remaining,
  ) {
    return '$category ມີ $remaining ເຫຼືອຢູ່.';
  }

  @override
  String financialInsightMsgCategoryPacedBudgetReasonMonth(String category) {
    return '$category ໃຊ້ຈ່າຍໄວກວ່າແຜນປະຈຳເດືອນ.';
  }

  @override
  String financialInsightMsgSpendingOverIncomeReasonMonth(
    String expense,
    String income,
  ) {
    return 'ການໃຊ້ຈ່າຍນັບແຕ່ຕົ້ນເດືອນແມ່ນ $expense ທຽບກັບລາຍຮັບ $income.';
  }

  @override
  String get financialInsightMsgIncomeCoversMonthReason =>
      'ລາຍຮັບປັດຈຸບັນຄຸ້ມຄອງການໃຊ້ຈ່າຍທີ່ບັນທຶກຂອງເດືອນນີ້.';

  @override
  String financialInsightMsgMonthComparableIncreaseReason(
    String changePercent,
  ) {
    return 'ການໃຊ້ຈ່າຍນັບແຕ່ຕົ້ນເດືອນສູງກວ່າເດືອນທຽບເທົ່າກ່ອນໜ້າ $changePercent.';
  }

  @override
  String get financialInsightMsgMonthComparableDecreaseReason =>
      'ການໃຊ້ຈ່າຍນັບແຕ່ຕົ້ນເດືອນຕ່ຳກວ່າໄລຍະທຽບເທົ່າກ່ອນໜ້າ.';

  @override
  String get financialInsightMsgSteadyReasonToday =>
      'ມື້ນີ້ຢູ່ໃນອັດຕາການໃຊ້ຈ່າຍທີ່ດີ.';

  @override
  String get financialInsightMsgSteadyReasonWeek =>
      'ອາທິດນີ້ຕິດຕາມໃກ້ຄຽງກັບອັດຕາຫຼ້າສຸດຂອງທ່ານ.';

  @override
  String get financialInsightMsgSteadyReasonMonth =>
      'ເດືອນນີ້ຢູ່ໃນແຜນທີ່ບັນທຶກໄວ້ໃນ Cashly.';

  @override
  String get financialInsightMsgShortHorizonNoActiveAccountToday =>
      'ມື້ນີ້ຍັງບໍ່ມີຍອດເງິນບັນຊີທີ່ໃຊ້ງານໃຫ້ປຽບທຽບ ດັ່ງນັ້ນ Cashly ກຳລັງໃຊ້ຍອດເງິນປັດຈຸບັນ, ງົບປະມານ, ແລະ ສັນຍານການໃຊ້ຈ່າຍ.';

  @override
  String get financialInsightMsgShortHorizonNoActiveAccountWeek =>
      'ອາທິດນີ້ຍັງບໍ່ມີຍອດເງິນບັນຊີທີ່ໃຊ້ງານໃຫ້ປຽບທຽບ ດັ່ງນັ້ນ Cashly ກຳລັງໃຊ້ຍອດເງິນປັດຈຸບັນ, ງົບປະມານ, ແລະ ສັນຍານການໃຊ້ຈ່າຍ.';

  @override
  String get financialInsightMsgShortHorizonCrossCurrencyToday =>
      'ມີການໂອນລະຫວ່າງສະກຸນເງິນເກີດຂຶ້ນມື້ນີ້. Cashly ກຳລັງຮັກສາການປຽບທຽບຍອດເງິນເປັນກາງຈົນກວ່າຈະມີພື້ນຖານອັດຕາແລກປ່ຽນ.';

  @override
  String get financialInsightMsgShortHorizonCrossCurrencyWeek =>
      'ມີການໂອນລະຫວ່າງສະກຸນເງິນເກີດຂຶ້ນອາທິດນີ້. Cashly ກຳລັງຮັກສາການປຽບທຽບຍອດເງິນເປັນກາງຈົນກວ່າຈະມີພື້ນຖານອັດຕາແລກປ່ຽນ.';

  @override
  String get financialInsightMsgShortHorizonAccountAddedToday =>
      'ມີການເພີ່ມບັນຊີໃໝ່ມື້ນີ້ ດັ່ງນັ້ນ Cashly ຍັງບໍ່ສາມາດຄຳນວນຍອດເງິນເປີດນັ້ນຄືນຢ່າງປອດໄພ.';

  @override
  String get financialInsightMsgShortHorizonAccountAddedWeek =>
      'ມີການເພີ່ມບັນຊີໃໝ່ອາທິດນີ້ ດັ່ງນັ້ນ Cashly ຍັງບໍ່ສາມາດຄຳນວນຍອດເງິນເປີດນັ້ນຄືນຢ່າງປອດໄພ.';

  @override
  String get financialInsightMsgShortHorizonUnverifiableToday =>
      'Cashly ບໍ່ສາມາດຢືນຢັນຄ່າຍອດເງິນສຳລັບມື້ນີ້ໄດ້ ດັ່ງນັ້ນການປຽບທຽບຍອດເງິນຈຶ່ງເປັນກາງ.';

  @override
  String get financialInsightMsgShortHorizonUnverifiableWeek =>
      'Cashly ບໍ່ສາມາດຢືນຢັນຄ່າຍອດເງິນສຳລັບອາທິດນີ້ໄດ້ ດັ່ງນັ້ນການປຽບທຽບຍອດເງິນຈຶ່ງເປັນກາງ.';

  @override
  String get financialInsightMsgShortHorizonZeroOpeningToday =>
      'ມື້ນີ້ເລີ່ມຕົ້ນທີ່ສູນໂດຍບໍ່ມີລາຍຮັບ ຫຼື ລາຍຈ່າຍທີ່ບັນທຶກ ດັ່ງນັ້ນ Cashly ກຳລັງໃຊ້ຍອດເງິນປັດຈຸບັນ, ງົບປະມານ, ແລະ ສັນຍານການໃຊ້ຈ່າຍ.';

  @override
  String get financialInsightMsgShortHorizonZeroOpeningWeek =>
      'ອາທິດນີ້ເລີ່ມຕົ້ນທີ່ສູນໂດຍບໍ່ມີລາຍຮັບ ຫຼື ລາຍຈ່າຍທີ່ບັນທຶກ ດັ່ງນັ້ນ Cashly ກຳລັງໃຊ້ຍອດເງິນປັດຈຸບັນ, ງົບປະມານ, ແລະ ສັນຍານການໃຊ້ຈ່າຍ.';

  @override
  String financialInsightMsgShortHorizonIncreasedToday(
    String percent,
    String points,
  ) {
    return 'ຍອດເງິນມື້ນີ້ເພີ່ມຂຶ້ນ $percent, ປະກອບສ່ວນ $points ໃຫ້ຄະແນນຮ່ວມກັບສັນຍານງົບປະມານ ແລະ ການໃຊ້ຈ່າຍ.';
  }

  @override
  String financialInsightMsgShortHorizonIncreasedWeek(
    String percent,
    String points,
  ) {
    return 'ຍອດເງິນອາທິດນີ້ເພີ່ມຂຶ້ນ $percent, ປະກອບສ່ວນ $points ໃຫ້ຄະແນນຮ່ວມກັບສັນຍານງົບປະມານ ແລະ ການໃຊ້ຈ່າຍ.';
  }

  @override
  String financialInsightMsgShortHorizonDecreasedToday(
    String percent,
    String points,
  ) {
    return 'ຍອດເງິນມື້ນີ້ຫຼຸດລົງ $percent, ປະກອບສ່ວນ $points ໃຫ້ຄະແນນຮ່ວມກັບສັນຍານງົບປະມານ ແລະ ການໃຊ້ຈ່າຍ.';
  }

  @override
  String financialInsightMsgShortHorizonDecreasedWeek(
    String percent,
    String points,
  ) {
    return 'ຍອດເງິນອາທິດນີ້ຫຼຸດລົງ $percent, ປະກອບສ່ວນ $points ໃຫ້ຄະແນນຮ່ວມກັບສັນຍານງົບປະມານ ແລະ ການໃຊ້ຈ່າຍ.';
  }

  @override
  String financialInsightMsgShortHorizonStayedLevelToday(String points) {
    return 'ຍອດເງິນມື້ນີ້ຄົງທີ່, ປະກອບສ່ວນ $points ໃຫ້ຄະແນນຮ່ວມກັບສັນຍານງົບປະມານ ແລະ ການໃຊ້ຈ່າຍ.';
  }

  @override
  String financialInsightMsgShortHorizonStayedLevelWeek(String points) {
    return 'ຍອດເງິນອາທິດນີ້ຄົງທີ່, ປະກອບສ່ວນ $points ໃຫ້ຄະແນນຮ່ວມກັບສັນຍານງົບປະມານ ແລະ ການໃຊ້ຈ່າຍ.';
  }
}
