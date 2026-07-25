# Cashly — Project Progress

Tracks what's actually been built, sprint by sprint, against the project's
Clean Architecture (feature-first, Riverpod, Firebase, GoRouter) plan.
Updated at the end of every sprint.

**Stack:** Flutter 3.44.7 / Dart 3.12.2, Firebase (Auth, Firestore),
Riverpod 3, GoRouter 17, fpdart (`Either`/`Unit` for error handling).

**Verification baseline** (true as of the end of every sprint below):
`flutter analyze` → 0 issues. `flutter test` → all passing. No Android
SDK/Xcode is available in the build sandbox, so native APK/IPA builds
have not been produced there — `flutter analyze` + `flutter test` are the
compilation/correctness signal until a build is run on a machine with the
native toolchains.

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

## Release

v1.0 is feature-complete against the original 10-sprint build plan. See
`RELEASE_NOTES.md` for the full user-facing feature summary and
`TODO.md` for what's deliberately deferred to a post-v1.0 release.
