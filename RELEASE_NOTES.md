# Cashly v1.0 — Release Notes

Cashly is a personal finance management app built for Laos (LAK as the
default currency, with multi-currency support), built with Flutter,
Firebase (Auth + Firestore), Riverpod, and GoRouter using Clean
Architecture throughout.

## Features

### Authentication
Email/password login, registration, forgot-password, and email
verification. Persistent login across app restarts. Profile screen shows
account details and lets you edit your display name.

### Accounts
Cash, Wallet, Bank, Credit Card, and Savings accounts, each with its own
currency (LAK, THB, USD, EUR, CNY), initial/current balance, icon, and
color. Archive accounts you no longer use without losing their history.

### Categories
Income and expense categories with icon and color, drag-to-reorder, and
archive. Cashly seeds 15 curated default categories (5 income, 10
expense) the first time you sign in, so you can start tracking
immediately.

### Transactions
Record income and expenses against an account and category, with amount,
date, and an optional note. Editing or deleting a transaction
automatically reconciles the linked account's balance — including moving
a transaction to a different account or flipping it between income and
expense. Browse month by month with real-time updates.

### Dashboard
Your at-a-glance financial summary: total balance, this month's income
and expense, recent transactions, spending by category, and account
balances — all grouped correctly by currency if you use more than one.

### Budget
Set a monthly spending limit per expense category. Track progress with a
bar that turns red when you go over, see exactly how much is remaining,
and get clear overspending detection. Budgets are also denominated in a
specific currency, so spending only counts against a budget from accounts
in that same currency.

### Reports
A deeper analytics view: a monthly income vs. expense summary, a 6-month
trend chart, a spending-by-category breakdown, and budget vs. actual —
all in one place, free for everyone.

### Settings
Choose your appearance (Light, Dark, or follow System) and set a default
currency that pre-fills new accounts and budgets.

## Under the hood

- **Clean Architecture, feature-first**: every feature has its own
  domain (entities, repository interfaces, usecases), data (Firestore
  models, datasources, repository implementations), and presentation
  (Riverpod providers, screens, widgets) layers.
- **Riverpod** for state management throughout, including real-time
  Firestore streams via `StreamProvider`.
- **GoRouter** for navigation, with authentication guarding entirely in
  one place (`redirect`) rather than scattered across screens.
- **Firestore security rules** enforce that every user can only ever
  read or write their own data, with server-side validation of every
  write (field types, required fields, and — where the app's own domain
  model treats a field as immutable after creation, like a category's
  `isDefault` flag or a budget's category/month — that invariant is
  enforced by the rules too, not just by the client).
- **241 automated tests** (up from 140 at initial launch) covering every
  feature's domain and data layers — model mapping, datasource behavior
  against a fake Firestore, repository error handling, usecase logic —
  plus 10 widget/screen-level presentation tests.
- **Responsive layout**: content is centered with a comfortable max width
  on tablets, while remaining full-width and unaffected on phones.

## Since v1.0

Shipped after initial launch, in order:
- **Google Sign-In**, alongside email/password — including a real bug
  found via beta-testing on physical hardware (not caught by
  `flutter analyze`/`flutter test`/emulator testing) and fixed; see
  `TODO.md` for the detail.
- **Search, filter, and sort** on Transactions.
- **A sync-status indicator** — an "offline — changes will sync" banner
  backed by Firestore's own snapshot metadata.
- **CSV export** for monthly Reports.
- **Biometric/PIN app lock**, gated behind a Settings toggle.
- **Local (on-device) notifications** for budget-exceeded and
  negative-account-balance conditions — deliberately not push/FCM, a
  real infrastructure/billing decision rather than a shortcut.
- **A multi-currency reporting rollup** — Reports now shows one
  converted total across every currency a month's activity touched,
  using a fetched daily exchange rate, alongside (never replacing) the
  currency-exact per-currency figures.

## Known limitations

See `TODO.md` for the full list of what's intentionally deferred. The
short version: no real monetization (Premium was removed ahead of launch
rather than ship a demo purchase flow — see `TODO.md`), no PDF export
(CSV shipped), and iOS remains completely untested — this project has
only ever been built and verified on Android.
