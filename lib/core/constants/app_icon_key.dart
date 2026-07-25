import 'package:flutter/material.dart';

import 'app_symbols.dart';

/// A curated, stable set of icons users can pick for an account or category.
///
/// We persist [AppIconKey.name] (not a raw `IconData.codePoint`) to
/// Firestore — code points aren't guaranteed stable across icon font
/// versions, but an enum name is. That's also what makes swapping from
/// classic Material Icons to Material Symbols Rounded (below) a pure
/// visual change: existing users' stored choices reference the enum name,
/// never the icon itself.
enum AppIconKey {
  cash(AppSymbols.payments),
  wallet(AppSymbols.accountBalanceWallet),
  bank(AppSymbols.accountBalance),
  creditCard(AppSymbols.creditCard),
  savings(AppSymbols.savings),
  atm(AppSymbols.localAtm),
  currencyExchange(AppSymbols.currencyExchange),
  business(AppSymbols.businessCenter),
  shopping(AppSymbols.shoppingBag),
  food(AppSymbols.restaurant),
  home(AppSymbols.home),
  car(AppSymbols.directionsCar),
  travel(AppSymbols.flight),
  health(AppSymbols.favorite),
  education(AppSymbols.school),
  gift(AppSymbols.cardGiftcard),
  entertainment(AppSymbols.movie),
  utilities(AppSymbols.bolt),
  pieChart(AppSymbols.pieChart),
  star(AppSymbols.star),
  work(AppSymbols.work),
  investment(AppSymbols.trendingUp),
  groceries(AppSymbols.localGroceryStore),
  transport(AppSymbols.directionsBus),
  bills(AppSymbols.receiptLong),
  other(AppSymbols.moreHoriz);

  const AppIconKey(this.icon);

  final IconData icon;
}
