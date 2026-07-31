# Cashly — Project Progress

Tracks what's actually been built, sprint by sprint, against the project's
Clean Architecture (feature-first, Riverpod, Firebase, GoRouter) plan.
Updated at the end of every sprint.

**Stack:** Flutter 3.44.6 / Dart 3.12.2, Firebase (Auth, Firestore,
Crashlytics, Analytics; Cloud Functions backend under `functions/`, live
deployment status unverified — see `docs/CLOUD_FUNCTIONS_STATUS.md`),
Riverpod 3 (`^3.3.2`), GoRouter (`^17.3.0`), fpdart (`Either`/`Unit` for
error handling), `local_auth` (biometric/PIN app lock), `package_info_plus`.

**Verification baseline** (true as of the end of every sprint below):
`flutter analyze` → 0 issues. `flutter test` → all passing. Most sprints
through Savings Goals (Sprint 18) and the phases after it were built in a
sandbox with no Android SDK/Xcode, so native APK/IPA builds were not
produced there — `flutter analyze` + `flutter test` were the compilation/
correctness signal, with real device/emulator verification done
separately by the project owner where noted. **As of this update
(2026-07-31)**, `flutter analyze` → 0 issues and `flutter test` →
412/412 passing, re-verified directly rather than assumed from prior
notes; `flutter doctor` in this environment now also reports a working
Android toolchain (SDK 37.0.0), though no build was attempted as part of
this documentation update — see `TODO.md` for which Android-specific
changes (R8/shrinking, the AAB build) are still flagged as unverified
until actually built and device-tested.

---

## Sprint 0 — Project Foundation ✅

Scaffolded the Flutter app (Android + iOS) wired to the `cashly-lao`
Firebase project. Core layer: Material 3 theme (light/dark), error types
(`Failure`/exceptions), shared form widgets, Firebase provider wiring,
GoRouter setup, Firestore security rules baseline.

## Sprint 1 — Authentication ✅

Email/password login, register, forgot password, email verification,
logout, profile (view/edit display name), persistent login, and an
auth-guard entirely inside GoRouter's `redirect` (no screen manually checks
"am I logged in"). Post-launch review found and fixed a critical bug: the
auth stream was built on `authStateChanges()`, which Firebase does not fire
after `reload()`/`updateProfile()` — switched to `userChanges()` so the
verify-email and edit-name flows actually update reactively. Also fixed a
register() edge case and two responsive-layout overflow risks.

**Tests:** 23 (validators, login usecase, repository error-mapping, a
regression test pinning the `userChanges()` fix).

## Sprint 2 — Accounts ✅

Cash / Wallet / Bank / Credit Card / Savings accounts with initial/current
balance, currency (LAK/THB/USD/EUR/CNY), icon and color selection, archive,
and full CRUD. Firestore-backed (`users/{uid}/accounts/{id}`) with
real-time updates and validating security rules.

