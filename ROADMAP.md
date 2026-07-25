# Cashly — Development Roadmap

This roadmap replaces the earlier ad hoc "5-phase redesign sprint" plan
(Theme foundations → Component library → Screen redesign → Branding →
Final verification). That plan was written before a full project audit
existed; this one is written after one, against the current, verified
state of the codebase (see the project-analysis and design-verification
findings this roadmap accompanies). Where the old plan is still correct
it's absorbed into a stage below; where it assumed more or less work
than actually remains, this roadmap corrects it. Concretely: the old
Phase 1 (theme/tokens) and Phase 4 (branding) are genuinely done and are
not repeated here; the old Phase 2/3/5 (component library, screen
redesign, final verification) are folded into Stage 2 below, scoped to
what the design-system audit actually found rather than a blanket
"redesign everything" pass.

Update this file as stages complete or scope changes — it's a living
document, same as `TODO.md` and `PROJECT_PROGRESS.md`.

---

## Stage 1 — Authentication Completeness ✅ Complete

**Objective**: Bring authentication to full production parity: every
method the product vision calls for, wired end-to-end, following
platform best practices.

**Status**: Done, verified end-to-end on a real emulator. Google
Sign-In is fully implemented — `google_sign_in` wired into the
datasource/repository/usecase/controller layers exactly like every
other auth method, a "Continue with Google" button on both Login and
Register, provider-aware account deletion (a Google-only account
re-authenticates via a fresh Google sign-in instead of a password),
and localized strings (English/Lao draft). The Google provider is
enabled in Firebase Console (public name "Cashly Lao"), the debug
keystore's SHA-1 is registered, and the re-downloaded
`google-services.json` now carries both the Android and web OAuth
client entries. Tapping "Continue with Google" now opens the real
Google account sign-in screen rather than erroring — confirmed on the
emulator. Remaining, not blocking: register the **release**-keystore
SHA-1 once Stage 6's real signing config exists, and add the
equivalent iOS `GoogleService-Info.plist`/URL-scheme setup when iOS
testing starts.

**Features**:
- Google Sign-In (real Firebase wiring, not UI-only) via `google_sign_in`
  + `GoogleAuthProvider.credential` / `signInWithCredential`, on both
  Android and iOS
- Verify existing email/password login, registration, forgot-password,
  and logout still integrate cleanly once Google is added as a second
  provider (e.g. an account created via Google shouldn't collide with
  one created via email)
- "Remember login" — confirm Firebase Auth's default persistence
  behavior actually matches user expectation on both platforms; make it
  explicit rather than assumed
- Secure-by-default session handling audit (token refresh, sign-out
  clears all local state)

**Deliverables**: `google_sign_in` integrated into
`auth_remote_datasource.dart`/`auth_repository_impl.dart` following the
existing repository pattern; a "Continue with Google" button on
Login/Register wired to it; updated `firestore.rules` comment/behavior
check for provider-agnostic user documents; tests for the new usecase
and repository paths; a short doc note on what Firebase Console / native
config (SHA-1 fingerprint registration, OAuth consent screen) is
required and was or wasn't completed, since some of that is
account-console work no code change can substitute for.

**Dependencies**: `google-services.json` / `GoogleService-Info.plist`
already present (Firebase project exists). Requires the Google
Sign-In provider to be enabled in Firebase Console and, for Android,
the app's SHA-1 certificate fingerprint(s) registered there — both are
Firebase Console actions, not something achievable from the codebase
alone.

**Estimated difficulty**: Medium.

---

## Stage 2 — Design System Compliance Pass ✅ Complete

**Objective**: Close every concrete inconsistency the design-system
audit found, and build the small set of shared components screens
actually need but don't have yet — not a ground-up redesign, since the
Phase 1 tokens (colors, typography, spacing, radius, elevation, icons)
are already in place and already correct where they've been applied.

