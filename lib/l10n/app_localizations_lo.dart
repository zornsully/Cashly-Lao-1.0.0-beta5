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
      'ຮັບການແຈ້ງເຕືອນເມື່ອງົບປະມານເກີນຂອບເຂດ, ຍອດເງິນບັນຊີຕິດລົບ, ຫຼື ເຖິງກຳນົດຝາກເງິນເຂົ້າເປົ້າໝາຍການເກັບເງິນ. ໃຊ້ໄດ້ສະເພາະຕອນເປີດແອັບເທົ່ານັ້ນ.';

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
}
