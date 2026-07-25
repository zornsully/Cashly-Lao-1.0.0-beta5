# Cashly

Personal finance app for the Lao market. Flutter + Firebase (Auth +
Firestore). This file is the project's permanent handbook — product
vision, architecture, coding standards, and the design system all live
here, and every new feature is expected to follow it. If code and this
file disagree, treat that as a bug: either the code needs fixing or this
file needs updating to match a deliberate decision — never silently drift.

## Product Vision

Cashly is a real, shipping product at Apple Wallet / Revolut / Monzo /
Copilot Money quality — not a learning project, not an MVP. Every screen
should feel premium, fast, and trustworthy. Never ship something that
merely "works" if the design bar hasn't been met too.

The app exists because Lao consumers don't have a finance tracker built
for them: multi-currency support that treats the **Lao Kip (₭ / LAK) as
a first-class, primary currency** rather than an afterthought bolted onto
a USD-first app, and a bilingual Lao/English experience rather than
English-only. Every design and product decision should be checked against
that: does this feel like it was built *for* a Lao user, or ported to
them?

## Project Goals

- **v1 (launch-ready)**: accounts, transactions, categories, budgets,
  account-to-account transfers, and monthly reports, fully bilingual
  (English/Lao), themed to the design system below, on a secure and
  correctly-modeled Firebase backend.
- **Trust is the product.** This app holds a user's financial picture.
  Every Firestore write is validated server-side (see `firestore.rules`),
  every balance-affecting operation is atomic, and nothing about the
  design or copy should ever feel like a demo.