**Status**: Done. Audit-flagged inconsistencies (hardcoded colors,
magic-number spacing/radius, legacy `Icons.*`, one bare spinner) fixed
across Accounts, Budget, Categories, Reports, Transactions, and
Dashboard. Built the confirmed-missing `core/widgets`: `AppCard`,
`SecondaryButton`/`DestructiveButton`, `AppDialog` (a `.confirm()`
helper consolidating 5 near-identical delete-confirmation dialogs down
to one call each), `AppBottomSheet`, `AppChip`, `AppBadge` (replacing 3
duplicated inline badge implementations), a real skeleton loader
(`AppSkeletonList`/`AppSkeletonListTile`/`SkeletonBox`, now used by
Accounts/Budget/Categories/Transactions' loading states instead of a
bare spinner), and a shared chart-legend component (`ChartLegendDot` +
`AppChartStyle`) consolidating Reports' pie and trend chart legends.
`flutter analyze`: 0 issues. `flutter test`: 150/150 passing (3 new
widget tests for the skeleton loader). **Not independently verified
on-device this pass** — an attempt to sign in a fresh test account for
visual verification was aborted after Android's autofill silently
substituted different account details into the registration form and
it submitted before that was caught (a real, unintended Firebase user
was created and is being cleaned up by the project owner). Every
change here is a structurally identical substitution of already
visually-confirmed markup (same `Card`/`InkWell`/`AlertDialog`/
`Container` trees, just deduplicated), except the skeleton loader,
which is genuinely new UI and should get a real on-device look when
convenient.

**Dependencies**: the design-verification audit's findings (this
session).

**Estimated difficulty**: Medium-High — touches many files, but every
change follows an established, low-risk pattern (swap a literal for a
token) rather than new design work.

---

## Stage 3 — Motion System ✅ Complete

**Objective**: Deliver on the design system's "motion is first-class"
requirement, currently entirely unbuilt.

**Status**: Done. Added `AppMotion` (duration/curve tokens). App-wide
`PageTransitionsTheme` in `app_theme.dart` (`FadeForwardsPageTransitionsBuilder`
on Android/desktop, native Cupertino on iOS/macOS) gives every
`go_router` push/pop a subtle fade+scale for free — confirmed working
on-device both directions (Login → Register → back) with no crashes.
`AppDialog`/`AppBottomSheet` now pass `AppMotion` timing via
`animationStyle`/`sheetAnimationStyle`. Bottom-nav tab switches
cross-fade instead of instant-swapping (`AnimatedSwitcher` around
`navigationShell`). Dashboard's `StatCard` (balance/income/expense
figures) counts smoothly between values via `TweenAnimationBuilder`
instead of snapping. `flutter analyze`: 0 issues. `flutter test`:
150/150 passing. The tab-switch and balance-count pieces specifically
weren't confirmed on-device this pass (would have required signing
in, and a prior sign-in attempt this session hit an Android-autofill
issue unrelated to this code — see Stage 2's status note) — both use
standard, common Flutter APIs (`AnimatedSwitcher`, `TweenAnimationBuilder`)
in their ordinary documented usage, so risk is low, but worth a real
look next time you're signed in.

**Deliverables**: new motion tokens (`AppMotion` or similar), updated
`app_theme.dart` and the specific screens/widgets that most benefit
(Dashboard balance updates, transaction list add/remove, bottom-sheet
open/close).

**Dependencies**: Stage 2's component work (bottom sheets/dialogs)
benefits from landing first so motion can be applied to real shared
components rather than screen-specific ones.

**Estimated difficulty**: Low-Medium.

---

## Stage 4 — Transfers (Core Feature Completeness) ✅ Complete

**Objective**: Close the single largest gap against the product vision —
`TransactionType` today is `income`/`expense` only, so moving money
between a user's own accounts has no correct representation.

