import 'package:flutter/widgets.dart';

/// Material Symbols Rounded icons Cashly actually uses, defined directly
/// against the `material_symbols_icons` package's bundled font asset
/// rather than importing that package's `symbols.dart`.
///
/// `symbols.dart` is a ~7.5MB generated file covering all three styles
/// (outlined/rounded/sharp) of the entire Material Symbols set. Importing
/// it makes `flutter build apk` fail on Windows — the Gradle-driven kernel
/// compiler errors reading that file ("Undefined name 'Symbols'" /
/// "the system cannot find the path specified"), even though `flutter
/// analyze` and `flutter test` handle it without complaint. Defining only
/// the handful of icons actually needed, as plain `IconData` constants
/// against the same bundled `MaterialSymbolsRounded.ttf` font (still
/// pulled in automatically via the `material_symbols_icons` pubspec
/// dependency), sidesteps the giant file entirely. Add new entries here
/// as needed rather than reaching for the `symbols.dart` import.
///
/// Codepoints sourced from that package's generated `symbols.dart`
/// (version 4.2951.0) — [name]_rounded entries.
abstract final class AppSymbols {
  static const _family = 'MaterialSymbolsRounded';
  static const _package = 'material_symbols_icons';

  static const IconData payments = IconData(
    0xef63,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData accountBalanceWallet = IconData(
    0xe850,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData accountBalance = IconData(
    0xe84f,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData creditCard = IconData(
    0xe8a1,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData savings = IconData(
    0xe2eb,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData localAtm = IconData(
    0xe53e,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData currencyExchange = IconData(
    0xeb70,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData warningAmberRounded = IconData(
    0xf083,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData businessCenter = IconData(
    0xeb3f,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData shoppingBag = IconData(
    0xf1cc,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData restaurant = IconData(
    0xe56c,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData home = IconData(
    0xe9b2,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData directionsCar = IconData(
    0xeff7,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData flight = IconData(
    0xe539,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData favorite = IconData(
    0xe87e,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData school = IconData(
    0xe80c,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData cardGiftcard = IconData(
    0xe8f6,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData movie = IconData(
    0xe684,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData bolt = IconData(
    0xea0b,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData pieChart = IconData(
    0xf0da,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData star = IconData(
    0xf09a,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData work = IconData(
    0xe943,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData trendingUp = IconData(
    0xe8e5,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData localGroceryStore = IconData(
    0xe8cc,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData directionsBus = IconData(
    0xeff6,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData receiptLong = IconData(
    0xef6e,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData moreHoriz = IconData(
    0xe5d3,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData arrowDownward = IconData(
    0xe5db,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData arrowUpward = IconData(
    0xe5d8,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData trendingDown = IconData(
    0xe8e3,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData calendarMonth = IconData(
    0xebcc,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData keyboardArrowDown = IconData(
    0xe313,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData notificationsNone = IconData(
    0xe7f5,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData personOutline = IconData(
    0xf0d3,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData settings = IconData(
    0xe8b8,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData person = IconData(
    0xf0d3,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData addRounded = IconData(
    0xe145,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData removeRounded = IconData(
    0xe15b,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData swapHoriz = IconData(
    0xe8d4,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData dashboardCustomize = IconData(
    0xe99b,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData insertChartOutlined = IconData(
    0xf0cc,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData iosShare = IconData(
    0xe6b8,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData category = IconData(
    0xe72c,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData calendarToday = IconData(
    0xe935,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData notes = IconData(
    0xe26c,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData helpOutline = IconData(
    0xe8fd,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData deleteOutline = IconData(
    0xe92e,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData close = IconData(
    0xe5cd,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData search = IconData(
    0xef7a,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData tune = IconData(
    0xe429,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData moreVert = IconData(
    0xe5d4,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData edit = IconData(
    0xf097,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData contentCopy = IconData(
    0xe14d,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData archive = IconData(
    0xe149,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData dragHandle = IconData(
    0xe25d,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData labelOutline = IconData(
    0xe893,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData brightnessAuto = IconData(
    0xe1ab,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData lightMode = IconData(
    0xe518,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData darkMode = IconData(
    0xe51c,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData chevronRight = IconData(
    0xe5cc,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData chevronLeft = IconData(
    0xe5cb,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData errorOutline = IconData(
    0xf8b6,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData refresh = IconData(
    0xe5d5,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData cloudOff = IconData(
    0xe2c1,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData check = IconData(
    0xe668,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData lockOutline = IconData(
    0xe899,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData visibility = IconData(
    0xe8f4,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData visibilityOff = IconData(
    0xe8f5,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData dashboard = IconData(
    0xe871,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData barChart = IconData(
    0xe26b,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData repeat = IconData(
    0xe040,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData checkCircle = IconData(
    0xf0be,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData autoAwesome = IconData(
    0xe65f,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData info = IconData(
    0xe88e,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData flag = IconData(
    0xf0c6,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData southEast = IconData(
    0xf1e4,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData northEast = IconData(
    0xf1e1,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData addChart = IconData(
    0xef3c,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData waterfallChart = IconData(
    0xea00,
    fontFamily: _family,
    fontPackage: _package,
  );
  // `matchTextDirection: true` here and on `logout` below is verified
  // directly against the installed material_symbols_icons package source
  // (compare_arrows_rounded / logout_rounded both declare it) -- not a
  // stylistic choice, so keep it even if a future merge drops it again.
  static const IconData compareArrows = IconData(
    0xe915,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData circle = IconData(
    0xef4a,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData verified = IconData(
    0xef76,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData logout = IconData(
    0xe9ba,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData deleteForever = IconData(
    0xe92b,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData notificationsActive = IconData(
    0xe7f7,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData email = IconData(
    0xe159,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData markEmailRead = IconData(
    0xf18c,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData markEmailUnread = IconData(
    0xf18a,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData badge = IconData(
    0xea67,
    fontFamily: _family,
    fontPackage: _package,
  );
}