- **Not goals (for now)**: monetization/IAP (deliberately removed for v1,
  see [Known gaps](#known-gaps-vs-the-product-vision)), investment
  tracking, bill splitting, or multi-user/shared accounts — Cashly is a
  personal, single-user finance tracker first.

## Stack

- Flutter (Dart ^3.12.2), Material 3
- `flutter_riverpod` for DI/state
- `go_router` for navigation (single `GoRouter`, declarative `redirect`
  for auth guarding — see `lib/core/routing/app_router.dart`)
- `fpdart`'s `Either<Failure, T>` for error handling
- `cloud_firestore` + `firebase_auth` (+ `firebase_crashlytics` +
  `firebase_analytics`), no backend of our own
- `flutter_localizations` + ARB-based i18n (`lib/l10n/*.arb`, `flutter
  gen-l10n`) for English/Lao bilingual support
- Manrope/Plus Jakarta Sans/Noto Sans Lao bundled as local font assets
  (not fetched via `google_fonts` — see [Typography](#typography) for
  why), Noto Sans Lao as a font-fallback (not a per-locale switch)
- No codegen (no `build_runner`, no `freezed`) — models/entities are
  hand-written

## Architecture Principles

Clean Architecture, feature-first, under `lib/features/<feature>/`:

```
data/
  datasources/   Firestore access, throws AuthException / ServerException
  models/        fromFirestore / toFirestore mapping
  repositories/  implements domain repo, uses RepositoryGuard, returns Either
domain/
  entities/      plain Dart, Equatable
  repositories/  abstract interfaces
  usecases/      one class per operation, `call()` entrypoint
presentation/
  providers/     Riverpod providers/notifiers wiring the above together
  screens/
  widgets/
```

Shared code lives in `lib/core/` (`error/`, `providers/`, `routing/`,
`theme/`, `widgets/`, `utils/`, `constants/`). Reuse `core/widgets`
instead of building one-offs — see [Component Guidelines](#component-guidelines).

Principles that hold across every feature:
- **Dependencies point inward.** `presentation` depends on `domain`;
  `data` implements `domain`'s interfaces. `domain` never imports
  `data` or `presentation`, and never imports Flutter/Firebase types.
- **One usecase, one operation.** No "god" usecases or repositories that
  accumulate unrelated methods — if two features need the same
  computation, extract a shared usecase (see
  `ComputeCategorySpendingUseCase`, used by both Dashboard and Reports)
  rather than duplicating it or reaching across feature boundaries.
- **Errors are values, not exceptions**, above the datasource boundary.
  Datasources throw; everything above that returns `Either<Failure, T>`
  via `RepositoryGuard`.
- **Ownership is enforced by data shape, not just by rules.** Every
  user's data lives under `users/{uid}/...` subcollections, so a
  Firestore query literally cannot cross into another user's data —
  `firestore.rules` is the backstop, not the only line of defense.

## Coding Standards

- Repository implementations mix in `RepositoryGuard` (`lib/core/error/
  repository_guard.dart`) — never hand-roll try/catch → `Either`.
- Providers follow `<feature>RemoteDataSourceProvider` →
  `<feature>RepositoryProvider` → usecase/controller providers, in that
  file order, in `presentation/providers/<feature>_providers.dart`.
- Routes are named constants in `lib/core/routing/app_routes.dart`
  (`fooEditPath(id)` helpers for parameterized routes), registered in
  `app_router.dart`, navigated to via `context.go`/`context.push` —
  never hardcoded path strings.
- Money is always keyed by currency (`Map<String, double>`), never
  summed across currencies — see `DashboardSummary`,
  `ComputeCategorySpendingUseCase`. Currency is attributed via the
  transaction's *account* (transactions don't carry their own code).
  This is also why a transfer's source and destination account must be
  the same currency (enforced in `transaction_form_screen.dart`) —
  there's no exchange-rate conversion, so moving "30" out of one
  account has to land as 30 of that same currency, not 30 of whatever
  the other account happens to use.
- Any Firestore write path needs a matching `firestore.rules` update:
  type-check every field, and pin any field that must be immutable
  after creation (see the `isDefault` / `categoryId`+`month` pinning —
  those exist to close real privilege-escalation paths, not out of
  caution).
- Transaction-affecting Firestore writes (anything that touches an
  account balance) must go through `firestore.runTransaction`, reading
  before writing. See `transaction_remote_datasource.dart` for the
  reference pattern, including the cross-account-and-type-flip case.
- User-facing strings go through `AppLocalizations` (`lib/l10n/*.arb`),
  not hardcoded English — add the key to both `app_en.arb` and
  `app_lo.arb` together. (Existing hardcoded strings in
  not-yet-localized screens are a tracked gap, not a pattern to copy —
  see [Known gaps](#known-gaps-vs-the-product-vision).)
- Icons come from `AppSymbols` (`lib/core/constants/app_symbols.dart`),
  never `Icons.*` — the latter is the legacy Material icon set and is
  visually inconsistent with Material Symbols Rounded.

## Cashly Brand & Design System

This is Cashly's permanent design reference — the single source of truth
for every visual and UX decision. It supersedes ad hoc styling choices
anywhere in the codebase; if existing code conflicts with this section,
the code is wrong, not the section.

**The bar, stated as a question**: for every design decision — a screen,
a component, a spacing value, a transition — ask *"would this look
appropriate in a top-ranked App Store finance app?"* Benchmark against
Apple Wallet, Revolut, Monzo, Copilot Money, and Linear. If the answer is
no, it's not done yet, regardless of whether the feature "works."

### Color palette

Material 3, light and dark, via `ColorScheme.fromSeed` with pinned brand
roles (`lib/core/theme/app_theme.dart`):

| Role | Hex |
|---|---|
| Primary — Blue | `#2563EB` |
| Secondary — Green | `#10B981` |
| Tertiary — Accent Gold | `#F59E0B` |
| Dark Navy (dark-mode base surface) | `#0F172A` |
| Neutral Gray | `#F1F5F9` |
| Error | `#DC2626` |

Dark mode's base surface is Dark Navy, never pure black (`#000000`) —
pure black kills the sense of depth Material 3 elevation relies on.
Every other color (surfaces, containers, on-colors) is derived from this
palette via `ColorScheme`, not hand-picked per-screen. Screens read
colors via `Theme.of(context).colorScheme.*` — never a raw hex literal
or `Colors.*` constant for anything that should adapt to the theme.

### Typography

- **Primary typeface**: Manrope, bundled as a local variable-font asset
  (`assets/fonts/Manrope/`) — not fetched via `google_fonts` at runtime.
  That package was the original approach, but gating the very first
  frame's theme construction on a live network fetch is a real crash
  risk, not just a slower one: a failed or slow fetch left
  `TextTheme.apply` building on a style with a null `fontSize`, crashing
  the app on launch. Switched to a bundled asset the same way Noto Sans
  Lao already was — `google_fonts` is no longer a dependency at all.
- **Fallback chain**: Plus Jakarta Sans, then Noto Sans Lao (so Lao
  glyphs render correctly regardless of which font is "primary" for a
  given run of text — this is a font *fallback*, not a per-locale
  theme switch). All three are bundled local assets, declared in
  `pubspec.yaml`'s `fonts:` section.
- Every screen pulls from `Theme.of(context).textTheme.*` (display/
  headline/title/body/label, each in large/medium/small) — never a
  one-off `TextStyle(fontSize: ..., fontWeight: ...)` constructed in
  screen code.
- Buttons get their own consistent style via `PrimaryButton`, distinct
  from body text.

### Theme Guidelines

- The app must look correct and intentional in **both** light and dark
  mode at all times — dark mode is not a lower-priority variant.
  `surfaceTintColor: Colors.transparent` is set app-wide so elevation
  reads through the explicit shadow tokens below, not Material 3's
  tonal-tint elevation (which looks muddy against the brand palette).
- Theme mode (light/dark/system) and language (English/Lao) are both
  user preferences persisted via Settings (`lib/features/settings/`) —
  see that feature for the pattern to follow if another persisted
  preference is ever needed.
- Never introduce a second theme file, a second color source, or a
  screen-local `ThemeData` override. One `AppTheme`, one source of truth.

### Design tokens

No hardcoded hex colors, spacing numbers, radii, or elevations in screen
or widget code — everything routes through a named constant:
- **Spacing** — `AppSpacing.xs/sm/md/lg/xl/xxl` = 4/8/16/24/32/48
  (`lib/core/constants/app_spacing.dart`).
- **Radius** — `AppRadius.sm/md/lg/xl/full` = 8/14/20/28/999
  (`lib/core/constants/app_radius.dart`).
- **Elevation/shadow** — `AppElevation` subtle/soft/lifted `BoxShadow`
  presets, plus `cardElevation`/`sheetElevation`/`dialogElevation`
  (`lib/core/constants/app_elevation.dart`) — not each widget picking
  its own `BoxShadow`.
- **Icons** — `AppSymbols.*` (`lib/core/constants/app_symbols.dart`),
  Material Symbols Rounded exclusively. (Defined as direct `IconData`
  constants rather than importing `material_symbols_icons`' generated
  `symbols.dart` — that file is large enough that it broke `flutter
  build apk` specifically on Windows. Add new icons the same way,
  don't reintroduce the bulk import.)

### Component Guidelines

Built once in `core/widgets`, reused everywhere — a screen should almost
never define its own button, card, dialog, or loading/empty/error
styling inline. **Currently built** (audit this list before assuming
something needs to be created from scratch):
- `PrimaryButton`, `SecondaryButton`, `DestructiveButton`,
  `AppTextField`, `AppPasswordField`
- `AppCard`, `AppBadge`, `AppChip`
- `AppDialog` (static `.confirm()` helper for Cancel/confirm dialogs —
  use a plain themed `AlertDialog` for one-off custom content, e.g. a
  form field, since `AppTheme`'s `dialogTheme` already gives it
  consistent chrome), `AppBottomSheet`
- `IconPickerField`, `ColorPickerField`
- `AppLoadingIndicator` (full-body spinner), `AppSkeletonList` /
  `AppSkeletonListTile` / `SkeletonBox` (list-shaped skeleton loading —
  prefer this over the bare spinner for any screen whose data resolves
  into a list), `EmptyState`, `ErrorView`
- `ResponsiveCenter`, `MonthSelectorHeader`
- `ChartLegendDot` + `AppChartStyle` — shared chart-legend dot/label/
  trailing-value row and its sizing constants, used by Reports' pie and
  trend charts (Dashboard's spending bar doesn't use a legend, so it
  doesn't need this)
- `CashlyLogoMark`, `GoogleLogoMark`, `GoogleSignInButton`

Every async screen needs distinct, styled loading / empty / error
states using the components above — no bare `CircularProgressIndicator()`
and no bare `Text('$error')`.

### Branding

- **Logo**: the letter **C**, a wallet shape, and a Lao Kip (**₭**) coin
  motif, combined into one minimal, flat-design mark. **Never a dollar
  sign** — this is a Lao-market app.
- Flat design only — no gradients-as-depth, no skeuomorphism.
- The mark is a **real image asset**, not a hand-coded `CustomPainter`.
  The source of truth is `assets/logo/source/Logo.ai` (a real
  Illustrator/PDF file, plus the designer's own clean `PNG`/`SVG`
  exports alongside it); the in-app asset
  (`assets/logo/cashly_mark.png`, rendered via `CashlyLogoMark`,
  `lib/core/widgets/cashly_logo_mark.dart`) and every generated app-icon
  file were produced directly from it — export a fresh flat PNG from
  that source and regenerate, don't hand-redraw, if the mark ever needs
  to change.
- Applied consistently across: the app icon (Android Adaptive Icon —
  `mipmap-anydpi-v26/ic_launcher.xml` + per-density
  `ic_launcher_foreground.png` layers over a flat
  `@color/ic_launcher_background`, and iOS `AppIcon.appiconset`, both
  generated from the same source), the splash screen, and auth screens
  (login/register/forgot-password). Not yet applied to: empty-state
  illustrations, About/Settings screen branding.

### Motion

Meaningful transitions and micro-interactions are a first-class
requirement, not polish layered on at the end. Every navigation, state
change, and user action should have an intentional, premium-feeling
transition rather than an instant cut.

- **Tokens**: `AppMotion` (`lib/core/constants/app_motion.dart`) —
  `fast`/`normal`/`slow` durations and `enter`/`exit` curves. Use these
  instead of a screen picking its own duration/curve, same rationale as
  `AppSpacing`/`AppRadius`/`AppElevation`.
- **Route transitions**: app-wide via `AppTheme`'s `pageTransitionsTheme`
  (`FadeForwardsPageTransitionsBuilder` on Android/desktop, native
  `CupertinoPageTransitionsBuilder` on iOS/macOS) — every `go_router`
  push/pop gets this for free; no per-screen work needed.
- **`AppDialog`/`AppBottomSheet`** pass `AppMotion` timing via
  `animationStyle`/`sheetAnimationStyle` — already wired, nothing to do
  per call site.
- **Bottom-nav tab switches** cross-fade (`AnimatedSwitcher` around
  `navigationShell` in `home_shell_screen.dart`) instead of the
  `StatefulShellRoute` default instant swap.
- **Value changes**: `StatCard` (Dashboard's balance/income/expense
  figures) counts smoothly between old and new amounts via
  `TweenAnimationBuilder` rather than snapping. Apply the same pattern
  anywhere else a prominent figure updates in place.

### Non-negotiables

- No screen ships "unfinished": every async screen has loading, empty,
  and error states styled to this system.
- Dark mode and light mode are both fully supported and both verified
  (on an actual device/emulator, not just by reading the code) before
  any screen is considered done.
- No hardcoded colors, spacing, radii, or font styles outside the
  design-token files.

## UI/UX Design Guidelines

- **Accessibility isn't optional.** Never encode meaning in color alone
  (the existing charts already follow this — donut/spending-bar charts
  pair color with a label or pattern, not color by itself). Interactive
  targets should meet a comfortable tap-target size; body text should
  meet WCAG AA contrast against its background in both themes.
- **Responsive by default.** Use `ResponsiveCenter` for content that
  shouldn't stretch edge-to-edge on tablets/wide screens rather than a
  screen-specific `MediaQuery` check.
- **Bilingual by default.** Any new copy needs both an `app_en.arb` and
  `app_lo.arb` entry (see [Coding Standards](#coding-standards)) and
  layout that doesn't break when Lao text runs longer/shorter than the
  English string it replaces.
- **Money is never ambiguous.** Always show the currency alongside an
  amount; never assume the user's only account is in LAK just because
  it's the primary currency.

## Development Workflow

- Every change must pass `flutter analyze` (zero issues) and
  `flutter test` (all green) before being considered done.
- Prefer refactoring existing code over stacking a workaround next to
  it. No quick fixes, no duplicate logic.
- Don't introduce breaking changes to existing features while adding
  new ones.
- `PROJECT_PROGRESS.md`, `TODO.md`, and `RELEASE_NOTES.md` are living
  docs — deferred work goes in `TODO.md` *with the reason* it was
  deferred, not silently dropped. `ROADMAP.md` holds the current
  staged development plan.
- Verify UI/UX changes on a real device or emulator before calling them
  done — `flutter analyze`/`flutter test` catch correctness regressions,
  not visual or interaction regressions. Say so explicitly if a change
  hasn't been visually verified.
- Nothing gets committed or opened as a PR without the user's explicit
  go-ahead for that specific batch of work.

## Quality Assurance Checklist

Before calling any screen or feature "done," confirm:

- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test` — all green, and new logic has usecase/repository/
      datasource-level test coverage (see existing tests for the
      pattern: `mocktail` + `fake_cloud_firestore`)
- [ ] Every color/spacing/radius/elevation value traces to a design
      token — no raw hex, no magic-number `EdgeInsets`/`BorderRadius`
- [ ] Icons are `AppSymbols.*`, not `Icons.*`
- [ ] Loading, empty, and error states are all present and styled
      (`AppLoadingIndicator`/`EmptyState`/`ErrorView`), not bare
- [ ] Verified on-device/emulator in **both** light and dark mode
- [ ] All user-facing strings are in `app_en.arb` **and** `app_lo.arb`,
      and the screen renders correctly with the Lao locale forced
- [ ] Any new/changed Firestore write path has a matching, tested
      `firestore.rules` update (type-checked fields, immutable fields
      pinned)
- [ ] Any balance-affecting write uses `firestore.runTransaction`
- [ ] No breaking change to an existing feature's behavior

## Product Roadmap

The full staged roadmap — objectives, features, deliverables,
dependencies, and difficulty per stage — lives in `ROADMAP.md`. Update
that file, not this section, as stages complete or scope changes. This
section is a pointer, not a duplicate, so it doesn't go stale.

## Future Vision

Everything originally listed here as forward-looking — multi-currency
reporting, notifications, and export — has since shipped:
- **Multi-currency reporting**: `lib/features/exchange_rates/` fetches
  a daily rate snapshot (ExchangeRate-API's free, no-key endpoint) and
  Reports' `ConvertReportTotalsUseCase` rolls up a month's per-currency
  totals into one figure in the user's default currency — raw amounts
  stay currency-exact everywhere else, exactly as originally scoped.
- **Notifications**: local (on-device) budget-exceeded / negative-
  balance alerts, deliberately **not** FCM (a real infrastructure/
  billing decision, not a shortcut) — see
  `lib/core/providers/budget_alert_providers.dart`.
- **Export**: CSV, built directly on `MonthlyReport.toExportRows()` as
  planned. PDF is the one format still open — see `TODO.md`.

The one item from this section still genuinely in the future:
- **Real monetization**, if pursued, must be server-validated from day
  one (a Cloud Function checking a purchase receipt before granting any
  entitlement) — never a client-writable Firestore flag. See
  [Known gaps](#known-gaps-vs-the-product-vision) for why the original
  approach was removed.

## Known gaps vs. the product vision

Tracked in more detail in `TODO.md` and `ROADMAP.md`, but worth knowing
up front:
- Reports are monthly-only (no daily/weekly/quarterly/yearly); charts
  are hand-rolled, no charting library.
- The component library (see [Component Guidelines](#component-guidelines))
  and the Motion system (see [Motion](#motion)) are both built.
- Search/filter/sort on transactions, a sync-status indicator, CSV
  export, biometric/PIN app lock, and local budget/balance
  notifications have all shipped since v1 (see `TODO.md` for the
  Google Sign-In bug that shipping the last of these on real hardware
  turned up, and how it was fixed).
- Every screen is localized into Lao (Auth, Dashboard, Accounts,
  Transactions, Categories, Budget, Reports, Settings, Profile). The
  existing `app_lo.arb` translations are still a draft, not written by a
  certified translator — have a native Lao speaker review them before
  shipping.
- Premium/monetization was deliberately removed ahead of v1 (a
  client-writable demo flag was a real App Store review risk with no
  real IAP behind it) — Reports ships free for everyone in v1. See
  [Future Vision](#future-vision) for how to reintroduce it safely.
- Test coverage has grown to 241 tests across 10 widget/screen test
  files (every feature's list screen has at least one presentation-
  layer test) plus full domain/data-layer coverage — see `TODO.md` for
  what's still open there.
- The iOS side of Google Sign-In and a real iOS release signing/App
  Store Connect setup are both still outstanding — this project has
  never been tested on an iOS device or simulator, only Android.