Built for reuse by later sprints: curated `AppIconKey`/`AppColorKey` enums
(persisted by stable name, not raw codePoint/ARGB — those aren't guaranteed
stable across Material font versions), `IconPickerField`/`ColorPickerField`
widgets, `AppCurrency`, a `RepositoryGuard` mixin factoring out the
try/catch → `Either` mapping (also refactored onto Auth's repository, so
there's one implementation instead of two). Introduced the bottom-nav
shell (`StatefulShellRoute`) once there was a second real destination
beyond Sprint 1's Profile screen.

**Tests:** 18 (model mapping, datasource against a fake Firestore,
archived-filtering logic, error mapping, usecase). Reviewed and fixed an
empty-state copy bug and hardened `AppCurrency` equality before commit.

## Sprint 3 — Categories ✅

Income/Expense categories with icon/color (reusing Sprint 2's pickers),
archive, drag-to-reorder (persisted `sortOrder`), and a 15-category
curated default set (5 income, 10 expense) seeded exactly once per user —
atomically, alongside a `defaultCategoriesSeeded` flag on the user's
profile doc — triggered at login rather than gated behind opening the
Categories tab, so Transactions always has categories ready. Security
rules validate every write and allow archiving but never deleting a
default category.

**Tests:** 15 (model mapping, seeding/idempotency/default-deletion-guard/
reorder against a fake Firestore, repository filtering, usecase). Review
fixed a silently-swallowed reorder-failure case and migrated off the
newly-deprecated `ReorderableListView.onReorder`.

## Sprint 4 — Transactions ✅

Full income/expense transaction tracking, Firestore-backed
(`users/{uid}/transactions/{id}`), integrated with both prior features:

- **Account integration**: creating, editing, or deleting a transaction
  atomically adjusts the linked account's balance via
  `FirebaseFirestore.runTransaction` — editing correctly reverses the old
  effect and applies the new one, including when the account or type
  (income/expense) changes, or when the transaction moves to a different
  account entirely.
- **Category integration**: category selection reuses Sprint 3's
  `categoriesProvider`, filtered to the transaction's current type.
- **Monthly filtering**: a persistent (session-scoped) selected-month
  provider with prev/next navigation; the Firestore query ranges on the
  `date` field, real-time via `.snapshots()`.
- Add/Edit form: type toggle, amount (validated `> 0`), account, category,
  date (Material date picker), optional note.
- List: real-time, empty/loading/error states, delete with confirmation
  (explicitly warns that it reverses the account balance).
- New fourth bottom-nav tab.

**Architectural decisions:**
- Transaction `amount` is stored as an unsigned magnitude; `type`
  (income/expense) determines the signed effect on balance
  (`TransactionEntity.signedAmount`). Keeps the sign unambiguous instead of
  relying on a signed amount matching its type.
- The transactions datasource reads/writes the `accounts/{id}` document
  directly (via the shared `FirestorePaths` path constants) inside the same
  atomic Firestore transaction, rather than depending on the Accounts
  feature's repository/domain types. This keeps the cross-feature
  consistency at the data layer (where Firestore's atomicity guarantee
  actually lives) without introducing a domain-level Transactions →
  Accounts dependency.
- Account/category dropdowns in the transaction form include archived
  items (labeled) rather than excluding them, so an existing transaction
  against a now-archived account/category always remains fully editable.
- Reviewed and fixed before commit: a missing `mounted` check after the
  date-picker await, a fixed-width month label that risked overflow at
  large accessibility text sizes, and a real crash risk — if a
  transaction's linked account/category were ever deleted elsewhere, the
  edit form's dropdowns would hit Flutter's "current value must match an
  item" assertion. Added a synthetic disabled fallback entry so the form
  degrades to a clear "choose another" prompt instead of crashing.

**Known limitation:** Sprint 2's `deleteAccount` does not check whether
transactions still reference that account before deleting it (Transactions
didn't exist yet when that was written). This sprint made the Transactions
side of that gap safe — `deleteTransaction` and now `updateTransaction`'s
form both handle a missing account gracefully rather than crashing — but
deleting an account that still has transactions is not itself blocked or
warned against. Worth revisiting when Accounts is next touched.

**Tests:** 20 (model mapping; datasource balance-adjustment logic for
create/update-same-account/update-cross-account/update-type-flip/delete,
including account-not-found; monthly range + ordering; repository error
mapping; usecase; `positiveAmount` validator).

**Running total: 77 tests, `flutter analyze` 0 issues.**

## Sprint 5 — Dashboard ✅

A read-only aggregation screen over Accounts, Categories, and
Transactions — the app's new landing tab. Shows, per currency (see
architectural decision below): Total Balance, Total Income (month), Total
Expense (month), Recent Transactions (last 5, tap to edit, delete with
the same balance-reversing confirmation as the Transactions tab), Spending
by Category (proportional bars using each category's own color, with
percentage text alongside so the comparison isn't color-only), and Account
Balances (reusing Sprint 2's `AccountCard`). Fully real-time — recomputes
whenever any underlying Firestore stream changes.

**Architectural decisions:**
- **No new Firestore collection, datasource, or repository.** Dashboard
  owns no data of its own — it's a pure aggregation over what Accounts,
  Categories, and Transactions already stream. Domain layer is a value
  object (`DashboardSummary`, `CategorySpending`) plus
  `BuildDashboardSummaryUseCase`, a plain synchronous function (accounts +
  month's transactions + categories → summary) with no repository
  dependency at all — there's nothing to abstract over. The presentation
  layer's `dashboardSummaryProvider` is what combines the three features'
  existing async providers reactively; introducing a
  `DashboardRepository` that only ever delegated to three other
  repositories would have been indirection without benefit.
- **Every total is keyed by currency code** (`Map<String, double>`, e.g.
  `{'LAK': 1500000}`), never collapsed into one number. Accounts can each
  use a different currency (Sprint 2); silently summing across currencies
  would produce a figure that doesn't correspond to any real amount of
  money. In the overwhelmingly common single-currency case this is
  invisible — one entry, one card row — but it stays correct the moment a
  user has two.
- **Dashboard's month is always the real current calendar month**,
  independent of whatever month the user has navigated to on the
  Transactions tab (that's separate, user-driven browsing state) —
  implemented as its own provider rather than reusing Transactions'
  `selectedTransactionsMonthProvider`.
- A transaction whose linked account was since deleted (the Sprint 4
  known limitation) is excluded from every currency-keyed total — there's
  no currency to attribute it to — but still appears in Recent
  Transactions, which doesn't need one. Likewise an expense whose category
  was deleted is still counted in that currency's total expense but
  excluded from the Spending by Category breakdown, since it can't be
  attributed to a category bucket. Both are covered by tests.

**Tests:** 8, all on `BuildDashboardSummaryUseCase` (the one place with
real logic worth testing) — currency grouping for balance/income/expense,
orphaned-account and orphaned-category handling, the 5-item recent-list
cap, spending-by-category grouping/sorting/percentages, empty inputs, and
no divide-by-zero when a currency has no expense this month.

**Running total: 85 tests, `flutter analyze` 0 issues.**

## Sprint 6 — Budget ✅

Monthly, per-category expense budgets, Firestore-backed
(`users/{uid}/budgets/{categoryId}_{yyyy-MM}`), integrated with both
Transactions (spend tracking) and Dashboard (progress display).

The Budget tab lists every active expense category for the browsed month
(its own prev/next month selector, independent of Transactions' and
Dashboard's) — each row is either a progress tile (spent/limit, a bar that
turns red when over, remaining amount, delete) or a "No budget set" row
with a button that opens the create form pre-bound to that category and
month. Editing a budget only ever changes its limit and currency — the
category and month are fixed at creation by design (see below). Dashboard
gained a "Budgets" section (reusing the same `BudgetProgressTile`,
omitted entirely when no budgets exist yet, matching how Dashboard already
omits its other empty sections).

**Architectural decisions:**
- **One budget per category per month is a data-model invariant, not a
  query-time check**: the Firestore document ID is deterministic
  (`{categoryId}_{yyyy-MM}`), so a duplicate is structurally a write to
  the same document rather than a second one ever existing. `createBudget`
  still checks-then-rejects if one already exists (clear "already exists"
  error rather than silently overwriting), and `updateBudget`/
  `deleteBudget` only ever touch a budget's limit/currency or remove it —
  category and month can't change after creation, so there's no path to
  create a second budget for the same category/month by editing one.
- **A budget is denominated in one specific currency**, chosen at
  creation, and only transactions on accounts of that same currency count
  toward it — the same reasoning as Dashboard's per-currency totals
  (Sprint 5): a category can be spent from accounts in different
  currencies, and mixing them into one "spent" figure against one limit
  would produce a number that doesn't correspond to any real comparison.
  In the common single-currency case this is invisible; a user tracking
  the same category in two currencies simply sets two budgets for it.
- **`BuildBudgetProgressUseCase` is a second pure, repository-free
  usecase** (alongside Dashboard's `BuildDashboardSummaryUseCase`) — same
  reasoning: no new data source to abstract over, just arithmetic
  combining Budgets' own data with Accounts/Categories/Transactions,
  which already stream. `BudgetProgress` (spent/remaining/percentage/
  overspent) is entirely computed, never stored.
- **Promoted a provider from private to shared**: Dashboard's Sprint 5
  `_dashboardTransactionsProvider` (a month-scoped transactions stream,
  private to that file) is now `transactionsForMonthProvider`, a public
  family provider in the Transactions feature — Budget needed the exact
  same capability, so duplicating it a second time was the signal to
  promote it. Both Dashboard's and Budget's "progress for month X"
  providers are themselves families for the same reason: each is watched
  twice — once for the browsing tab's user-selected month, once for
  Dashboard's always-current month — and building that on a shared family
  provider means the aggregation logic is written exactly once.

**Tests:** 18 (model mapping; datasource — deterministic IDs, one-per-
category-per-month rejection, same category across different months,
update/delete, monthly query; repository error mapping; usecase
delegation; `BuildBudgetProgressUseCase` — currency-matched spend
calculation, overspend detection, cross-currency exclusion, income
transactions ignored, orphaned-category exclusion, zero-spend case).

**Running total: 103 tests, `flutter analyze` 0 issues.**

## Sprint 7 — Reports ✅

A historical analytics screen over Accounts, Categories, Transactions, and
Budgets — reached via an icon button in Dashboard's AppBar rather than a
7th bottom-nav tab (see below). The Reports screen browses its own month
(independent prev/next selector, same pattern as Transactions/Budget) and
shows, per currency: a Monthly Summary (income/expense/net), an Income vs
Expense Trend across the last 6 months (a custom grouped bar chart — tap a
month to see its exact figures), Spending by Category (a custom donut
chart with a text legend so identity is never color-only), and Budget vs
Actual (reusing `BudgetProgressTile` as-is).

**Architectural decisions:**
- **No new Firestore collection, datasource, or repository** — same
  reasoning as Dashboard (Sprint 5) and Budget (Sprint 6): Reports owns no
  data of its own, it's a pure aggregation over what the other four
  features already stream. The one genuinely new capability needed was a
  general date-range query, so `TransactionRepository` gained
  `watchTransactionsInRange({start, endExclusive})`; `watchTransactionsForMonth`
  is now a thin convenience wrapper over it.
- **Extracted `ComputeCategorySpendingUseCase` out of Dashboard's summary
  usecase** once Reports needed the identical "group expense transactions
  by category and currency, with percentages" computation a third
  time (Dashboard and Budget already shared the pattern of promoting
  duplicated logic once a second consumer appeared — this is the same
  move one level down, at the usecase layer instead of the provider
  layer). `BuildDashboardSummaryUseCase`'s own 8 existing tests were
  re-run unchanged after the extraction to confirm the refactor didn't
  change behavior.
- **`MonthlyReport` reuses `CategorySpending` (Dashboard) and
  `BudgetProgress` (Budget) directly** rather than redefining equivalent
  value objects — both are pure, repository-free entities, consistent
  with the codebase's existing convention of sharing entities (but never
  repositories or datasources) across features.
- **`MonthlyReport.toExportRows()`** flattens a report into a stable list
  of `Map<String, Object?>` rows (one per category spend, plus one
  totals-per-currency row) — this is what "export-ready report models"
  means here: a tested, stable data shape a future CSV/PDF export feature
  can build on, rather than a placeholder "Export" button with nothing
  behind it.
- **Not a 7th bottom-nav tab.** Six tabs already exceeds Material's
  typical 3-5 guidance; Reports is a pushed full-screen route
  (`AppRoutes.reports`) reached via an icon button in Dashboard's AppBar
  instead.
- **No third-party charting package.** The trend and category-breakdown
  charts are custom, lightweight widgets — a plain-widget grouped bar
  chart and a `CustomPainter` donut chart — consistent with the app's
  established pattern of avoiding chart libraries for simple visualizations
  (`StatCard`, `CategorySpendingBar`, `BudgetProgressTile` all did the
  same).

**Tests:** 13 — `watchTransactionsInRange` (multi-month span, exclusive
end boundary) on the transactions datasource; `BuildMonthlyTrendUseCase`
(month bucketing/ordering, per-currency income/expense grouping, orphaned-
account exclusion, out-of-window exclusion); `BuildMonthlyReportUseCase`
(full combination, month normalization, orphaned-account income
exclusion); `MonthlyReport` (currency union, net calculation,
`hasAnyActivity`, `toExportRows()` row shape).

**Running total: 116 tests, `flutter analyze` 0 issues.**

## Sprint 8 — Settings ✅

A `settings` feature, reached via a gear icon on the Profile tab (same
"pushed route from an icon" pattern established by Reports on Dashboard).
Two preferences: **Appearance** (System/Light/Dark, applied immediately
app-wide) and **default currency** (pre-selects the currency dropdown on
new Accounts/Budgets, which previously always defaulted to LAK). Both
persist to the same `users/{uid}` profile document Auth already writes —
its seed-write comment has said "settings... attach fields to" since
Sprint 1.

This sprint's requirements weren't specified in advance; the scope above
was chosen deliberately narrow, and flagged to the user before starting.
Deliberately **not** included: biometric/PIN app-lock, push-notification
toggles, an "About" screen — none have real infrastructure behind them yet
(no `local_auth` package, no FCM setup, no version-info package), and a
toggle with no actual effect would violate the project's no-placeholder
rule. Worth a proper sprint of their own once that infrastructure is a
real requirement.

**Architectural decisions:**
- **No new Firestore collection.** `UserPreferencesEntity` (`themeMode`,
  `defaultCurrencyCode`) is read from and written to the existing
  `users/{uid}` document via `SetOptions(merge: true))`, the same pattern
  `updateDisplayName` (Sprint 1) already uses on that same document. No
  Firestore rules changes were needed — the existing `users/{userId}` rule
  already grants `allow update` to the document's own owner with no
  per-field validation, so the new fields are covered automatically.
- **`AppThemeModePreference` lives in `core/constants`**, not the domain
  layer, mirroring `AppIconKey`/`AppColorKey` (Sprint 2): persisted by
  enum `.name` rather than Flutter's own `ThemeMode` ordering, for the
  same forward-compatibility reason.
- **Missing document ≠ error.** `UserPreferencesModel.fromFirestore`
  treats an absent document (e.g. a dropped best-effort seed write) and
  an absent field identically — both default to system theme / LAK —
  since a user who has never touched Settings should see the exact
  behavior Cashly always had.
- **Full Clean Architecture layers despite being "just two fields"**:
  domain entity + repository interface + two usecases, data model +
  datasource + repository impl, presentation provider + `AsyncNotifier`
  controller + screen — matching every other feature's structure rather
  than special-casing something this small.
- **`CashlyApp` watches `userPreferencesProvider` and falls back to
  `ThemeMode.system`** whenever it has no value yet — covers both "still
  loading" and "not signed in" (the provider is watched unconditionally,
  including on the pre-auth splash/login/register screens, where it
  synchronously errors with "no signed-in user" and is never displayed;
  only `.value`, never `.when`, is read here).
- **Account/Budget forms read the default currency once, in `initState`**
  via `ref.read` (not `ref.watch` — the dropdown's initial value shouldn't
  jump mid-edit if the preference changes in another tab), falling back to
  `SupportedCurrencies.fallback` if preferences haven't loaded yet by the
  time the form opens.

**Tests:** 14 — `UserPreferencesModel.fromFirestore` (stored values,
defaults when fields absent, defaults when the document doesn't exist);
datasource against a fake Firestore (defaults, merge-not-clobber for both
fields, real-time updates, no-signed-in-user); repository error mapping;
both usecases' delegation.

**Running total: 130 tests, `flutter analyze` 0 issues.**

## Sprint 9 — Premium ✅

A `premium` feature gating Reports (Sprint 7) behind entitlement, plus a
Premium screen (reached via a row on the Profile tab, or automatically
when a free user taps Dashboard's now-lock-icon Reports button) showing
what's included and a way to toggle status.

**This sprint's requirements weren't specified in advance** — the roadmap
just says "Premium." No in-app-purchase infrastructure exists in this
build (no `in_app_purchase` package, no App Store/Play Console products
configured), so a real payment flow was not buildable here, and faking
one — a "processing payment" animation with no processor behind it —
would have been a placeholder, which the project rules explicitly
disallow. The scope actually built:

- **Real entitlement infrastructure**: `PremiumStatusEntity` (`isPremium`,
  `activatedAt`), persisted on the same `users/{uid}` document Settings
  (Sprint 8) already uses, following the identical Clean Architecture
  shape (entity, repository, usecases, model, datasource, repository
  impl, provider, `AsyncNotifier` controller, screen).
- **Reports is the gated feature** — a deliberate product choice, not an
  arbitrary one: core money-tracking (Accounts, Transactions, Budget)
  stays entirely free; the analytics/insights layer built in Sprint 7 is
  what's behind Premium. This is the same shape most personal-finance
  apps use (free ledger, paid insights).
- **The Premium screen's "Activate/Deactivate Premium" button is real,
  working code — it performs the actual Firestore write a payment
  webhook would perform once IAP is wired up** — not a disabled
  "coming soon" stub. It's explicitly labeled "(demo)" and the screen
  states in-UI that no charge is made, so nothing about it pretends to be
  a real transaction.

**Architectural decisions:**
- **No new Firestore collection.** Same pattern as Settings: `isPremium`
  and `premiumActivatedAt` fields on the existing `users/{uid}` document,
  written via `SetOptions(merge: true)`. No rules changes needed for the
  same reason as Sprint 8 (the existing owner-only `update` rule has no
  per-field validation) — but `firestore.rules` now carries an explicit
  comment flagging that a client-writable `isPremium` field is a known,
  acceptable-for-now gap that **must** move behind a server-validated
  write (a Cloud Function checking a real purchase receipt) before real
  money is involved. This is the Premium-specific equivalent of Sprint
  4's "known limitation" callouts — a deliberate, documented gap rather
  than a silent one.
- **Reports gates itself, not just its entry points** (defense in depth):
  Dashboard's Reports button already only offers the lock icon → Premium
  screen when `!isPremium`, but `ReportsScreen` also checks
  `premiumStatusProvider` directly and renders a locked upsell view
  instead of report content if reached any other way (e.g. a future deep
  link) — mirrors the codebase's general preference for guards that don't
  rely on every caller doing the right thing.
- **The gate lives in the UI layer, not the router's `redirect`** — unlike
  the Auth guard (entirely in `GoRouter.redirect`, Sprint 1). Auth state
  has a clear "still resolving" state handled by the splash screen before
  `redirect` ever runs; `premiumStatusProvider` doesn't have an equivalent
  splash gate and reusing `redirect` for it would risk a loading-state
  flicker to the Premium screen before the real status loads. Simpler and
  safer to gate at the two places Reports is actually reached from.

**Tests:** 14 — `PremiumStatusModel.fromFirestore` (stored values,
defaults when fields absent, defaults when the document doesn't exist);
datasource against a fake Firestore (defaults, activate/deactivate,
merge-not-clobber, no-signed-in-user); repository error mapping; both
usecases' delegation.

**Running total: 144 tests, `flutter analyze` 0 issues.**

## Sprint 10 — Testing, Optimization, and Release Preparation ✅ (this sprint)

A full-codebase review pass across all nine features (Auth, Accounts,
Categories, Transactions, Dashboard, Budget, Reports, Settings, Premium)
— no new features, purely correctness/consistency/polish. No behavior-
changing bugs were found in the core money-tracking logic (balance
reconciliation, budget progress, currency grouping, etc. all held up under
re-reading); the findings below are refactors, a genuine security-rules
gap, and responsive/error-handling consistency improvements.

**Duplicated code found and refactored:**
- **`MonthSelectorHeader`** (`core/widgets/`): the prev/month-label/next
  `AppBar.bottom` header was byte-for-byte identical across Transactions,
  Budget, and Reports (three sprints, three copies). Extracted into one
  `PreferredSizeWidget` taking `month`/`onPrevious`/`onNext`; each screen
  now passes its own month provider's callbacks.
- **`ErrorView`** (`core/widgets/`): every screen's `AsyncValue.when(error:
  ...)` branch rendered the raw exception as bare `Text('$error')` — 11
  occurrences across 9 files, and poor UX (no icon, no visual weight,
  looks broken rather than like a handled error state). Replaced with a
  shared widget matching `EmptyState`'s existing look (icon + title +
  message), with an optional `onRetry` for future use.

**Responsive layout (goal: phones and tablets):** every form/profile
screen already constrained its content width (`ConstrainedBox` at 440px,
established since Sprint 1/2), but every list/dashboard-style screen
(Accounts, Categories, Transactions, Budget, Dashboard, Reports, Settings,
Premium) had no such constraint and would have stretched full-bleed edge
to edge on a tablet. Added **`ResponsiveCenter`** (`core/widgets/`) — caps
content at 720px and centers it, a no-op on phone widths — and wrapped
every list/dashboard screen's body in it.

**Security rules — two real gaps found and fixed** (not just documentation
this time):
- **Categories**: `isDefault` was `bool`-type-checked on `update` but never
  pinned to its existing value. A user's own Firestore document is only
  protected by rules (not by what the official app UI happens to expose),
  so a direct API call could set `isDefault: false` on a real default
  category via `update`, then `delete` it — bypassing the "default
  categories can never be deleted" guarantee entirely, since the `delete`
  rule only checks the *current* `isDefault` value at delete time. Fixed
  by splitting `create`/`update` into separate rules and requiring
  `request.resource.data.isDefault == resource.data.isDefault` on update —
  matching `CategoryEntity.copyWith`, which never exposed `isDefault` as
  mutable in the first place.
- **Budgets**: `categoryId`/`month` were type-checked but not pinned on
  `update`, even though the whole "one budget per category per month"
  invariant depends on the deterministic document ID
  (`{categoryId}_{yyyy-MM}`) matching those two fields. A direct API
  update could silently repoint an existing budget document at a
  different category/month, desyncing the ID from its own data and
  defeating `watchBudgetsForMonth`'s month-field query. Fixed the same
  way: split `create`/`update`, pin both fields unchanged on update.
- Confirmed no composite Firestore indexes are required by any current
  query (every `where`+`orderBy` combination is on a single field, or a
  bare equality filter) — `firestore.indexes.json`'s empty index list is
  correct as-is, not an oversight.
- The pre-existing, already-documented client-writable `isPremium` gap
  (Sprint 9) was reviewed again and left as is — it's an accepted, explicit
  tradeoff for this pre-launch build, not an oversight like the two above.

**Performance:** reviewed for missing `const` (already fully enforced by
`flutter_lints`, nothing to fix), unnecessary rebuild scope (Dashboard/
Reports/Budget's multi-provider combination pattern already limits
rebuilds to only the specific streams each screen needs — see Sprint 5/6/7
architectural decisions), and Firestore query efficiency (Accounts/
Categories fetch their full collection and filter client-side, which is
correct at the realistic scale of a personal-finance app's own data —
flagged as a scaling note in `TODO.md` rather than "fixed," since
introducing server-side pagination now would be premature optimization
for data volumes that don't exist yet).

**Loading/empty/error state audit:** confirmed every screen already used
`AppLoadingIndicator` for loading and `EmptyState` for empty results
consistently (established since Sprint 2); the only real gap was the
error branch, closed by the `ErrorView` refactor above.

**Navigation audit:** every `AppRoutes` constant is both registered in
`app_router.dart` and reached from at least one `context.go`/`context.
push` call; no dead routes, no orphaned constants. Confirmed the `:id`
route templates (`accountEdit`, `categoryEdit`, `budgetEdit`,
`transactionEdit`) are only ever used for `GoRoute` registration, never
passed directly to a navigation call (`context.push` always goes through
the corresponding `*EditPath(id)` helper). One pre-existing, known
limitation carried forward into `TODO.md`: edit routes pass the entity via
GoRouter's `extra`, so a cold deep link to an edit URL (without having
navigated there in-app first) would need to fetch by ID instead — not a
bug today since nothing generates such links, but worth closing before any
web deployment relies on shareable URLs.

**Dependencies:** `flutter pub outdated` / `flutter pub upgrade` — all
direct and dev dependencies already at their latest resolvable versions
for this Flutter SDK; the handful of outdated transitive packages
(`analyzer`, `meta`, etc.) are pinned by the SDK itself, not by this
project's `pubspec.yaml`, and forcing them further would risk breaking
tooling compatibility rather than improving anything shipped. No changes
made.

**Tests:** no new test files this sprint — the changes are presentation-
layer widgets with no business logic (`ErrorView`, `MonthSelectorHeader`,
`ResponsiveCenter` are pure layout) and a security-rules fix (this
project has no Firestore-rules test harness, consistent with it being a
Flutter-only project without a Node/`firebase-tools` setup). All 144
existing tests re-verified passing after every change in this sprint.

**Running total: 144 tests, `flutter analyze` 0 issues.**

---

# Post-v1.0

Sprint 10 closed the original 10-sprint build plan. Everything below
happened afterward, driven first by `ROADMAP.md`'s staged post-v1 plan
(Sprints 11–19, mapping to that file's Stages 1–8 plus "Beyond v1"), then
by a series of full-project audits and a page-by-page product-polish pass
(dated phases, mapping to the entries under CLAUDE.md's own "Project
Memory and Progress" section). Numbering continues as "Sprint" for the
staged roadmap items since that's this file's own established unit; the
audit/polish phases after that are dated instead, since they weren't
pre-planned sprints but review-driven follow-up work — same convention
`ROADMAP.md`/`CLAUDE.md` already use for them.

## Sprint 11 — Google Sign-In & Auth Completeness ✅

Added `google_sign_in` end-to-end (datasource/repository/usecase/
controller, "Continue with Google" on Login and Register), matching every
other auth method's existing shape. Provider-aware account deletion: a
Google-only account re-authenticates via a fresh Google sign-in instead of
a password prompt. Verified on a real emulator — tapping "Continue with
Google" opens the real account picker. Firebase Console: Google provider
enabled, debug keystore SHA-1 registered at the time (release-keystore
SHA-1 registered later, alongside Sprint 16's real signing setup).
**Known follow-up, closed later during beta testing (see `TODO.md`)**: a
real bug shipped in early beta builds —
`GoogleSignInExceptionCode.clientConfigurationError` ("serverClientId must
be provided on Android") because `google_sign_in`'s Android
auto-detection of `default_web_client_id` wasn't firing; fixed by passing
the web-client OAuth ID explicitly to `GoogleSignIn.instance.initialize()`.
iOS-side Google Sign-In setup remains open — no Mac in any environment
this project has used (full checklist in `TODO.md`).

**Test count not separately recorded for this stage** — `ROADMAP.md`'s
Stage 1 note doesn't give one, and Sprint 12 below reports its own total
(150, including 3 new tests it added), so this stage's count can't be
reconstructed without guessing. `flutter analyze`: 0 issues.

## Sprint 12 — Design System Compliance Pass ✅

Closed every concrete inconsistency a design-system audit found —
hardcoded colors, magic-number spacing/radius, legacy `Icons.*`, one bare
spinner — across Accounts, Budget, Categories, Reports, Transactions, and
Dashboard. Built the `core/widgets` that were confirmed missing at the
time: `AppCard`, `SecondaryButton`/`DestructiveButton`, `AppDialog`
(`.confirm()` helper collapsing 5 near-identical delete dialogs into one
call each), `AppBottomSheet`, `AppChip`, `AppBadge` (replacing 3 duplicated
inline badge implementations), a real skeleton loader
(`AppSkeletonList`/`AppSkeletonListTile`/`SkeletonBox`), and
`ChartLegendDot`/`AppChartStyle` (shared chart-legend component).

**Tests:** +3 (skeleton loader widget tests). **Running total: 150
tests, `flutter analyze` 0 issues.** Not independently verified on-device
this pass — this is the sprint where the first Android-autofill incident
happened (a fresh test-account sign-in attempt had Android's autofill
silently substitute different account details into the registration form
before it could be caught, creating an unintended real Firebase user that
had to be cleaned up manually) — recorded here since it's the origin of a
standing project rule: an agent should never type into auth forms during
on-device verification; the project owner drives sign-in manually instead.

## Sprint 13 — Motion System ✅

Delivered the design system's "motion is first-class" requirement,
previously entirely unbuilt: `AppMotion` duration/curve tokens; app-wide
`PageTransitionsTheme` (`FadeForwardsPageTransitionsBuilder` on
Android/desktop, native Cupertino on iOS/macOS) giving every `go_router`
push/pop a subtle transition for free; `AppDialog`/`AppBottomSheet` now
pass `AppMotion` timing; bottom-nav tab switches cross-fade
(`AnimatedSwitcher`) instead of instant-swapping; Dashboard's `StatCard`
counts smoothly between values (`TweenAnimationBuilder`) instead of
snapping. Confirmed on-device for the route-transition piece (Login →
Register → back, both directions, no crashes); the tab-switch and
balance-count pieces used standard documented Flutter APIs but weren't
separately confirmed on-device this pass.

**Running total: 150 tests, `flutter analyze` 0 issues** (widget-only
changes, no new test cases this stage).

## Sprint 14 — Transfers (Core Feature Completeness) ✅

Closed the largest pre-v1.1 product gap: `TransactionType` gained
`transfer` (a single document with `accountId` source + `toAccountId`
destination, no `categoryId`). Every existing Dashboard/Reports/Budget
aggregation usecase already filtered to `income`/`expense` only, so a
transfer is excluded from every one of those totals for free — no changes
needed there. The real work was
`transaction_remote_datasource.dart`: a unified `_deltasFor()` helper
computing per-account balance deltas for any transaction shape (one
account for income/expense, two for transfer), with `updateTransaction`
netting the old shape's reversed deltas against the new shape's deltas —
correctly handling plain edits, account changes, amount changes, and
transfer↔income/expense conversions in either direction, all in one
algorithm instead of special-cased branches.

`firestore.rules`: `categoryId`/`toAccountId` always present as strings
(empty for whichever doesn't apply), rules require the right one present
for each type plus `toAccountId != accountId`. Account delete-guard
extended to also check `toAccountId`. UI: a third "Transfer" segment in
the transaction form, "To account" picker restricted to the same currency
as the source and excluding the source itself (per this project's
never-mix-currencies rule); `transaction_tile.dart` shows transfers with
their own icon, a neutral amount color, and "Transfer to X"/"From Y" text.

**Tests:** +12 (transfer balance-delta scenarios — the highest-value
place in the app for thorough coverage, so tested directly rather than
just asserted by inspection). **Running total: 163 tests, `flutter
analyze` 0 issues.** Not verified on-device this pass (reaching the
transfer form requires signing in first — deliberately skipped rather
than risk repeating Sprint 12's autofill incident); the money-correctness
logic has thorough automated coverage instead.

## Sprint 15 — Full Bilingual Coverage ⚠️ Complete pending native review

Extracted and translated every remaining hardcoded string (Accounts,
Transactions, Categories, Budget, Reports, the rest of Settings, Profile,
the bottom-nav shell, shared icon/color picker fields) into
`app_en.arb`/`app_lo.arb`. Migrated the shared `Validators` utility to
take `BuildContext`/`AppLocalizations`, updating every call site. **Fully
on-device verified with the Lao locale forced** — the project owner
signed in manually (Google, sidestepping the autofill risk) and swept/
screenshotted every screen. That pass caught a real bug: `DateFormat`
output (every month/date label app-wide) wasn't following the in-app
language toggle, because `Intl.defaultLocale` — a separate global from
`MaterialApp`'s `locale:` — was never being set. Fixed in `lib/app.dart`.

**Running total: 163 tests, `flutter analyze` 0 issues.** One deliverable
remains, unchanged since: a native Lao speaker has never reviewed
`app_lo.arb` — every Lao string added across every subsequent phase is
still a draft (see `TODO.md`).

## Sprint 16 — Production Hardening ✅ (Android)

Real Android release signing: a generated upload keystore + `key.
properties` (both gitignored), wired into `android/app/build.gradle.kts`
with a debug-signing fallback for CI. Verified end-to-end at the time —
`flutter build apk --release`/`flutter build appbundle --release` both
produced artifacts genuinely signed with the upload key (confirmed via
`apksigner verify --print-certs`). Added `.github/workflows/ci.yml`
(`flutter analyze` + `flutter test` on every push/PR). Added the first
widget/integration test layer for login, add-transaction, and Dashboard
totals — 169 tests total. `PRIVACY_POLICY.md` written, cross-checked
against what Firebase Auth/Firestore/Crashlytics actually collect at the
time. Confirmed (not re-done) that account deletion already correctly
blocks/handles transactions referencing the account, from Sprint 14's
transfer work. iOS release signing/App Store Connect remain untouched —
this project has only ever been built/signed for Android.

**Running total: 169 tests, `flutter analyze` 0 issues.**

## Sprint 17 — Store Readiness & Launch (in progress, gated on owner approvals)

`ROADMAP.md`'s Stage 7 — Play Console/App Store Connect listings, closed
beta rollout, crash-free-rate monitoring — has not itself been executed
as a discrete sprint; instead, its prerequisites and tooling were built
out over the phases below (a full manual release pipeline, store-listing
docs (`STORE_CHECKLIST.md`/`STORE_LISTING.md`), a free-tier-compatible
distribution design). No real public release has gone out yet on any
platform — see the **Release** section at the end of this file for exact
current status and what's still gated on explicit owner approval.

## Sprint 18 — Savings Goals (v1.1) ✅

First net-new feature past v1: a savings goal links 1:1 to a dedicated
account, so progress is that account's live balance — never a
separately-summed ledger that could drift. A "contribution" is an
ordinary transfer into the goal's account, reusing Sprint 14's atomic
transaction machinery unchanged. Full vertical slice
(`lib/features/savings_goals/`): entities/repository/usecases (create,
update, archive/unarchive, delete, live progress, a completion-date
estimate, contribute), Firestore datasource + rules (new `savingsGoals`
collection; account delete-guard extended so an account backing an
active goal can't be hard-deleted), providers/controller, and screens
(list, create/edit form, detail with a progress ring + account-activity
history reusing `TransactionTile`, a one-shot confetti celebration on
completion). Auto-contribution reminders reuse the existing
local-notification plumbing and `notificationsEnabled` toggle. Reached
via an icon button from Dashboard, not a 7th bottom-nav tab.

**Four real bugs found and fixed only by on-device testing** (see
`ROADMAP.md`'s Stage 8 entry for full root-cause detail on each): (1) an
app-wide theme-construction crash on cold start (`ThemeData.light()/
.dark().textTheme` returning null `fontSize` outside a `BuildContext` on
Flutter 3.44.6) — fixed by explicitly rebuilding the Material 3
typography merge, and bundling Manrope + Plus Jakarta Sans as local
assets in the same pass, removing `google_fonts` entirely; (2) a
`DropdownButtonFormField` orphan-value crash on goal creation; (3) Goal
Detail's account-activity section could get stuck loading forever, from
a non-`autoDispose` `StreamProvider.family` keyed on millisecond-precision
`DateTime.now()` minting a fresh, never-disposed Firestore listener on
every emission — fixed by truncating the key to day granularity; (4)
deleting a goal from Detail's menu left the screen stranded on an error
view instead of returning to the list, a "Ref used after dispose" race
between the `autoDispose` controller and the screen's error-state
transition — fixed by guarding `state = ...` writes with
`if (ref.mounted)`.

**On-device verified**: full mutation flow (create/edit/archive/
unarchive/delete/contribute, including a real same-currency
contribution), the completion-celebration animation, dark mode, and the
Lao locale's graceful English fallback (before this feature's own
translations existed — later completed as a draft, ~44 keys). **Still
not verified**: auto-contribution reminder notifications actually firing.

**Tests:** +33 (feature's own datasource/model/repository/usecase/widget
layers) + 2 new cases on `account_remote_datasource_test.dart`.

## Sprint 19 — Beyond v1: Export, Multi-currency Reporting, Biometric
Lock, Sync Status, Push Notifications, Analytics ✅

Everything `ROADMAP.md` originally staged as "future" shipped ahead of
Stage 7 rather than after it, driven partly by real beta-testing on
hardware:

- **CSV export** shipped, built on `MonthlyReport.toExportRows()`'s
  stable row shape (Sprint 7). PDF remains open (`TODO.md`).
- **Multi-currency reporting rollups** shipped
  (`lib/features/exchange_rates/`) — a daily rate snapshot from
  ExchangeRate-API's free endpoint, rolled up via
  `ConvertReportTotalsUseCase` into one figure in the user's default
  currency; raw amounts stay currency-exact everywhere else.
- **Biometric/PIN app lock** shipped via `local_auth`.
- **Sync-status indicator** shipped — an "offline — changes will sync"
  banner backed by Firestore's own `includeMetadataChanges` snapshot
  metadata, not a separate connectivity check.
- **Push notifications (FCM)** shipped as a hybrid backstop, not a
  replacement for the existing local (on-device) budget/negative-
  balance/goal-reminder alerts. First-ever non-Flutter component in this
  repo: a TypeScript Cloud Functions backend (`functions/`) — five
  functions (`onTransactionWrite`/`onBudgetWrite`/`onAccountWrite`/
  `checkGoalReminders`/`onUserDeleted`), deduplicated against the local
  path via a client presence heartbeat
  (`lib/core/providers/presence_providers.dart`) and a durable
  `notificationState` doc mirroring the client's own alerted-state
  transitions. Pushes are sent data-only so both foreground and
  background delivery render through the same Dart content-building code
  local alerts already use. Full design, accepted gaps (session-scoped
  local dedup has no memory of a push that fired while closed), and what
  remains unverified (a genuine force-close → push delivery, not just
  foreground local alerts) are in `ROADMAP.md`'s "Beyond v1" section.
  **Live deployment status of this backend is unverified** — Cloud
  Functions 2nd-gen requires the paid Blaze plan, which conflicts with
  this project's Spark-only policy pending explicit owner approval (see
  `docs/CLOUD_FUNCTIONS_STATUS.md`, added during the 2026-07-31
  completion-mission phase below).
- **Analytics** shipped — `firebase_analytics`, disabled in debug builds
  the same way Crashlytics already is, automatic screen-view tracking,
  and a deliberately curated set of creation/login/signup events with no
  amounts, names, or other financial detail ever logged.

Both still owed as console-only actions, not code: updating the Play
Store Data Safety form for both Analytics and push-notification data
collection.

---

# Post-v1.1 audits, hardening, and product polish

Everything below is dated, review-driven follow-up work rather than a
pre-planned sprint — full detail for each lives in the corresponding
entry under CLAUDE.md's "Project Memory and Progress" section; this is
the condensed progress-log version.

## 2026-07-29 — Free-tier manual release pipeline (redesigned)

Replaced an earlier paid/protected-environment release design with a
manual Firebase Spark + GitHub Free one: a private source repository
stays separate from a future owner-approved public distribution
repository; a fail-closed `assets/release/distribution_policy.json`
(unconfigured by default, so no public APK download can be enabled by
accident); local preparation/publish/website-metadata/rollback tooling
under `tool/`, none of it run yet to actually publish anything. GitHub
Actions stayed strictly read-only (no signing material, no release-write
scope). Full validation in CLAUDE.md's own dated entry; nothing here
changed a public download.

## 2026-07-29 — Post-audit Phase 1: account-currency & transfer-currency correctness ✅

A full project audit found two High-severity, pre-existing money-
correctness gaps: `accounts.currencyCode` was editable after creation and
unpinned in `firestore.rules` (silently reclassifying every historical
transaction/budget/report tied to that account), and a transfer's
same-currency requirement was enforced only in the form UI, never in
rules. Both closed: `currencyCode` removed entirely from the
`updateAccount` call chain (account form now shows currency as a locked
field once created) and pinned unchanged in rules; transfers now require
a `get()`-verified currency match between source and destination both in
`firestore.rules` and as datasource-layer defense-in-depth. **Tests:**
+5-ish across account/transaction datasource and repository layers.
`flutter test`: 371 passing.

## 2026-07-29 — Post-audit Phase 2a: localize Smart Money Score card chrome ✅

~65 hardcoded English strings in `financial_insight_card.dart` (section
headers, status badges, breakdown-sheet labels, formula footnote) routed
through `AppLocalizations` — ~68 new ARB keys. Dynamic engine-generated
text (headline/explanation/actions/reasons) deliberately deferred to 2b,
since restructuring it needed a real architecture change, not a
mechanical string swap. `flutter test`: 371 passing (harness fix only,
no new cases).

## 2026-07-29 — Post-audit Phase 2b: structured Smart Money Score messages ✅

Gave the domain layer a framework-free structured-message type
(`FinancialInsightMessage`: a 91-key enum + args map) so
`rule_based_financial_insight_engine.dart` and
`short_horizon_balance_movement_calculator.dart` stop producing raw
English strings; the presentation layer renders them through
`AppLocalizations` via an exhaustive switch in
`financial_insight_card.dart`. The persisted, auditable
`SmartMoneyScoreCalculation.reasons`/`baselineNote` fields remain
English-only by deliberate, documented scope boundary (a schema-migration
question, not this phase's job) — rendered through a `literal` passthrough
key. 92 new ARB keys. **Tests:** assertions across the engine/calculator
tests rewritten to check `.key`/`.args` instead of English substrings
(more resilient to future copy tweaks). `flutter test`: 371 passing.

## 2026-07-29 — Post-audit: report currency partial-conversion signal ✅

`ConvertReportTotalsUseCase` silently dropped any individual currency
lacking an exchange rate while still returning a total that looked
complete. Fixed: `ConvertedMonthlyTotals` gained `excludedCurrencyCodes`
+ a derived `isPartial` getter; the Reports screen now shows a warning
row naming the excluded currencies whenever a total is partial. **Tests:**
+1. `flutter test`: 372 passing.

## 2026-07-29 — Product polish Phase 1: Dashboard ✅

First phase of a page-by-page "complete product polish" pass. Added
Quick Actions to the mobile/compact dashboard (desktop already had it),
replaced its mismatched button styling with four equal-weight
`_QuickActionTile`s in a reflowing grid, localized ~20 remaining strings,
and swept 19 raw `Icons.*` references to `AppSymbols.*` (14 new
constants). **Tests:** dashboard suite 9/9 passing, `flutter build web
--release` clean. Not visually verified on-device this phase.

## 2026-07-30 — Product polish Phase 2: Transactions ✅

Kept the existing (already solid) mobile search/filter system as-is.
Added: a three-dot Edit/Duplicate/Delete menu on `TransactionTile`
(replacing the old permanent delete icon, app-wide across every screen
embedding this shared tile); a genuinely new **duplicate transaction**
feature (`duplicateFrom` prefill on the transaction form, submits as a
create, date deliberately not copied); desktop summary cards (Income/
Expense/Net/Count) computed from whatever the current filter already
narrowed the list to. 11 new `AppSymbols` constants. **Tests:** full
suite 372/372, with two real bugs caught by the existing test suite at
wide-layout widths (a `RenderFlex` overflow, a `PopupMenuButton` sizing
issue) — fixed, not just noted.

## 2026-07-30 — Product polish Phase 3: Accounts ✅

Added a responsive `LayoutBuilder`-driven grid (1–3 columns), a genuine
"Negative" balance badge (color was previously the only signal — fixed
per this project's own accessibility rule), and a per-currency
percent-of-total-balance caption on each account card. Extended the
shared `AppBadge` with an optional `color` param rather than a one-off.
**Tests:** 372/372 unchanged (no new coverage added for the new badge/
percentage — flagged as a real, still-open gap).

## 2026-07-30 — Release manifest: schema-v3 generator bug fix + version history ✅

Found and fixed a real pre-existing defect while building version
history: `tool/generate_release_manifest.dart` hardcoded
`schemaVersion: 2` while every validator has required `3` since Phase 1's
currency-integrity work — any manifest this script produced would have
silently failed every trust check and never unlocked a real public
download button. Fixed to emit the real constant. Added `ReleaseManifest.
history` (up to 10 prior releases, same trust-chain validation as the
current release but per-entry drop-on-failure rather than whole-manifest
rejection) and a landing-page version-history section. **Tests:** +8.
`flutter test`: 380 passing.

## 2026-07-30 — Release/website-sync spec audit ✅

Audited a detailed release/website-sync spec against the existing
implementation — found it already matched on the required flow and
fail-closed behavior. Two real gaps: added a "View full release notes on
GitHub" link (gated to the verified latest-stable release only), and
confirmed with the owner that the bundled offline-fallback manifest asset
stays deliberately outside the trust chain (no code change). **Tests:**
+1. `flutter test`: 380 passing. No release was pending or executed.

## 2026-07-30 — Website-only content deploy carve-out (policy + script) ✅ (never run)

Added a narrow, pre-approved deploy path for website-*content*-only
changes (landing page, legal pages, FAQ, static assets, web-only bug
fixes) via `tool/deploy_website.ps1` — refuses to run if the change
touches any release-trust path (`web/release-manifest.json`,
`assets/release/**`, Android signing/version files), runs the full
analyze/test/build sequence, confirms the Hosting target, then verifies
the live site after deploying rather than trusting a clean exit code.
Application binaries, the Download section's actual release data, and
all Git actions remain fully manual/approval-gated — this carve-out
changes nothing about those. **Never actually run** — this environment's
`firebase` CLI has no authenticated session.

## 2026-07-31 — Product polish Phase 4: Budgets ✅

Added the same responsive grid pattern, a month-total summary header
(Budgeted/Spent/Remaining per currency), a percent-used label combined
with the existing remaining/overspent text, and a third "approaching
limit" (≥80%, not yet overspent) progress-bar state — closing the same
color-only-meaning gap Accounts' negative badge closed. Rebuilt
`_NoBudgetTile` on `AppCard` for visual consistency with the new grid.
**Tests:** +3 (first coverage `BudgetProgressTile` and the summary header
had ever had). `flutter test`: 383 passing.

## 2026-07-31 — Product polish Phase 5: Categories ✅

Swept the remaining `Icons.*` uses (2 new `AppSymbols` constants:
`dragHandle`, `labelOutline`), fixed the archive-toggle icon to match
Accounts' single-glyph tinted pattern, and added a "Default" badge +
explanatory helper text when editing a default category (previously the
delete restriction had no visible explanation). Deliberately did **not**
add a responsive grid (this list is drag-to-reorder, which doesn't have
unambiguous 2D-grid semantics) or a transaction-count-before-delete
safety check (needs a new aggregate-query capability, out of scope).
**Tests:** +3 (first coverage `category_form_screen.dart` had ever had).
`flutter test`: 386 passing.

## 2026-07-31 — Product polish Phase 6: Settings ✅

First full pass on Settings. Added an Account section (linking back to
Profile — previously one-directional from Dashboard only) and an About
section (`CashlyLogoMark` + app name + version via a new
`packageInfoProvider`/`package_info_plus` dependency + Privacy Policy/
Terms links) — closing a branding gap CLAUDE.md had already flagged as
unapplied. Added a confirmation dialog before disabling app lock (a
security-relevant toggle that previously flipped silently), and an
explanatory line where Security/Notifications sections vanish on web
instead of just disappearing unexplained. 4 new `AppSymbols` constants.
**Tests:** +1. `flutter test`: 387 passing. `profile_screen.dart`'s own
remaining `Icons.*` violations were identified but deliberately left for
a future Profile-specific pass (different feature, out of this phase's
scope).

## 2026-07-31 — Reports functionality phase: filters, insights, account breakdown, transaction list, Expense Watch ✅

The functional core of a larger Reports redesign (PDF export and
cloud-based detection explicitly deferred). Added: date-range/account/
category/type filters (`ReportFilter` + `reportFilterProvider`); four new
summary metrics (savings rate, average daily spend, top category,
month-over-month change) via `ComputeReportInsightsUseCase`; an account-
breakdown donut chart (`AccountPieChart`, same hand-rolled
`CustomPainter` approach as the existing category chart — no new
charting dependency); a read-only detailed transaction list
(deliberately not a reuse of the editable `TransactionTile` — Reports is
analysis, not a second place to edit data); and **Expense Watch** ("Keep
an Eye On") — three fixed, deterministic, on-device heuristics (no ML,
no cloud call) flagging a single unusually large transaction, several
same-amount transactions in quick succession (likely duplicate charge),
or a category trending well above its own average.

A real design decision surfaced mid-build: **Budget vs Actual must never
be narrowed by the report's own display filter** — a budget's real spend
has to reflect the whole month regardless of which account a user is
currently viewing Reports through, so `BuildMonthlyReportUseCase` now
takes the filtered transaction list and a separately-always-unfiltered
one explicitly. **Tests:** +22 (12 of them on Expense Watch's three
heuristic branches — the most novel logic this phase, most thoroughly
covered). `flutter test`: 409 passing.

## 2026-07-31 — Permanent multi-platform release procedure + Android AAB build (documented; not yet run)

Generalized the Android-specific manual release policy into a standing,
criteria-based procedure covering whichever platforms actually satisfy
four "release-ready" tests: scaffolding exists, a real local build has
succeeded, signing is genuinely configured, **and** a distribution
channel is approved. `tool/prepare_manual_release.ps1` now builds both
the APK and the AAB; the AAB is checksummed as local evidence for future
Play Store readiness but deliberately never enters the public trust
chain (Play Store itself generates installable APKs from an AAB at
install time — nothing should ever link to the AAB directly).
**Android is not yet release-ready by this procedure's own fourth
criterion** — `assets/release/distribution_policy.json`'s `repository`
field is still `null`, so no public distribution channel has actually
been approved; the APK/AAB build-and-signing tooling is prepared and
scaffolding/build/signing (criteria 1–3) are satisfied, but publishing
still requires that approval first, exactly as the **Release** section at
the end of this file states. iOS/Windows/macOS/Linux remain fully
unconfigured — no signing material, no accounts, no Mac in any
environment used so far. **Not exercised end-to-end** — no real release
tag, keystore use, or actual build attempt this phase.

## 2026-07-31 — Completion-mission Phase 1: privacy/security/data-integrity fixes + Android/Web hardening ✅

The "Immediate Confirmed Audit Fixes" from a larger external completion
spec, closed in one continuous session (the full 28-section mission is
explicitly scoped far beyond one session — see CLAUDE.md's own entry for
what remains open). Fixed:

1. Account deletion was missing `savingsGoals` and `smartMoneyScores`
   from its collection-deletion loop.
2. Corrected a real, previously undocumented contradiction — this
   project's own docs claimed "no backend of our own" while `functions/`
   has been a genuine 2nd-gen Cloud Functions backend since the FCM work
   (which requires the paid Blaze plan). Investigated and documented
   rather than guessed (`docs/CLOUD_FUNCTIONS_STATUS.md`); live
   deployment status remains genuinely unknown from this environment.
3. Logout never cleared Firestore's local persistence cache — a second
   person signing into the same device could read the previous user's
   cached financial data. Fixed: logout now waits (bounded, 8s) for
   pending offline writes to sync, refusing rather than discarding an
   unsynced write if it can't confirm, then clears the local cache;
   account deletion does the same. Added error handling to the
   previously-bare sign-out button.
4. Web gained security headers (`X-Content-Type-Options`/`X-Frame-
   Options`/`Referrer-Policy`/`Permissions-Policy`/HSTS/a scoped CSP
   built from the app's actual Firebase/Google dependencies) and a
   `theme-color` fix (a stale green, not the real brand blue).
5. Confirmed no custom service-worker code exists — Flutter's own
   content-hashed default web loader was already the right call,
   documented as deliberate rather than left unexplained.
6. Android gained R8/resource shrinking + `allowBackup="false"` — **but
   this specific environment had no Android SDK at the time**, so the
   change was never actually built or device-tested (flagged explicitly,
   not reported as verified — see `TODO.md`).
7. Built the first Firestore rules-emulator test harness
   (`firestore-tests/`, 19 tests against a real local Firestore
   Emulator) — this project had never had automated rules coverage
   before, only manual review.
8. Fixed the 2 `Icons.*` uses in `reports_screen.dart` already flagged as
   a specific deferred item; catalogued (not fixed) the other 85 across
   16 more files in `TODO.md`, deliberately not rushed given several are
   high-blast-radius shared widgets.

**Tests:** +3 on `auth_remote_datasource_test.dart` (logout/cache-clear
behavior), plus the 19 new Firestore rules-emulator tests (a separate
Node/Jest suite, not counted in the Flutter `flutter test` total).
`flutter test`: 412 passing. `flutter build apk --release` was attempted
and genuinely failed (`No Android SDK found`) — recorded here so it's
never mistaken for a passing build.

---

## Release

No real public release has gone out on any platform yet. Version in
`pubspec.yaml`: `1.0.2+3`. Every platform in `assets/release/
distribution_policy.json`/the landing page's manifest is still
`coming_soon`, which — per repeated audits above — is confirmed accurate
to current reality, not stale: `distribution_policy.json`'s
`repository` field is still `null` (no public distribution repository
has been approved), and no signed Android build has ever gone through
the full manual pipeline end-to-end.

**What's built and ready, pending the standing two owner-approval gates**
(see CLAUDE.md's "Free-tier manual release policy" / "Multi-platform
release procedure"): local Android APK+AAB build/checksum tooling, a
fail-closed distribution-policy + manifest trust chain, a public-release
publish script, a website-metadata deploy script, a rollback script, and
a pre-approved narrow carve-out for website-*content*-only deploys
(never yet exercised — no authenticated `firebase login`/`gh auth`
session has existed in any environment this project has used).

**What's still fully open**: iOS (never built — no Mac, no iOS OAuth
client, no `Podfile`), Windows/macOS (no signing certificates, no Apple
Developer account), Linux (not even a configured Flutter target), Play
Store/App Store listing submission, the Cloud Functions Blaze-upgrade
decision, and a native-speaker review of `app_lo.arb`.

See `RELEASE_NOTES.md` for the full user-facing feature summary and
`TODO.md` for the complete, itemized list of what's deliberately deferred
and why.