**Status**: Done. Added `TransactionType.transfer` — a single
transaction document with `accountId` (source) and a new `toAccountId`
(destination), no `categoryId` (transfers aren't spending). This turned
out to require *no* changes to any of Dashboard/Reports/Budget's
aggregation usecases: every one of them already filtered with
`if (transaction.type != TransactionType.expense/income) continue`,
so a third type is automatically excluded from every income/expense/
category/budget total for free.

The real work was `transaction_remote_datasource.dart`: replaced the
old same-account/cross-account special-casing with a single unified
algorithm — a `_deltasFor()` helper returns the per-account balance
deltas for any transaction shape (one account for income/expense, two
for transfer), and `updateTransaction` nets the *old* shape's deltas
(reversed) against the *new* shape's deltas per account before writing.
This correctly and uniformly handles every case: plain edits, moving
either account, amount changes, and converting between transfer and
income/expense in either direction — all covered by new tests (12
added, covering exactly these scenarios) rather than asserted by
inspection alone, since this is the highest-value place in the app for
real test coverage.

`firestore.rules` updated: `categoryId`/`toAccountId` are always
present as strings (`''` for whichever doesn't apply) so the rule can
require a real `categoryId` and no `toAccountId` for income/expense, or
the reverse for a transfer, plus `toAccountId != accountId`.
`account_remote_datasource.dart`'s delete-guard now also checks
`toAccountId`, so an account can't be hard-deleted while it's a
transfer's destination. UI: a third "Transfer" segment in the
transaction form swaps the category picker for a "To account" picker,
restricted to accounts in the **same currency** as the source (Cashly
never mixes currencies without a conversion — see CLAUDE.md's Coding
Standards) and excluding the source itself; `transaction_tile.dart`
shows transfers with their own icon, a neutral (non green/red) amount
color, and "Transfer to X" / "From Y" text.

`flutter analyze`: 0 issues. `flutter test`: 163/163 passing.
**Not verified on-device this pass** — reaching the transfer form
requires signing in first, which is the exact step that triggered the
Android-autofill incident during Stage 2 (see that stage's status
note), so this was deliberately skipped rather than risk a repeat. The
money-correctness logic (the part that actually matters here) has
thorough automated coverage instead; the UI itself follows the same
patterns as the rest of the form, which *is* already visually
confirmed.

**Deliverables**: entity/model/rules changes, an atomic
`firestore.runTransaction` implementation (following the existing
cross-account-and-type-flip pattern in
`transaction_remote_datasource.dart`), updated Dashboard/Reports
aggregation logic, full test coverage (this is money-correctness logic —
the highest-value place in the app for thorough tests), UI for
creating/editing/displaying a transfer.

**Dependencies**: none blocking — can start independently, but touches
enough shared aggregation logic (Dashboard summaries, Reports totals)
that it's safer after Stage 2's component work lands, to avoid
conflicting with in-flight visual changes to the same screens.

**Estimated difficulty**: High — the only stage that changes the core
money-movement data model, and correctness here matters more than
anywhere else in the app.

---

## Stage 5 — Full Bilingual Coverage ⚠️ Complete pending native review

**Objective**: Finish what Phase 1 started as a proof of concept —
every screen, not just Auth and Dashboard, fully localized.

**Features**: extract and translate hardcoded strings in Accounts,
Transactions, Categories, Budget, Reports, the rest of Settings, and
Profile into `app_en.arb`/`app_lo.arb`; localize the shared `Validators`
utility (requires threading `BuildContext`/`AppLocalizations` into its
signature — a real, if mechanical, breaking change to its call sites);
native-speaker review and correction of the existing draft Lao
translations, including any new ones added in this stage.

**Status**: `app_en.arb`/`app_lo.arb` now cover every screen (Accounts,
Transactions, Categories, Budget, Reports, Settings, Profile), plus the
bottom-nav shell and the shared icon/color picker fields, which the
initial sweep missed since they live outside any single feature
directory. `Validators` was migrated to take `BuildContext` with every
call site updated to match. **On-device verification with the Lao
locale forced is now done** — the project owner signed in manually on
the emulator (Google, to sidestep the autofill risk noted in `TODO.md`)
and every screen was swept and screenshotted. That pass also caught a
real bug no code review would have: `DateFormat`-produced text (every
month/date label in the app) wasn't following the in-app language
toggle at all, because `Intl.defaultLocale` — a separate global from
`MaterialApp`'s `locale:` — was never being set. Fixed in `lib/app.dart`.
`flutter analyze` (0 issues) and `flutter test` (all 163 tests) both
pass. One deliverable remains: native-speaker review of the
draft-quality Lao translations — see `TODO.md`'s Localization &
accessibility section.

**Deliverables**: complete `app_en.arb`/`app_lo.arb`, updated
`Validators` signature and all call sites, on-device verification with
the Lao locale forced for every screen (not just a code read).

**Dependencies**: ideally after Stage 2, so strings are extracted from
already-compliant screen code rather than being touched twice.

**Estimated difficulty**: Medium — large surface area, low technical
risk, but needs a real native Lao speaker for the review step (not
something that can be verified by code alone).

---

## Stage 6 — Production Hardening ✅ Complete (Android)

**Objective**: Everything currently blocking a real store submission
that isn't a user-facing feature.

**Features**:
- Real Android release signing (a generated upload keystore +
  `key.properties`, wired into `android/app/build.gradle.kts` in place
  of today's debug-signed release build) and, if using Play App
  Signing, the corresponding Play Console setup
- A GitHub Actions CI workflow running `flutter analyze` + `flutter
  test` on every PR (there is none today)
- A widget/integration test layer for the highest-value flows (login,
  add transaction, dashboard renders correct totals) — today's 163
  tests are entirely domain/data-layer
- Privacy policy + Play Store Data Safety form / App Store App Privacy
  details, matching what Firebase Auth/Firestore/Crashlytics actually
  collect

**Deliverables**: signed release build artifact (`.aab`/`.ipa`), CI
config file, new widget/integration tests, a privacy policy document.

**Status**: done, for Android.
- The "orphaned-transaction" item originally scoped for this stage —
  deleting an account should either cascade-delete its transactions or
  explicitly block deletion while transactions reference it — turned
  out to already be fixed (and tested:
  `account_remote_datasource_test.dart`'s "deleteAccount throws
  ServerException when transactions reference the account" /
  "...when a transfer targets the account as its destination"), most
  likely alongside Stage 4's transfer work. `CLAUDE.md`'s "Known gaps"
  section still listed it as unfixed — corrected there rather than
  re-doing work that was already done.
- CI: `.github/workflows/ci.yml` runs `flutter analyze` + `flutter
  test` on every push/PR to `main`.
- Widget/integration tests added for the three named flows: login
  (`test/features/auth/presentation/screens/login_screen_test.dart`),
  add transaction (`test/features/transactions/presentation/screens/
  transaction_form_screen_test.dart`), and Dashboard totals
  (`test/features/dashboard/presentation/screens/
  dashboard_screen_test.dart`) — 169 tests total, all passing.
- Real Android release signing: a generated upload keystore
  (`android/app/upload-keystore.jks`, gitignored) + `android/
  key.properties` (gitignored), wired into `android/app/
  build.gradle.kts` with a fallback to debug signing when the keystore
  isn't present (e.g. CI). Verified end-to-end — `flutter build apk
  --release` and `flutter build appbundle --release` both produce
  artifacts genuinely signed with the new upload key (confirmed via
  `apksigner verify --print-certs`), not the debug key. Play App
  Signing / Play Console enrollment itself is a Play Console action
  only the project owner can do — not something this covers.
- `PRIVACY_POLICY.md` — covers what Firebase Auth/Firestore/Crashlytics
  actually collect (cross-checked against `lib/main.dart` and the
  domain entities, not just accepted as given); no Firebase Analytics
  claim since the app doesn't use it. Submitting this to the Play Store
  Data Safety form / App Store App Privacy questionnaire is still a
  manual step in each store's console.
- **Not covered**: anything iOS-specific (release signing, App Store
  Connect, Play App Signing enrollment) — this project has only ever
  been built/signed for Android.

**Dependencies**: none blocking; can run partly in parallel with Stages
2-5, but should be the last stage completed before Stage 7, since it's
the actual store-submission gate.

**Estimated difficulty**: Medium — mostly configuration and process,
plus one real, bounded new test layer.

---

## Stage 7 — Store Readiness & Launch

**Objective**: Everything between "the app works" and "a real user can
install it."

**Features**: Play Console / App Store Connect listings (screenshots,
description, in both English and Lao), a closed-beta rollout to a small
real user group before public release, and a monitoring pass on
Crashlytics crash-free-rate and any beta feedback before promoting to
public release.

**Deliverables**: live Play Console / App Store Connect listing in
closed testing, a beta feedback log, a go/no-go decision for public
release with the actual crash-free-rate number behind it.

**Dependencies**: Stage 6 must be complete (can't submit an
unsigned/debug-signed build).

**Estimated difficulty**: Low-Medium — mostly coordination and
non-code work, but gated on real user feedback turnaround time, not
effort.

---

## Stage 8 — Savings Goals (v1.1)

**Objective**: First net-new feature past v1 — let a user set a savings
target, track progress against it, and optionally schedule a recurring
contribution reminder.

**Status**: Done, on-device verified (light mode, English — dark mode and
Lao locale verified separately below; only a native-speaker Lao review
and real reminder-notification firing remain open). A savings goal links
1:1 to a dedicated account; progress is that account's live balance,
never a separately-summed ledger, so it can't drift from the real
number the way a summed-contributions design could (if the user later
spends out of that account for something unrelated, a summed ledger
would keep showing the old, too-high progress). A "contribution" is an
ordinary transfer into the goal's account, reusing the existing atomic
transaction machinery unchanged — no changes to `TransactionEntity`, the
transaction datasource, or its Firestore rules. Full vertical slice
(`lib/features/savings_goals/`): entities, repository, usecases
(create/update/archive/unarchive/delete, live progress, a
completion-date estimate that prefers a configured auto-contribution
schedule and falls back to recent contribution pace, contribute),
Firestore datasource + rules (new `savingsGoals` collection, plus a
small additive guard on `account_remote_datasource.dart`'s delete so an
account backing an active goal can't be hard-deleted out from under
it), providers/controller, and screens (list, create/edit form, detail
with a progress ring, an account-activity history reusing
`TransactionTile`, and a one-shot confetti celebration on completion).
Auto-contribution reminders reuse the existing local-notification
plumbing (a new Android channel) and the existing `notificationsEnabled`
Settings toggle rather than a new one. Reached via an icon button from
Dashboard, not a 7th bottom-nav tab (same treatment as Reports).

`flutter analyze`: 0 issues. `flutter test`: all green — 33 new tests
across the feature's datasource/model/repository/usecase/widget layers,
plus two new cases added to `account_remote_datasource_test.dart`.

**On-device verification (Android emulator, light mode, English)**: the
core flow is confirmed working end-to-end against the live `cashly-lao`
Firestore project — create goal → list → detail (progress ring correctly
derived from the linked account's real live balance, not a separately-
summed figure) → contribute sheet (correctly disabled with no eligible
same-currency source account, confirming the currency filter works as
designed). Two real bugs surfaced and were fixed during this pass, both
outside what `flutter analyze`/`flutter test` could catch:
1. An app-wide theme-construction crash (`AppTheme._buildTheme`, a null
   `fontSize` on `ThemeData.light()/.dark().textTheme` when built outside
   a `BuildContext` on Flutter 3.44.6) — not specific to this feature,
   but this pass is what surfaced it. Fixed by explicitly rebuilding the
   Material 3 typography merge (`Typography.material2021(...).englishLike
   .merge(...black/.white)`) instead of relying on the implicit one. Also
   took the opportunity to bundle Manrope + Plus Jakarta Sans as local
   assets (matching the existing Noto Sans Lao pattern) instead of
   `google_fonts`' runtime fetch, removing that dependency entirely.
2. A `DropdownButtonFormField` orphan-value crash on goal creation (the
   create form's account dropdown could briefly hold a value the same
   rebuild had just excluded from `eligibleAccounts`) — fixed with a
   `_withOrphanFallback` helper in `savings_goal_form_screen.dart`,
   mirroring the existing pattern in `transaction_form_screen.dart`.
3. Detail's "Account activity" section got stuck on its loading spinner
   forever after a transient network drop. Root cause was in this
   feature's own code, not the network blip itself:
   `_goalActivityRange()` computed `endExclusive` from a millisecond-
   precision `DateTime.now()` and fed it into
   `transactionsInRangeProvider`, a plain (non-`autoDispose`)
   `StreamProvider.family` keyed on that value. Since the key is
   different on every rebuild, every emission from the stream minted a
   brand-new family instance — and therefore a brand-new live Firestore
   listener — while the previous instance, no longer watched by
   anything, was never disposed and kept running forever. When whichever
   instance happened to be live hit the network drop, nothing was left
   to ever retry it: the derived `Provider.family`
   (`goalAccountActivityProvider`) only recomputes when its current
   dependency emits, and that dependency was the dead listener. Fixed by
   truncating `endExclusive` to day granularity (matching the
   already-day-granular `twelveMonthsAgo` computation), the same
   stable-key approach `report_providers.dart` already uses by keying off
   the selected month rather than raw `now()`. On-device re-confirmation
   (fresh navigation to a goal's detail screen resolves the section
   cleanly, no error in logs) completed later in the same pass.
4. Deleting a goal from the Detail screen's menu left the screen
   permanently stranded on "Something went wrong — this goal no longer
   exists" instead of returning to the list, even though the delete
   itself had genuinely succeeded. Root cause:
   `savingsGoalControllerProvider` is `AsyncNotifierProvider.autoDispose`
   (matching `BudgetController`'s own pattern) — safe on the form screen,
   which keeps it alive via `ref.watch(...).isLoading` for its Save
   button, but the Detail screen's archive/unarchive/delete menu actions
   only ever `ref.read` the controller's notifier, never watch it. For
   delete specifically, the instant the goal disappears,
   `savingsGoalProgressByIdProvider` resolves to null, the screen swaps
   to its error view, nothing is left watching the controller, and
   Riverpod disposes it — right as `SavingsGoalController._run`'s
   `await action()` continuation resumes and tries to write the final
   `state`, throwing "Ref used after dispose" instead of ever returning
   `true`. `_confirmDelete`'s `await notifier.deleteGoal(...)` line never
   completes, so its `context.pop()` never runs. (Archive/unarchive hit
   the same disposed-ref throw but stayed invisible, since neither's
   post-success path does anything beyond an error-only snackbar — the
   live Firestore listener updates the UI independently either way.)
   Fixed in `savings_goal_controller.dart`'s shared `_run` helper by
   guarding each `state = ...` write with `if (ref.mounted)`, per
   Riverpod's own recommended fix for this exact class of race — the
   already-known success/failure result is still returned either way,
   only the now-moot state echo is skipped. `flutter analyze` (0 issues),
   `flutter test` (all `savings_goals` tests green), confirmed on-device
   that delete now correctly pops back to the list.

**On-device verification, full pass**: every mutation flow (create,
edit, archive, unarchive, delete, contribute — including a real
same-currency contribution once a second USD account existed to
contribute from) and the completion-celebration animation (confirmed via
temporary diagnostic logging that `AnimationController.forward()` fires
and the value genuinely progresses 0→1; earlier "no confetti visible in
screenshots" was a screenshot-timing artifact of manual ADB testing, not
a product bug) are now confirmed working end-to-end in light mode,
English locale, against the live `cashly-lao` Firestore project.

Dark mode and the Lao locale were also verified on the same pass: dark
mode renders correctly across the list, detail, form, and contribute
sheet; the Lao locale (before its own translations existed) gracefully
fell back to English for this feature's strings with no crash or broken
layout, confirming the fallback path itself is safe.

**Still not verified on-device**: auto-contribution reminder
notifications actually firing (the schedule/estimate logic that drives
them is confirmed correct; the notification firing itself needs either a
long-running wait or a way to force the due-check).

**Deliverables**: the feature described above, plus the `firestore.rules`
and English-localization updates it needed. Lao translation of the
~44 new keys was completed in a follow-up pass (draft — see `TODO.md`
for the native-speaker review this still needs, same as the rest of
`app_lo.arb`).

**Dependencies**: none blocking.

**Estimated difficulty**: Medium-High — the money-model decision (tie
progress to a real account's balance rather than a summed ledger) was
the main design risk; once made, most of the implementation closely
follows existing Budget/Account/Transaction patterns.

---

## Beyond v1 (see also `CLAUDE.md`'s Future Vision)

Everything originally staged here has since shipped, ahead of Stage 7
rather than after it — beta-testing directly on real hardware
surfaced a genuine Google Sign-In bug in the process (see `TODO.md`):
- ~~CSV/PDF export~~ — CSV shipped; PDF remains open (see `TODO.md`).
- ~~Multi-currency reporting rollups~~ — shipped
  (`lib/features/exchange_rates/`).
- ~~Biometric/PIN app lock~~ — shipped (`local_auth`).
- ~~Sync-status indicator~~ — shipped.

Decisions since revisited (queued, not yet implemented):
- **Push notifications** — v1 shipped **local** (on-device) alerts only,
  a deliberate infrastructure/billing decision at the time. That
  decision has since been revisited: Firebase Cloud Messaging (real
  push — budget/bill/savings reminders plus promotional notifications)
  is now planned as a follow-up milestone. Not started.
- ~~**Analytics**~~ — shipped. `firebase_analytics` added,
  `analyticsProvider` in `firebase_providers.dart`, collection disabled
  in debug builds the same way Crashlytics already is
  (`!kDebugMode`, in `main.dart`). Automatic screen-view tracking via
  `FirebaseAnalyticsObserver` on the app's single `GoRouter`. A
  deliberately curated set of feature-adoption events, not an
  exhaustive one — creation events only (`account_created`,
  `transaction_created`, `category_created`, `budget_set`,
  `savings_goal_created`, `csv_exported`), plus `login`/`sign_up` on the
  auth success paths — logged with a type/category parameter where one
  exists, never an amount, name, or other financial detail. Edits,
  deletes, archives, and other finer-grained interactions are not
  instrumented; add them incrementally if a specific question needs
  that data, rather than instrumenting every action up front.
  `logAnalyticsEvent` (`core/utils/analytics_logger.dart`) is the only
  way any of this is called — it swallows failures so a broken
  analytics call can never break the action it's attached to, which is
  also what keeps it safe to call from controllers that existing tests
  exercise without a Firebase app (a real bug caught only by running
  the suite: the first version read `ref.read(analyticsProvider)` as
  a plain argument, outside the helper's own try/catch, so it still
  threw). `PRIVACY_POLICY.md` updated with a dedicated Analytics
  disclosure. Still owed: the Play Store Data Safety form update
  before release (a console action, not a code change).

Not sequenced — still genuinely future:
- Real, server-validated monetization, if pursued (see `TODO.md` for
  why the original client-writable approach was removed)
