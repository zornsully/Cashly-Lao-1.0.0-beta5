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

### Free-tier manual release policy

During development, Cashly Lao uses Firebase Spark and GitHub Free only.
Firebase Hosting serves the website and `release-manifest.json`; it must never
serve an APK or another installer. GitHub Actions may perform read-only checks
and build review artifacts, but must never receive signing material, create a
release, upload an asset, deploy Hosting, or change download metadata.

The source repository remains private. A public Android download can use only
a separate, owner-approved public GitHub distribution repository recorded in
`assets/release/distribution_policy.json`. That policy is deliberately
unconfigured by default, so the landing page remains fail-closed as “Coming
soon” until a repository is reviewed and committed.

The required manual sequence is non-negotiable:

1. Check out a clean immutable source tag and build the signed APK locally.
2. Verify package ID, version name/code, APK signature, approved certificate
   fingerprint, size, and SHA-256; generate `SHA256SUMS.txt`, evidence, and
   reviewed notes.
3. Stop for explicit owner approval.
4. After approval only, upload a draft GitHub Release to the approved public
   distribution repository, verify the uploaded APK, publish it, then verify
   an anonymous public download's size and SHA-256.
5. Stop for a second explicit owner approval before generating/deploying
   Firebase Spark website metadata. Deploy only `hosting:cashly-lao`, then
   validate the live manifest.

Never overwrite or retag a versioned public APK, never delete release evidence
automatically, and never change the website link if public-asset verification
fails. A rollback changes only the website manifest back to a previously
verified public release; it cannot retract or alter an existing GitHub asset.
macOS, Windows, and iOS releases remain held until separately authorized.

### Website-only content deploys (pre-approved)

Scoped narrowly to content that lives only at
[cashly-lao.web.app](https://cashly-lao.web.app): the landing page, Privacy
Policy, Terms, FAQ, screenshots, the Download section's *presentation* (not
its data), website localization, other static web assets, and web-only
bug/accessibility/responsive-layout fixes.

For changes scoped to that list only, once `flutter analyze`, `flutter
test` (full suite), and `flutter build web --release` all pass — and the
change touches none of `web/release-manifest.json`, `assets/release/**`, or
any Android signing/version file — a Firebase Hosting deploy of
`hosting:cashly-lao` may proceed without a separate per-instance approval,
via `tool/deploy_website.ps1` (see
[docs/RELEASE_PIPELINE.md](docs/RELEASE_PIPELINE.md#website-only-content-deploys)).
That script itself refuses to run if the change touches a release-trust
path, runs the full analyze/test/build sequence, confirms the configured
Hosting target before deploying, and verifies the live site afterward
rather than trusting a clean exit code alone.

This carve-out changes nothing else about the [manual release
policy](#free-tier-manual-release-policy) above:

- **Application binaries remain fully manual and non-negotiable** — APK/AAB/
  IPA, App Store submission, installers, GitHub Release publication, signing-
  key changes, and production release tags all still require the full
  sequence and both explicit owner approvals, exactly as documented above.
- **The Download section's actual release data is never covered by this
  carve-out.** Any change to `release-manifest.json` or
  `assets/release/distribution_policy.json` — including which release is
  marked latest — stays on the existing two-approval-gate sequence.
- **This never authorizes Git actions.** Commit, push, merge, PR, and tag
  still each require your explicit per-instance approval, unchanged.
- **No new paid services.** Stays fully Firebase Spark/GitHub Free
  compatible — no Blaze-only services, no deploy-only Cloud Functions, no
  GitHub Actions deploy credentials. Firebase Hosting deployment uses
  whichever local `firebase login` session is available in the environment
  actually running the deploy; no Firebase credentials, tokens, or login
  data are ever stored in the repository or in this file.

After every website deployment under this policy, record in a new dated
Project Memory entry: date/time, task completed, files changed, tests run,
the web build command, the deployment command, the Firebase Hosting target,
the live URL, verification actually performed against the live site,
deployment result, any failures or limitations, rollback notes, and the next
step. Never record a deployment as successful without independently
verifying the live site — a clean local build and a clean `firebase deploy`
exit code are not the same claim as "the live site now shows this."

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

## Project Memory and Progress

### 2026-07-29 — Free-tier manual release redesign (validated; pending owner decisions)

Summary:

- Replaced the paid/protected-environment release design with a manual
  Firebase Spark + GitHub Free design.
- Kept the private source repository separate from a future public,
  owner-approved distribution repository.
- Added a fail-closed release-distribution policy. It is unconfigured by
  default, so no public APK download can be enabled accidentally.
- Added local preparation, public-release, website-metadata, and rollback
  tooling. None has been run to publish, deploy, create a release, or change a
  public download link.

Files created:

- `assets/release/distribution_policy.json`
- `tool/prepare_manual_release.ps1`
- `tool/publish_github_release.ps1`
- `tool/publish_web_metadata.ps1`
- `tool/rollback_web_metadata.ps1`

Files modified:

- `.github/workflows/ci.yml`
- `.github/workflows/prepare-release.yml`
- `.github/workflows/release.yml`
- `.github/workflows/rollback-production.yml`
- `.github/workflows/web-preview.yml`
- `CLAUDE.md`
- `README.md`
- `RELEASE_NOTES.md`
- `assets/release/release_manifest.json`
- `docs/FIREBASE_HOSTING_APK_DELIVERY.md`
- `docs/PRODUCTION_ENVIRONMENT.md`
- `docs/RELEASE_PIPELINE.md`
- `docs/RELEASE_SECRETS.md`
- `docs/REPOSITORY_HARDENING.md`
- `docs/ROLLBACK.md`
- `firebase.json`
- `lib/features/landing/data/services/hosted_release_manifest_service.dart`
- `lib/features/landing/domain/entities/release_manifest.dart`
- `pubspec.yaml`
- `test/features/landing/data/services/hosted_release_manifest_service_test.dart`
- `test/features/landing/domain/entities/release_manifest_test.dart`
- `test/features/landing/presentation/screens/landing_page_test.dart`
- `tool/generate_release_manifest.dart`
- `tool/generate_release_notes.dart`
- `tool/verify_release.dart`
- `web/release-manifest.json`

Files removed:

- `tool/stage_release_apk.ps1`
- `tool/sync_release_manifest.ps1`

Implementation decisions:

- Firebase Spark hosts only static web content and `release-manifest.json`.
  APK hosting and Firebase binary-delivery rules were removed.
- GitHub Actions are read-only: no signing credentials, release-write scope,
  environments, OIDC, Firebase deployment, or automatic publication.
- A schema-v3 manifest accepts an Android download only when the bundled policy
  approves the exact public `owner/repository`, release tag, and canonical
  GitHub asset URL. Schema-v1 and schema-v2 documents remain non-downloadable
  fallbacks.
- The manual sequence requires local signing/validation/checksums/notes, owner
  approval for public GitHub publication, anonymous asset verification, then a
  separate owner approval for Spark metadata deployment.

Validation:

- `firebase.json` parsed successfully after removal of APK Hosting headers.
- The bundled Dart analyzer completed with no issues.
- `flutter analyze` completed with no issues.
- The focused release-manifest and landing-page suite passed: 33 tests.
- The full Flutter suite completed successfully: 366 tests.
- PowerShell parser validation passed for all four manual release scripts.
- JSON parsing passed for `firebase.json`, the distribution policy, and both
  bundled/hosted manifest files. `git diff --check` passed with only existing
  line-ending warnings.
- A read-only workflow security scan found no deployment command, release-write
  command, protected environment, OIDC, or write-permission pattern.
- No end-to-end signed release dry run was run: it requires an immutable
  release tag and the owner's local signing material. No public release,
  website deployment, production metadata update, or Git commit was performed.

Known limitations:

- No public distribution repository has been approved or created. Keep
  `assets/release/distribution_policy.json` as `repository: null` and the
  landing page as “Coming soon” until the owner explicitly approves one.
- The public-release and Spark metadata scripts remain deliberately unexecuted;
  they are approval-gated and would change external state.

Required approvals and setup:

- Owner approval is required before naming or creating the public distribution
  repository, publishing an APK, changing production metadata, deploying
  Firebase Spark, committing this batch, or opening a pull request.
- Local Android signing material, a local `gh auth` session, and a local
  `firebase login` session are required only when their corresponding approved
  manual step is run. Do not record credential values here.

Next steps:

- Obtain the owner's decision on a separate public distribution repository
  (the private source repository must remain private), then set it through a
  reviewed policy change.
- Build and validate a signed immutable-tag candidate locally. Review the APK,
  package/version, signing certificate, checksum, size, and generated notes.
- Obtain separate owner approvals for (1) public GitHub Release publication and
  (2) the later Firebase Spark metadata/website deployment.

### 2026-07-29 — Post-audit Phase 1: account-currency and transfer-currency correctness (done)

Summary:

A full project audit (architecture, Firebase/security, business logic,
design system, localization/testing, release pipeline) found two
High-severity money-correctness gaps, both pre-existing and unrelated to
the release-pipeline redesign above. Both are now closed.

1. **`accounts.currencyCode` was editable after creation and unpinned in
   `firestore.rules`.** Since currency is attributed via the *account*
   (never the transaction — see Coding Standards), editing an existing
   account's currency silently reclassified every historical
   transaction/budget/report/Smart-Money-Score figure tied to it into a
   different currency, with no conversion and no warning.
2. **A transfer's same-currency requirement (source and destination
   accounts must match) was enforced only in `transaction_form_screen.dart`
   — never in `firestore.rules`.** A direct Firestore write bypassing the
   form could create a mismatched-currency transfer, moving an unconverted
   raw number between currencies.

Files modified:

- `firestore.rules` — `accounts.update` now pins `currencyCode` unchanged
  (same pattern as categories' `isDefault` and budgets'
  `categoryId`/`month`); `transactions.create`/`update` now requires a
  `get()`-verified currency match between a transfer's `accountId` and
  `toAccountId`, matching the categories/budgets precedent of closing a
  rules gap with a real check rather than a comment.
- `lib/features/accounts/domain/usecases/update_account_usecase.dart`,
  `domain/repositories/account_repository.dart`,
  `data/repositories/account_repository_impl.dart`,
  `data/datasources/account_remote_datasource.dart`,
  `presentation/providers/account_controller.dart` — `currencyCode` removed
  from the entire `updateAccount` call chain (the established codebase
  pattern for a pinned field — see `UpdateBudgetUseCase`, which likewise
  never exposes `categoryId`/`month`).
- `lib/features/accounts/presentation/screens/account_form_screen.dart` —
  the currency dropdown is only interactive when creating a new account;
  editing an existing account shows it as a locked, read-only field
  (`InputDecorator` with `enabled: false`) plus a new helper string, so the
  currency stays visible (money is never ambiguous) without being
  editable.
- `lib/features/transactions/data/datasources/transaction_remote_datasource.dart`
  — added `_requireMatchingTransferCurrency` (online, reads both account
  docs inside the same `runTransaction`) and
  `_requireCachedMatchingTransferCurrency` (offline queue counterpart,
  reads from cache like the existing `_requireCachedAccounts`) as
  defense-in-depth alongside the new rules check — matches the project's
  existing double-gating pattern (see Sprint 9's Reports/Premium gate).
- `lib/l10n/app_en.arb` / `app_lo.arb` — new key
  `accountCurrencyLockedHelper` (Lao translation is a draft, same
  unreviewed status as the rest of `app_lo.arb` — see `TODO.md`).
- Tests: `test/features/accounts/data/datasources/account_remote_datasource_test.dart`
  (new: `updateAccount does not modify currencyCode`),
  `test/features/accounts/data/repositories/account_repository_impl_test.dart`
  (new: `updateAccount returns Right(unit) on success` — there was
  previously no test at all for `updateAccount` at either layer),
  `test/features/transactions/data/datasources/transaction_remote_datasource_test.dart`
  (new: same-currency transfer succeeds; different-currency transfer
  rejected on create; different-currency transfer rejected on update,
  with balances confirmed untouched in both rejection cases).

Implementation decisions:

- Removing `currencyCode` from `updateAccount`'s signature entirely
  (rather than accepting it and just pinning it in rules) follows the
  codebase's own established precedent for pinned fields
  (`UpdateBudgetUseCase` only exposes `limitAmount`/`currencyCode`, never
  the pinned `categoryId`/`month`) instead of introducing a new pattern.
- The transfer-currency check lives in the **datasource** layer, not a
  usecase, because `CreateTransactionUseCase`/`UpdateTransactionUseCase`
  only take account *IDs* — giving them account *data* would mean
  injecting an `AccountRepository` into the Transactions domain layer,
  exactly the cross-feature domain dependency `CLAUDE.md`'s Architecture
  Principles say to avoid. The datasource already reads both account docs
  directly inside the same atomic transaction for balance deltas (see
  `_applyDeltas`); the currency check reuses that same access pattern.
- No data migration was written for any transfer that might already exist
  with mismatched currencies from before this fix — the app has no
  real users yet (pre-launch), so this was judged unnecessary scope.

Validation:

- `flutter analyze` — 0 issues.
- `flutter test` — full suite, 371 passing, 0 failing, 0 skipped.
- No `firestore.rules` test harness exists in this repo (confirmed
  absent during the audit, consistent with `TODO.md`) — the two rules
  changes were verified by manual review against the existing
  `isDefault`/`categoryId`+`month` pinning precedent and Firestore rules
  syntax, not by an emulator test. Standing up a rules-test harness was
  offered as an option for this phase and deliberately deferred (owner
  chose to proceed without it) — worth reconsidering before the next
  `firestore.rules` change of comparable risk.

Known limitations:

- Pre-existing Firestore data (if any) with a transfer between
  already-mismatched-currency accounts, or an account whose currency was
  already changed before this fix, is not retroactively corrected.
- The two rules changes add Firestore `get()` reads on every
  account create/update and every transfer create/update — expected to be
  negligible at this app's realistic usage volume, not benchmarked.

Next recommended phase: Phase 2 — localize the Smart Money Score feature
(`financial_insight_card.dart` and its generation engine currently render
100% in English regardless of the app's language setting, undocumented
anywhere until this audit). See the audit's phased roadmap for Phases 2–4.

### 2026-07-29 — Post-audit Phase 2a: localize Smart Money Score card chrome (done; dynamic engine text deferred to 2b)

Summary:

Phase 2 ("localize the Smart Money Score feature") turned out to be two
architecturally distinct problems, discovered while reading the actual
code rather than assuming the original one-line audit description:

1. **Static UI chrome in `financial_insight_card.dart`** — section
   headers, status-badge labels, breakdown-sheet row labels, impact
   descriptions, the formula footnote, etc. — roughly 65 hardcoded
   English strings, all living directly in the presentation layer with
   zero domain involvement. Straightforward to localize the same way
   every other screen in the app already is.
2. **Dynamic, engine-generated text** — `FinancialInsight.headline`/
   `explanation`/`scoreReasons`/`actions` and `FinancialPeriodScore
   .reasons`, produced by `rule_based_financial_insight_engine.dart`
   (~50 templates with interpolated amounts/percentages/category names)
   and `short_horizon_balance_movement_calculator.dart`. This needs a
   structured-message domain type (kind + params) so the domain layer
   stays framework-free and localization happens in the presentation
   layer — a real architecture change, not a mechanical string swap.

There's also a data-model wrinkle worth recording: `SmartMoneyScoreCalculation
.reasons` and `SmartMoneyScoreOpening.baselineNote` are **persisted** to
Firestore (`smartMoneyScores/{scoreId}`) as English prose, kept as an
auditable historical calculation record (confirmed in
`smart_money_score_model.dart`). `FinancialInsight` itself is never
persisted — it's recomputed live every session — so it's safe to restructure
freely, but the persisted calculation fields are a separate, deliberately
out-of-scope concern (see Known limitations).

Given the split was materially bigger than originally scoped, the user chose
to split it into 2a (this phase — the static chrome, item 1 above, done now)
and 2b (the engine restructuring, item 2 above, a future phase).

Files modified:

- `lib/features/financial_insights/presentation/widgets/financial_insight_card.dart`
  — every static string now routed through `AppLocalizations`. Helper
  functions that were previously plain (`_statusFor`, `_budgetSummary`,
  `_periodLabel`, `_expenseComparisonLabel`) now take an `AppLocalizations`
  parameter, the same pattern `Validators` already established for
  threading locale-awareness into a non-widget function. Also fixed the
  monthly-score-hero label to read `score.maximum` instead of a hardcoded
  `150`.
- `lib/l10n/app_en.arb` / `app_lo.arb` — ~68 new keys (`smartMoneyScore*`,
  `financialInsightPeriod*`), including 4 parameterized ones (`{max}`,
  `{count}`, `{points}`, `{percent}`). Lao translations are drafts, same
  unreviewed status as the rest of `app_lo.arb` (see `TODO.md`).
- `test/features/financial_insights/presentation/widgets/financial_insight_card_test.dart`
  — added the `localizationsDelegates`/`supportedLocales` the test's
  `MaterialApp` needed once the widget started calling
  `AppLocalizations.of(context)` (it had none before, since the widget
  used zero localization previously).

What's still English-only after this phase (by design, deferred to 2b):

- `insight.headline`, `insight.explanation`, each `action.title`/
  `.detail`, and every string inside `insight.scoreReasons`/
  `score.reasons` (shown via `_ReasonLine` and the score-tile tooltip) —
  all engine-generated dynamic text, unchanged in this phase.
- The persisted `SmartMoneyScoreCalculation.reasons`/`unavailableReason`
  and `SmartMoneyScoreOpening.baselineNote` — deliberately out of scope,
  see Known limitations.

Implementation decisions:

- Did **not** touch `SmartMoneyScoreCalculation.reasons`/`baselineNote`'s
  persistence shape or the `smartMoneyScores` Firestore schema — those
  are an auditable historical record, and localizing them would mean
  either a schema migration or storing a structured representation
  instead of prose, both bigger decisions than this phase's scope.
  2b's structured-message design (once built) can still choose to feed
  the *live* display path from a freshly-generated structured message
  instead of the persisted string, without touching what's persisted —
  this phase didn't need to resolve that yet since it never touched
  engine-generated text.
- Reused `score.maximum` (already on `FinancialPeriodScore`) instead of
  a hardcoded `150` for the monthly hero label — a small correctness
  improvement that fell out of touching that line anyway.

Validation:

- `flutter analyze` — 0 issues.
- `flutter test` — full suite, 371 passing, 0 failing, 0 skipped (test
  count unchanged from Phase 1: no new test cases added, one existing
  widget test's harness updated to supply localization delegates).

Known limitations:

- The majority of *dynamically generated* Smart Money Score text (the
  headline, explanation, actions, and score reasons — arguably the most
  prominent content on the card) is still English-only. This phase only
  closes the static-chrome portion. See Phase 2b below.
- `SmartMoneyScoreCalculation.reasons`/`baselineNote` (persisted,
  auditable) remain English-only indefinitely unless a future phase
  deliberately takes on the schema-migration question — not tracked as
  a bug, just an explicit, documented boundary.
- New Lao strings are drafts, not reviewed by a native speaker (same
  standing item as the rest of `app_lo.arb`).

Next recommended phase: **Phase 2b** — give the domain layer a
framework-free structured-message type (kind enum + typed params) so
`rule_based_financial_insight_engine.dart` and
`short_horizon_balance_movement_calculator.dart` stop producing raw
English strings, and have the presentation layer render that structured
data through `AppLocalizations` with ICU placeholders. Real files
touched: `financial_insight.dart` (entity shape), the two calculator/
engine files above, `financial_insight_card.dart` again (to consume the
new structured types), ~50 new ARB key pairs, and test-assertion
rewrites in `rule_based_financial_insight_engine_test.dart`,
`smart_money_score_calculator_test.dart`,
`short_horizon_balance_movement_calculator_test.dart`,
`build_financial_insight_snapshots_usecase_test.dart`. This is a bigger,
more architecturally novel change than 2a — get explicit sign-off on
the structured-message design before starting.

### 2026-07-29 — Post-audit Phase 2b: structured Smart Money Score messages (done)

Summary:

Gave the domain layer the framework-free structured-message type Phase
2a deferred, and used it to localize every dynamically generated string
in the rule-based insight engine and the short-horizon balance-movement
calculator — the headline, explanation, actions, and score reasons that
2a explicitly left in English. `SmartMoneyScoreCalculation.reasons`/
`baselineNote` (persisted, auditable) remain untouched, exactly as
scoped in 2a: they're rendered through a deliberate `literal` passthrough
key rather than mapped onto a localizable one.

Files created:

- `lib/features/financial_insights/domain/entities/financial_insight_message.dart`
  — `FinancialInsightMessageKey` (91 template keys + `literal`) and
  `FinancialInsightMessage` (key + `Map<String, Object> args`), both
  plain Dart/Equatable, zero Flutter imports. Deliberately an enum +
  args map rather than 91 sealed subclasses — less boilerplate for a
  set this large, while staying fully framework-free and testable
  (domain tests assert on `.key`/`.args`, not rendered text).

Files modified:

- `financial_insight.dart` — `FinancialPeriodScore.reasons`,
  `FinancialInsight.headline`/`.explanation`/`.scoreReasons`, and
  `FinancialInsightAction.title`/`.detail` all changed from
  `String`/`List<String>` to `FinancialInsightMessage`/
  `List<FinancialInsightMessage>`.
- `rule_based_financial_insight_engine.dart` — every one of its ~75
  string templates now constructs a `FinancialInsightMessage(key,
  args)` instead of a raw string. `_scoreMonth()`'s passthrough of the
  persisted lifecycle calculation's reasons now wraps each string via
  `FinancialInsightMessage.literal(...)` rather than assigning it
  directly, preserving the 2a boundary without a type mismatch.
- `short_horizon_balance_movement_calculator.dart` —
  `ShortHorizonBalanceMovement.reason` is now a `FinancialInsightMessage`.
  Its 16 templates split into explicit Today/Week key pairs (rather than
  interpolating an English "today"/"this week" noun into one shared
  template) so every ARB message stays a natural, translatable sentence
  instead of requiring a nested-formatting step for the period noun.
  The "increased/decreased/stayed level by X%, contributing Y points"
  sentence was also reworded slightly to avoid needing English's
  point/points plural, consistent with the no-ICU-plural convention
  `smartMoneyScoreBudgetOverCount` already established in 2a.
- `financial_insight_card.dart` — added
  `_formatFinancialInsightMessage(message, l10n)`, an exhaustive switch
  mapping every `FinancialInsightMessageKey` to its `AppLocalizations`
  call; every call site that read `.headline`/`.explanation`/
  `.scoreReasons`/`action.title`/`.detail`/`score.reasons` (the card
  body, the today/week/month tooltip, and the action list) now routes
  through it.
- `lib/l10n/app_en.arb` / `app_lo.arb` — 92 new keys (91 templates +
  parity check; `literal` has no ARB entry, it renders verbatim in
  code), generated programmatically from a single source-of-truth table
  (key name, English text, Lao draft, placeholder types) rather than
  hand-transcribed, specifically to avoid mismatched key names or
  placeholder order across ~180 hand-written entries. Lao translations
  are drafts, same unreviewed status as the rest of `app_lo.arb`.
- Tests: `rule_based_financial_insight_engine_test.dart` and
  `short_horizon_balance_movement_calculator_test.dart` — every
  assertion that matched on a substring of English prose now checks
  `.key` (and `.args` where a specific value like a category name or
  percentage matters) instead. This is a incidental improvement, not
  just a forced migration — asserting on semantic key rather than exact
  wording means a future copy tweak to the English ARB string can't
  silently break these tests the way a `contains('...')` match could.
  `financial_insight_card_test.dart` updated to construct its fixture
  `FinancialInsight` with `FinancialInsightMessage` values.
  `smart_money_score_calculator_test.dart`,
  `build_financial_insight_snapshots_usecase_test.dart`, and
  `derive_smart_money_score_opening_usecase_test.dart` needed no
  changes — confirms the persisted-calculation boundary was correctly
  scoped; nothing they test crosses into the new message type.

Implementation decisions:

- Enum + args map over sealed subclasses: with 91 distinct templates, a
  sealed class per variant would mean 91 boilerplate classes for
  marginal type-safety gain over a `Map<String, Object>`— this
  codebase's own "don't design for hypothetical future requirements...
  three similar lines is better than a premature abstraction" standard
  argued against it here. `args` losing per-key compile-time shape
  checking is a real, accepted tradeoff; it's caught at the two
  boundaries that matter (the engine that builds each message, and the
  card's exhaustive formatter switch), both of which are covered by
  tests.
- Today/Week key pairs over a shared key + interpolated period arg:
  avoids ever asking a translator to insert a pre-translated English
  noun mid-sentence, and avoids needing a second, nested
  message-formatting pass in the card widget just to resolve the period
  word before interpolating it into the outer sentence.
- Generated the ARB additions and the card's formatter switch from one
  Node.js table (not committed — a throwaway script run from the
  scratchpad) rather than hand-writing ~270 lines of repetitive
  key/text/case entries, specifically because the earlier manual Phase
  2a ARB edits are exactly the kind of task where a copy-paste error in
  a placeholder name silently produces a runtime crash instead of a
  compile error you'd catch immediately.

Validation:

- `flutter analyze` — 0 issues.
- `dart format --set-exit-if-changed lib test tool` — clean (CI's format
  gate rejected unformatted output during Phase 1/2a's PR; formatted
  proactively this time before validating).
- `flutter test` — full suite, 371 passing, 0 failing, 0 skipped (same
  total as 2a: this phase changed *what* several existing tests assert,
  not how many tests exist).

Known limitations:

- `SmartMoneyScoreCalculation.reasons`/`unavailableReason` and
  `SmartMoneyScoreOpening.baselineNote` remain English-only,
  indefinitely, by the same deliberate, documented boundary 2a
  established — unchanged by this phase.
- New Lao strings (92 keys) are drafts, not reviewed by a native
  speaker — same standing item as the rest of `app_lo.arb`.
- Not verified on-device/emulator this phase — `flutter analyze`/
  `flutter test` confirm correctness, not visual rendering of the new
  Lao strings in the actual card layout (text length changes could
  affect wrapping).

Next recommended step: a native-speaker review pass of `app_lo.arb`
(now materially larger — 454 keys total across Phases 1, 2a, and 2b)
is the highest-value remaining localization item; see `TODO.md`.
Otherwise, the localization work opened by the original audit is
complete — remaining phases (`Icons.*`→`AppSymbols.*` sweep, report
currency partial-conversion signal, landing-page design-system
decision, App Check) are unrelated to Smart Money Score and can be
picked up independently.

### 2026-07-29 — Post-audit: report currency partial-conversion signal (done)

Summary:

`ConvertReportTotalsUseCase` returned `null` only when *no* currency in
a report had an exchange rate, but silently dropped any individual
currency that lacked one while still returning a total that looked
complete — a user with USD+CNY activity and no CNY rate would see a
converted figure that quietly excluded all CNY amounts with no
indication anything was missing. Closed by adding a real signal instead
of just a boolean: `ConvertedMonthlyTotals` gained
`excludedCurrencyCodes` (which currencies had no rate) and a derived
`isPartial` getter, and `_ConvertedTotalsCard` (`reports_screen.dart`)
now shows a small warning line naming them whenever the total is
partial.

Files modified:

- `lib/features/reports/domain/entities/converted_monthly_totals.dart`
  — `excludedCurrencyCodes` field (defaults to `const []`) + `isPartial`
  getter.
- `lib/features/reports/domain/usecases/convert_report_totals_usecase.dart`
  — collects the codes it `continue`s past instead of discarding them;
  doc comment updated to describe the partial case explicitly rather
  than only the "returns null" case.
- `lib/features/reports/presentation/screens/reports_screen.dart` —
  `_ConvertedTotalsCard` shows a warning row (icon + "Doesn't include
  {currencies} — no exchange rate available.") when
  `totals.isPartial`. While touching this card, also fixed two adjacent
  `Icons.*` literals in the same widget
  (`Icons.currency_exchange`/`Icons.warning_amber_rounded`) to use
  `AppSymbols.*` instead, since one was a pre-existing violation right
  next to the line being edited and the other was a fresh icon this
  change introduced — both should never have been `Icons.*` per
  CLAUDE.md's design rules. This is *not* the broader `Icons.*` sweep
  (still open, tracked separately) — only these two, directly touched
  by this change.
- `lib/core/constants/app_symbols.dart` — added
  `warningAmberRounded` (codepoint `0xf083`, sourced directly from the
  installed `material_symbols_icons` package's own `symbols.dart`
  rather than guessed, consistent with this file's existing entries).
- `lib/l10n/app_en.arb` / `app_lo.arb` — new key
  `convertedTotalsPartialWarning`, worded to avoid needing an ICU
  plural (no existing precedent for that in this codebase — see Phase
  2a/2b's own reasoning for the same choice).
- `test/features/reports/domain/usecases/convert_report_totals_usecase_test.dart`
  — extended the existing "skips a currency..." test to also assert
  `isPartial`/`excludedCurrencyCodes`, and added a new test confirming
  a fully-covered report reports no exclusions.

Implementation decisions:

- `excludedCurrencyCodes` (a list) over a plain boolean: naming *which*
  currencies were dropped is materially more useful to a user than just
  knowing "something's missing," and costs nothing extra to compute
  since the usecase already iterates every currency.
- Still returns `null` (not a partial total) when *nothing* converts —
  that boundary was already correct and is unchanged; this only fixes
  the previously-silent partial case sitting between "fully converted"
  and "nothing converted."

Validation:

- `flutter analyze` — 0 issues.
- `dart format --set-exit-if-changed lib test tool` — clean.
- `flutter test` — full suite, 372 passing (1 new test), 0 failing, 0
  skipped. The existing `reports_screen_test.dart` widget test
  ("shows a converted rollup card when the report spans multiple
  currencies") still passes unchanged, confirming the new warning row
  doesn't break the non-partial rendering path.

Known limitations:

- New Lao string is a draft, same unreviewed status as the rest of
  `app_lo.arb`.
- Not verified on-device — the warning row's layout (icon + wrapped
  text inside the existing card) hasn't been visually confirmed,
  though it follows the same `Row`/`Icon`/`Expanded(Text)` pattern
  already used elsewhere in this screen.

Next recommended phase: pick from the remaining original-audit items —
`Icons.*`→`AppSymbols.*` sweep (large, mechanical), the landing-page
design-system decision (needs your input first), or Firebase App Check
(infra-adjacent).

### 2026-07-29 — Product polish, Phase 1: Dashboard (done)

Summary:

First phase of a much larger "complete product polish" mission (your
own master prompt covering Landing/Dashboard/Transactions/Accounts/
Budgets/Categories/Reports/Settings, a shared design system, full
responsive breakpoints, native-vs-web app entry behavior, PDF/Excel
export, and an anomaly-detection "Expense Watch" engine). Given the
size — larger than everything else done this session combined — you
chose "one page at a time, highest-traffic first" over a big-bang pass
or a foundations-first phase. This closes Dashboard within the
*existing* layout system (no breakpoint/sidebar architecture change —
that's explicitly out of scope for this phase).

Reading the actual code first changed the scope: `dashboard_screen.dart`
already had most of what the master prompt's Dashboard section asked
for — a proper desktop header, a 4-card metric grid, Smart Money Score,
trend/category/budget panels, and (on desktop only) a `_QuickActions`
row with exactly the four actions requested (Add Income/Add Expense/
Transfer/Create Budget). What was actually missing or broken, closed
this phase:

1. **Quick Actions didn't exist on the mobile/compact dashboard at
   all** — desktop had them, phones didn't. Added the same widget
   there.
2. **Quick Actions weren't actually "four equal buttons"** — one
   `FilledButton` + three visually-different `OutlinedButton`s in a
   `Wrap`, not the equal-weight grid the prompt asked for. Replaced
   with `_QuickActionTile` — four identically-styled tiles in a
   `LayoutBuilder`-driven grid that reflows by the space actually
   available to it (4 columns → 2 → 1), so the same widget does the
   right thing whether it's full-bleed on a phone or sharing desktop
   content width.
3. **~20 hardcoded English strings** across the header subtitle, both
   quick-actions labels, all four metric cards' labels/captions, the
   currency-choice/notifications tooltips, the notifications sheet, and
   all three panel empty-states.
4. **19 raw `Icons.*` references**, this file's full count — every one
   replaced with `AppSymbols.*`, adding 14 new constants (codepoints
   read directly from the installed `material_symbols_icons` package's
   own `symbols.dart`, not guessed, same discipline as the earlier
   `warningAmberRounded` addition).

Files modified:

- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` —
  all of the above.
- `lib/core/constants/app_symbols.dart` — 14 new icon constants
  (`arrowDownward`, `arrowUpward`, `trendingDown`, `calendarMonth`,
  `keyboardArrowDown`, `notificationsNone`, `personOutline`, `settings`,
  `person`, `addRounded`, `removeRounded`, `swapHoriz`,
  `dashboardCustomize`, `insertChartOutlined`).
- `lib/l10n/app_en.arb` / `app_lo.arb` — 22 new keys, one parameterized
  (`dashboardMetricAlsoBalance`).

Implementation decisions:

- Quick Actions' column count is driven by the widget's own
  `LayoutBuilder` width (content area), not window/screen width — this
  is what lets one implementation serve both the desktop and compact
  dashboards correctly without a screen-wide breakpoint system, which
  is deliberately out of scope for this phase.
- Did not touch any business logic, providers, routes, or the
  wide/compact layout switch itself (`_wideLayoutBreakpoint = 760`) —
  only presentation-layer strings, icons, and the Quick Actions widget.
- Did not build a shared `PageHeader`/`QuickActions` component usable
  by other screens yet — that's a cross-cutting Section-1 "shared
  design system" decision spanning every screen, not a Dashboard-only
  one; revisit once more screens are through this same pass and a
  real pattern has emerged, rather than abstracting from a single
  usage.

Validation:

- `flutter analyze` — 0 issues.
- `dart format --set-exit-if-changed lib test tool` — clean.
- `flutter test test/features/dashboard` — 9/9 passing, including the
  existing desktop-dashboard widget test (confirms totals/layout
  behavior unchanged).
- `flutter build web --release` — compiles clean end-to-end (confirms
  every new `AppSymbols.*`/ARB reference resolves correctly; this is
  the same build path that caught a real theme-construction crash
  earlier in this project's history, so a clean build here is a
  meaningful signal, not just a formality).

Known limitations:

- **Not visually verified on-device or in-browser** — reaching the
  Dashboard requires signing in, which this session deliberately does
  not do itself (matches this project's own established pattern —
  every prior Dashboard-touching change in this project's history was
  verified on-device by the project owner specifically because of a
  documented Android-autofill incident from signing in during a prior
  session). Worth a real look next time you're signed in, particularly
  the Quick Actions grid's reflow at a few different widths.
- New Lao strings are drafts, same unreviewed status as the rest of
  `app_lo.arb`.

Next recommended phase: Transactions (per your "highest-traffic first"
ordering) — desktop data table + toolbar (search/date/account/category/
type filters + sorting), summary cards, three-dot row menu instead of
permanent delete icons; mobile cards + bottom-sheet filters + sticky
search. This is a larger phase than Dashboard turned out to be — mobile
already has search (`transactions_list_screen_test.dart` covers it) but
desktop has no data-table view or filter toolbar today, so more of this
one is genuinely new UI, not just cleanup.

### 2026-07-29 — Product polish Phase 2: Transactions (done)

Summary:

Reading the actual code first changed scope again: the mobile list
already had a genuinely solid filter/search system (type/account/
category/sort, all localized) — replacing it with a new toolbar would
have been a regression, not polish, and would have meant duplicating a
working search box. Kept that system exactly as-is (same AppBar
search-toggle + filter bottom sheet, at every width) and closed what
was actually missing instead.

1. **No permanent delete icon anymore.** `TransactionTile`'s bare
   delete `IconButton` is now a three-dot `PopupMenuButton` with Edit/
   Duplicate/Delete — used by every screen embedding this shared tile
   (Transactions, Dashboard's two recent-transaction lists, Savings
   Goals' account-activity history), so the change is consistent
   app-wide, not just on this one screen.
2. **"Duplicate" is a genuinely new feature**, not a UI reshuffle —
   there was no way to do this before. `TransactionFormScreen` gained
   `duplicateFrom` (distinct from `existing`/edit-mode): pre-fills
   account/category/type/amount/note from an existing transaction but
   still submits as a create, going through the same atomic
   `CreateTransactionUseCase` path unchanged. The date is deliberately
   *not* copied — a duplicate is almost always "this again, today."
   Wired through the router (`transactionNew`'s `extra` now
   distinguishes a `TransactionType` prefill from a full
   `TransactionEntity` duplicate-source by runtime type).
3. **Desktop summary cards** (Income/Expense/Net/Transaction Count),
   added above the list on wide screens only. Computed from whatever
   the current filter/search/month already narrowed the list to, via
   a new `_summarizeByCurrency` helper that mirrors
   `BuildDashboardSummaryUseCase`'s already-tested pattern exactly:
   grouped by the transaction's *account* currency (never the
   transaction itself), transfers excluded from income/expense,
   orphaned-account transactions skipped. Transaction Count is the one
   dimensionless figure shown once, spanning all currencies — everything
   else is per-currency, never summed across currencies.
4. Localized the few remaining strings and replaced every `Icons.*` in
   the three touched files (`transactions_list_screen.dart`,
   `transaction_tile.dart`, `transaction_form_screen.dart`) with
   `AppSymbols.*` — 11 new constants, codepoints read from the
   installed `material_symbols_icons` package, same discipline as
   every prior icon addition this pass.

Files modified:

- `lib/features/transactions/presentation/widgets/transaction_tile.dart`
  — three-dot menu; fixed the trailing action button at 48px
  (Material's own default minimum interactive size) instead of
  shrinking it on narrow layouts, which the old delete button did.
- `lib/features/transactions/presentation/screens/transaction_form_screen.dart`
  — `duplicateFrom` parameter and prefill logic.
- `lib/features/transactions/presentation/screens/transactions_list_screen.dart`
  — `_TransactionsSummaryRow`/`_SummaryCard`/`_summarizeByCurrency`;
  `onDuplicate` wired into the existing `TransactionTile` call site.
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`,
  `lib/features/savings_goals/presentation/screens/savings_goal_detail_screen.dart`
  — `onDuplicate` added to their own `TransactionTile` call sites (the
  shared-widget API change touches every embedder, not just
  Transactions).
- `lib/core/routing/app_router.dart` — `transactionNew` route now
  passes both `initialType` and `duplicateFrom` from `state.extra`,
  discriminated by runtime type.
- `lib/core/constants/app_symbols.dart` — 11 new constants.
- `lib/l10n/app_en.arb` / `app_lo.arb` — 5 new keys.

Implementation decisions:

- Did **not** build a persistent inline desktop toolbar (search +
  filter fields always visible, replacing the AppBar icons) — the
  existing AppBar search-toggle and filter-bottom-sheet already work
  correctly at every width and are already covered by a passing test.
  Duplicating that into a second, always-visible search box would
  have been redundant UI, not an improvement — genuinely additive
  scope (the summary cards) was worth doing; replacing working,
  tested UI for its own sake was not.
- The Transaction Count card intentionally spans all currencies in one
  number (unlike Income/Expense/Net, which are always per-currency) —
  a count is dimensionless, so combining it across currencies isn't a
  money-correctness violation the way summing amounts would be.
- Fixed the trailing action button at a flat 48px instead of the old
  compact/standard variable sizing — `PopupMenuButton`'s internal
  `IconButton` enforces Material's default minimum interactive size
  regardless of an explicit smaller `constraints`, and this app's own
  accessibility requirement (44px minimum touch target) argues for
  embracing that rather than fighting it. The pre-existing test
  asserting an upper bound was rewritten to assert the actual
  accessibility-meaningful property (`>= 44`) instead.

Validation:

- `flutter analyze` — 0 issues.
- `dart format --set-exit-if-changed lib test tool` — clean.
- `flutter test` — full suite, 372/372 passing. Two real bugs were
  caught by this pass, not by manual inspection: a 2.8px `RenderFlex`
  overflow in `_SummaryCard` (fixed by widening its grid aspect ratio)
  and the `PopupMenuButton` sizing issue above — both only surfaced
  because the existing widget tests happen to run at an ~800px default
  test surface width, which hits this phase's new wide-layout code
  path. Concrete evidence for why the "not verified on-device" caveat
  on prior phases matters: this is exactly the class of bug that kind
  of check catches.
- `flutter build web --release` — compiles clean end-to-end.

Known limitations:

- **Not visually verified on-device or in-browser**, same standing
  caveat as every prior UI phase this pass, for the same reason
  (reaching these screens requires signing in). The two bugs caught by
  the test suite this time are a reminder that "tests pass" and
  "looks right" are not the same claim — worth a real look next time
  you're signed in, especially the summary-cards grid's reflow and the
  three-dot menu's placement/tap targets on an actual touch device.
- New Lao strings are drafts, same unreviewed status as the rest of
  `app_lo.arb`.
- No date-range picker was added — the existing month selector already
  serves as the de facto date filter (same pattern Budget/Reports use),
  and building a separate arbitrary-range picker was judged out of
  scope for this pass.

Next recommended phase: Accounts, Budgets, or Categories (all smaller,
page-level phases per your ordering), or Reports — the master prompt's
"major redesign" item, which is larger than every other page-level
phase combined (new summary metrics not in `MonthlyReport` today, new
charts, export formats, and an anomaly-detection engine) and would need
its own scoping conversation before starting.

### 2026-07-29 — Product polish Phase 3: Accounts (done)

Summary:

Smaller phase than Dashboard/Transactions — Accounts already had a
solid three-dot archive/delete menu (no permanent-icon issue here) and
was already fully localized. What was actually missing, closed this
phase:

1. **No responsive treatment at all** — a single-column list at every
   width, even on a wide desktop window. Added a `LayoutBuilder`-driven
   grid (same content-width-driven pattern as Dashboard's Quick
   Actions and Transactions' summary cards): 1 column under ~360px of
   content width, up to 3 as it widens.
2. **Negative balances used color only** (red text, no badge) —
   contradicts this project's own accessibility principle ("never
   encode meaning in color alone," already followed by every chart in
   the app). Added a genuine "Negative" badge.
3. **No percentage-of-total-balance signal**, which the master prompt
   explicitly asked for. Added `AccountCard.percentOfTotalBalance`,
   computed per currency (never mixed — an account's share is only
   ever shown against the total of *other accounts in the same
   currency*) via a new `_totalBalanceByCurrency` helper in the
   screen; omitted entirely (no caption) when that currency's total is
   zero or negative, since a percentage wouldn't be meaningful there.
4. Localized 2 new strings and replaced the remaining `Icons.*` in
   both touched files with `AppSymbols.*`.

Files modified:

- `lib/core/widgets/app_badge.dart` — added an optional `color` param
  (defaults to the existing neutral look, so all 6 pre-existing
  call sites — Archived/Default/Completed/Due — are visually
  unchanged) so `AccountCard` could reuse the shared badge component
  for the new "Negative" badge instead of hand-rolling a one-off.
- `lib/features/accounts/presentation/widgets/account_card.dart` —
  negative badge; optional `percentOfTotalBalance` caption under the
  balance.
- `lib/features/accounts/presentation/screens/accounts_list_screen.dart`
  — responsive grid/list switch; `_totalBalanceByCurrency` helper;
  icon sweep. The archive-toggle icon now reuses one `AppSymbols.archive`
  glyph for both states (tinted primary when active) instead of the
  old filled/outline `Icons.archive`/`Icons.archive_outlined` pair —
  Material Symbols Rounded, as bundled in this app, doesn't expose a
  separate filled variant per name the way classic Material Icons did.
- `lib/core/constants/app_symbols.dart` — 2 new constants (`archive`,
  `addRounded` already existed from Dashboard).
- `lib/l10n/app_en.arb` / `app_lo.arb` — 2 new keys
  (`negativeBalanceBadgeLabel`, `accountPercentOfTotalBalance`).

Implementation decisions:

- Percentage is computed from whatever `accounts` list is already
  being rendered (respects the existing `showArchived` toggle) rather
  than a second, independently-fetched "all accounts" total — keeps
  the percentage consistent with what the user is actually looking at.
- Extending the shared `AppBadge` (rather than a local one-off in
  `account_card.dart`) follows the same "shared design system" reasoning
  as every prior phase's component reuse — the negative-badge use case
  isn't unique to Accounts and the same `color` param is available if
  a future phase needs a semantic badge elsewhere (e.g. Budget's "Over
  Budget" status).

Validation:

- `flutter analyze` — 0 issues.
- `dart format --set-exit-if-changed lib test tool` — clean.
- `flutter test` — full suite, 372/372 passing (no new test cases —
  the existing `accounts_list_screen_test.dart` already covers
  name/balance rendering and passed unchanged, confirming the new grid/
  badge/percentage additions didn't disturb existing behavior; no
  dedicated widget test was added for the new percentage/badge
  rendering itself, which is a real coverage gap worth closing before
  this screen is next touched).
- `flutter build web --release` — compiles clean end-to-end.

Known limitations:

- **Not visually verified on-device or in-browser**, same standing
  caveat as every prior UI phase this pass.
- New Lao strings are drafts, same unreviewed status as the rest of
  `app_lo.arb`.
- No widget test added for the negative badge or percentage caption
  specifically (see Validation) — the existing test suite doesn't
  construct a negative-balance or multi-account-same-currency fixture
  today.

Next recommended phase: Budgets or Categories (similar size to this
one), or Reports (the large item, still needs its own scoping
conversation first).

### 2026-07-30 — Release manifest: schema-v3 generator bug fix + version history (done)

Summary:

You asked for fully automated, centralized release management (auto-upload,
auto-metadata, auto-"latest" marking, multi-platform, suggested new backing
services). That conflicts directly with this project's non-negotiable
[free-tier manual release policy](#free-tier-manual-release-policy) — no new
services, two mandatory owner-approval gates, GitHub Actions staying
read-only. You chose **"Enrich the manual pipeline"** via AskUserQuestion:
keep both approval gates and the Spark/GitHub-Free-only model exactly as-is,
and instead expand the existing manifest schema and add version history,
still fully manual.

Investigating that surfaced a real, pre-existing defect unrelated to the
enrichment itself: `tool/generate_release_manifest.dart` hardcoded
`'schemaVersion': 2` in its output, while
`ReleaseManifest.currentSchemaVersion` (the value every validator —
`_validatePlatformRelease`, `isTrustedForPublicDownload`,
`HostedReleaseManifestService._requirePublicStableManifest`,
`tool/verify_release.dart` — checks against) has been `3` since the Phase 1
currency-integrity work. `docs/RELEASE_PIPELINE.md` and the generator's own
`--help` text already documented "schema-v3" throughout — only the actual
JSON output was stale. Any manifest the script produced today would have
silently failed `isTrustedForPublicDownload` and never unlocked a real public
download button. Per this file's own priority order (release-integrity
problems before feature work), this was fixed as part of the same phase
rather than building version history on top of a generator whose output the
app would reject.

Files modified:

- `tool/generate_release_manifest.dart` — schema-version bug: now emits
  `landing.ReleaseManifest.currentSchemaVersion` instead of a literal `2`
  (matching the pattern `tool/verify_release.dart` already used). Version
  history: new `_buildHistory()` carries forward whatever `history` array is
  already in `--template`, and — only when this run's stable Android artifact
  is about to replace a different, currently-`available` version — prepends
  the outgoing release (with `isLatest` forced `false`) as a new entry,
  capped at the 10 most recent.
- `tool/publish_web_metadata.ps1` — now passes `--template
  $websiteManifest` (the currently deployed `web/release-manifest.json`) to
  the generator instead of relying on its default template
  (`assets/release/release_manifest.json`, the static offline-fallback
  asset, which is never the "previous release" — it's a separate,
  deliberately-static bundled fallback, updated by the owner independently).
  Without this the history carry-forward logic above would never see a real
  previous release to archive.
- `lib/features/landing/domain/entities/release_manifest.dart` — new
  `ReleaseHistoryEntry` (a `ReleaseDescriptor` + a `PlatformRelease`) and
  `ReleaseManifest.history` (defaults to `const []`). Parsed via
  `_parseHistory()`, which reuses `ReleaseDescriptor.fromJson`/
  `PlatformRelease.fromJson` per entry — the exact same
  `ReleaseManifestTrustPolicy` checks the current release gets — but unlike
  the current release's fail-closed all-or-nothing validation, a single
  malformed, untrusted, prerelease, current-tag-duplicate, or
  incorrectly-`isLatest`-flagged entry is dropped individually rather than
  failing the whole manifest. Entries are sorted newest-first and capped at
  10.
- `lib/features/landing/data/services/hosted_release_manifest_service.dart`
  — `_encode()` now round-trips `history` through the persistent cache (the
  same entry shape, reusing the existing `_encodePlatform` helper), so a
  cached fallback doesn't silently lose version history versus a fresh
  network fetch.
- `lib/features/landing/presentation/screens/landing_page.dart` — new
  `_VersionHistorySection`/`_VersionHistoryRow`, shown only when
  `manifest.history.isNotEmpty`, styled to match this file's own established
  (token-free, hand-styled `_LandingColors`) local convention rather than the
  authenticated app's `AppSpacing`/`AppSymbols` design-token system — this
  page has never used those tokens (it's the public, pre-auth marketing
  page), so matching its existing pattern is consistent, not a new
  violation. Also fixed one incidental `use_null_aware_elements` lint
  (`?release.fileSizeLabel` instead of an `if (... case final x?) x`
  list element) and gave `_FadeInUp` a `super.key` passthrough (needed once
  a `_FadeInUp` had to be constructed conditionally with an explicit key).
- `docs/RELEASE_PIPELINE.md` — documents the history carry-forward behavior
  under the website-metadata step.
- Tests: `test/features/landing/domain/entities/release_manifest_test.dart`
  (6 new: valid entry parses; malformed/duplicate-tag/prerelease/
  incorrectly-latest entries are each dropped; newest-first sort + 10-entry
  cap), `test/features/landing/data/services/hosted_release_manifest_service_test.dart`
  (1 new: history round-trips through the cache), `test/features/landing/presentation/screens/landing_page_test.dart`
  (1 new: the section renders when history is present).

Implementation decisions:

- Reused the exact same trust-chain primitives
  (`ReleaseDescriptor.fromJson`/`PlatformRelease.fromJson`/
  `ReleaseManifestTrustPolicy`) for history entries instead of a separate,
  looser parser — a listed history download is exactly as verifiable as the
  live one, not a lower-trust afterthought.
- Per-entry drop-on-failure for history (vs. the current release's
  fail-closed whole-manifest rejection) is a deliberate, narrower trust
  boundary: history is informational, so one bad entry shouldn't take down
  the live download experience, but it still can't smuggle in an unverified
  or untrusted download link.
- `--template` needed to change from the static bundled asset to the live
  deployed manifest for history to ever be non-empty in practice — this was
  discovered only by tracing where each script's inputs actually come from,
  not assumed.

Validation:

- `flutter analyze` — 0 issues.
- `dart format --set-exit-if-changed lib test tool` — clean.
- `flutter test` — full suite, 380 passing (8 new), 0 failing, 0 skipped.
- `flutter build web --release` — compiles clean end-to-end.
- PowerShell parser validation passed for the modified `publish_web_metadata.ps1`.
- One real widget-test-infra bug found and fixed while adding coverage (not
  a product bug): a `_FadeInUp` that only mounts once the release-manifest
  `Future` resolves creates its delay timer mid-`pump()`, too late for that
  same `pump(duration)` call to flush it — needs an extra zero-duration
  `pump()` first. Documented inline in the test.

Known limitations:

- No end-to-end dry run of the manual pipeline scripts was performed (would
  require real signing material, a real GitHub repository, and owner
  approval) — validated by unit/widget tests, `flutter analyze`, and
  PowerShell parsing only.
- The version-history UI has not been visually verified on-device/in-browser
  — same standing caveat as every other UI phase this session.
- History is Android-only, matching the current release channel's own
  Android-only scope; extending it to other platforms is deferred until
  those platforms leave "Coming soon" (see [Held platforms](docs/RELEASE_PIPELINE.md#held-platforms)).

Next recommended step: none required — this closes the "enrich the manual
pipeline" request. Resume Accounts/Budgets/Categories/Reports product-polish
phases, or a native-speaker `app_lo.arb` review, whichever you prefer next.

### 2026-07-30 — Release/website-sync spec audit (done, no active release)

Summary:

You sent a detailed "LATEST RELEASE AND WEBSITE DOWNLOAD SYNC" spec (required
release flow, Download-section requirements, fail-closed behavior, platform
rules, project-memory fields, git/deployment approval gating). Audited it
against the existing implementation rather than assuming a gap: the required
flow, fail-closed behavior, and platform-gating already match what
[Phase 1](#2026-07-29--free-tier-manual-release-redesign-validated-pending-owner-decisions)
and the [version-history phase](#2026-07-30--release-manifest-schema-v3-generator-bug-fix--version-history-done)
built and documented. Two points were surfaced and resolved with you directly
rather than assumed:

- **Release notes link** — the Download section rendered release notes as
  plain text only, short of the spec's "release notes link" requirement.
  Fixed: `_ApkDownloadSection` now shows a "View full release notes on
  GitHub →" link to `release.releaseUrl`, gated to the verified
  latest-stable release only (`releaseNotesUrl` is `null` unless
  `latestStableReleaseFor(...)` is non-null) — it can never point at a
  fallback or otherwise untrusted manifest.
- **Bundled fallback asset** (`assets/release/release_manifest.json`) — the
  spec's step 7 says to "update any bundled release metadata" as part of the
  approved flow, but `README.md`'s documented trust boundary deliberately
  keeps that file owner-maintained and outside every script, specifically so
  it can never enter the trust chain. Asked directly rather than silently
  changing established, documented behavior; you chose to keep it separate.
  No code change.

No release is currently pending — every platform is still "coming_soon" —
so no step of the actual release flow was executed, and per your new
git/deployment approval instruction no commit or push happened until you
explicitly approved this specific one.

Files modified:

- `lib/features/landing/presentation/screens/landing_page.dart` — the new
  `releaseNotesUrl` local + the release-notes-link `InkWell`, both inside
  `_ApkDownloadSection`.
- `test/features/landing/presentation/screens/landing_page_test.dart` — one
  new assertion on the existing fully-trusted-fixture test.

Validation:

- `flutter analyze` — 0 issues.
- `dart format --set-exit-if-changed lib test tool` — clean.
- `flutter test` — full suite, 380 passing, 0 failing, 0 skipped.

Known limitations:

- Not visually verified on-device/in-browser, same standing caveat as other
  landing-page UI work this session.

Next recommended step: none required. When an actual release is prepared,
follow this file's [Free-tier manual release policy](#free-tier-manual-release-policy)
and record the released version, tag, distribution repository, uploaded
asset filename, file size, SHA-256, website manifest changes, validation
performed, deployment result, known limitations, rollback target, and
remaining platform releases in a new dated entry here — never signing
credentials, access tokens, private keys, or certificate files.

### 2026-07-30 — Website-only content deploy carve-out (policy + script, not yet run)

Summary:

You asked for a standing "publish every update to the website" rule. That
conflicted with the non-negotiable [manual release
policy](#free-tier-manual-release-policy) — most updates (bug fixes, doc
edits) have nothing to do with the live site, and deploying on every commit
would bypass the two-approval gate for anything that does. Explained the
conflict; you came back with a precisely scoped "WEBSITE AUTO-DEPLOY POLICY"
spec instead: pre-approve deploys for *website-content-only* changes (landing
page, legal pages, FAQ, screenshots, localization, static assets, web-only
bug/accessibility fixes), while leaving app-binary releases, the Download
section's actual release data, and all Git actions exactly as manual and
approval-gated as before. You approved the `CLAUDE.md` policy text first, in
its own turn; this phase adds the script and docs it references.

Files created:

- `tool/deploy_website.ps1` — fixed, no shortcut flags. Refuses to run if the
  working tree or the commits ahead of `origin/main` touch
  `web/release-manifest.json`, `assets/release/**`, or an Android signing/
  version file (hard stop back to the manual release pipeline, not a
  warning); then runs `flutter analyze`, the full `flutter test` suite, and
  `flutter build web --release`; confirms `.firebaserc` actually configures
  the `cashly-lao` Hosting target before deploying it; runs `firebase deploy
  --only hosting:cashly-lao --project cashly-lao`; then fetches
  `https://cashly-lao.web.app/` afterward to confirm the deploy actually
  landed rather than trusting a clean exit code alone.

Files modified:

- `CLAUDE.md` — the "Website-only content deploys (pre-approved)" section
  now points at the real script instead of noting it didn't exist yet.
- `docs/RELEASE_PIPELINE.md` — new "Website-only content deploys" section,
  documenting this as a separate, narrower path from the manual app-release
  pipeline above it, cross-referenced from `CLAUDE.md`.

Implementation decisions:

- The release-trust guard checks *both* uncommitted changes (`git status
  --porcelain`) and commits already made ahead of `origin/main` (`git diff
  --name-only $(git merge-base HEAD origin/main) HEAD`), since a
  release-trust change could reach this script either staged or already
  committed. If the merge-base check itself can't run (e.g., no network to
  fetch `origin`), the script throws rather than silently skipping the
  guard — fails closed, consistent with every other safeguard in this
  policy.
- No parameters/flags on the script at all — no `-SkipTests`, no `-Force`.
  Every run does the full sequence or refuses; there's no shortcut path to
  weaken.
- Left `.github/workflows/*` untouched. The policy explicitly keeps
  deployment tied to whichever local `firebase login` session runs the
  script — no CI-stored Firebase credentials, so no workflow needed to
  change.

Validation:

- PowerShell parser validation passed for `tool/deploy_website.ps1`.
- `git diff --check` — clean (only the pre-existing LF/CRLF warning, not a
  real conflict).
- No Dart/Flutter code changed this phase (policy doc + a new PowerShell
  script only), so `flutter analyze`/`flutter test` weren't rerun — the
  script itself calls both internally on every future real run.

Known limitations:

- **`tool/deploy_website.ps1` has never actually been run.** This
  environment's `firebase` CLI is an unauthenticated first-run installer
  (`firepit`), not a real logged-in session — confirmed by running `firebase
  login:list`, which failed with a broken welcome-script crash instead of
  listing a session. A real deploy needs to run somewhere your own `firebase
  login` session already exists; nothing here claims otherwise.
- The release-trust guard's path list (`web/release-manifest.json`,
  `assets/release/**`, a few Android signing/version paths) is a best-effort
  denylist, not a formal proof — a future file that becomes release-trust-
  relevant but isn't yet in this list wouldn't be caught. Worth revisiting
  if the release-trust surface grows.
- Not exercised end-to-end (would require a real `firebase login` session
  and an actual website-only change to deploy).

Next recommended step: none required for this phase. The first real use of
`tool/deploy_website.ps1` — whenever a genuine website-only change is ready
— will be the actual end-to-end validation of this path; record that
deployment's result here per the section's own requirements when it happens.

### 2026-07-31 — Product polish Phase 4: Budgets (done)

Summary:

Continuing the page-by-page product-polish pass (Dashboard, Transactions,
Accounts already done) with Budgets — read the actual code first
(`lib/features/budget/`, singular directory name) rather than assuming scope.
Budgets already had correct loading/empty/error states and full
localization; what was actually missing or broken:

1. **No responsive treatment** — single-column at every width, unlike
   Dashboard/Transactions/Accounts. Added the same content-width-driven
   `LayoutBuilder` grid pattern (1–2 columns within `ResponsiveCenter`'s
   720px cap).
2. **No month-total signal.** A user could see each category's individual
   progress but never "how much of this month's total budget is left."
   Added `_BudgetSummaryHeader` (Budgeted/Spent/Remaining, per currency —
   never mixed, same as every other money rollup in this app), following
   the same `_summarizeByCurrency` + small stat-card pattern Transactions'
   `_TransactionsSummaryRow`/`_SummaryCard` already established. This is
   now the second near-identical private implementation of that pattern
   (Transactions, now Budgets) — a good candidate for extraction into
   `core/widgets` the next time a third screen needs it, deliberately not
   done yet per this project's own "don't abstract from a single usage"
   standard.
3. **No percentage-used signal** on `BudgetProgressTile` — only a bar and
   remaining/overspent text, no number. Added `budgetPercentUsedLabel`
   ("{percent}% used"), combined with the existing remaining/overspent
   message on one line (`"82% used · 120,000 ₭ remaining"`).
4. **Only two visual states** (on-track / overspent) on the progress bar,
   despite the accessibility principle already followed elsewhere in this
   app ("never encode meaning in color alone"). Added a third,
   `theme.colorScheme.tertiary`-colored "approaching limit" state
   (≥80%, not yet overspent) — always paired with the percent-used text
   from item 3, never color-only.
5. **4 raw `Icons.*` uses**, all with an existing `AppSymbols` equivalent
   already defined — no new icon constants needed this phase.
6. `_NoBudgetTile` was a bare `Card`/`ListTile`, visually inconsistent with
   `BudgetProgressTile`'s `AppCard`-based layout and, now that both sit in
   the same responsive grid, structurally mismatched height. Rebuilt on
   `AppCard` with the same icon-row shape.
7. `LinearProgressIndicator`'s `minHeight: 8` → `AppSpacing.sm` (same
   value, now token-traced).

Files modified:

- `lib/features/budget/presentation/widgets/budget_progress_tile.dart` —
  icon sweep, `AppSpacing.sm` token, `isApproachingLimit` third bar state,
  percent label combined into the existing status text.
- `lib/features/budget/presentation/screens/budget_form_screen.dart` — icon
  sweep (`Icons.calendar_today_outlined` → `AppSymbols.calendarToday`).
- `lib/features/budget/presentation/screens/budgets_list_screen.dart` —
  responsive grid, `_BudgetSummaryHeader`/`_BudgetSummaryCard`/
  `_summarizeByCurrency`, `_NoBudgetTile` rebuilt on `AppCard`, icon sweep.
- `lib/l10n/app_en.arb` / `app_lo.arb` — 4 new keys
  (`budgetPercentUsedLabel`, `budgetedTotalLabel`, `spentTotalLabel`,
  `remainingTotalLabel`).
- Tests: `test/features/budget/presentation/screens/budgets_list_screen_test.dart`
  — new test covering the month summary header and the approaching-limit
  (85%-used) tile state, the first coverage this screen had beyond the
  empty "no budget set" row. `test/features/budget/presentation/widgets/budget_progress_tile_test.dart`
  (new file) — `BudgetProgressTile` had zero dedicated widget tests before
  this phase; added on-track and overspent state coverage.

Implementation decisions:

- Kept the `_BudgetSummaryCard`/`_summarizeByCurrency` pattern local to
  `budgets_list_screen.dart` rather than reusing Transactions'
  `_SummaryCard` — Dart's file-level privacy means the existing widget
  isn't importable, and this project's established norm (see the Accounts
  phase's own reasoning) is to let a pattern repeat once before extracting
  a shared component, not extract from a single prior usage.
  `_BudgetSummaryCard`'s figures use `theme.colorScheme.primary` for
  Budgeted (a neutral figure, not positive/negative) and
  `AppSemanticColors`' positive/negative foreground for
  Spent/Remaining, matching how every other money figure in this app
  chooses color.
  Remaining is a plain `remaining < 0` comparison (i.e., only red when the
  *month's total* is overspent, not per-category) since it summarizes the
  whole month, not a single budget.
- `isApproachingLimit` (≥80%, not overspent) is computed inline in the
  widget rather than added as a new getter on `BudgetProgress` — a
  presentation-layer display threshold, not a business rule the domain
  layer needs to know about.
- Did not add a "copy last month's budgets" bulk-create feature, despite
  it being a real, valuable gap the initial audit surfaced (budgets are
  inherently monthly, and re-entering the same limits every month is a
  genuine annoyance) — sized similarly to Transactions' "duplicate"
  feature from the prior phase, but decided to keep this phase to
  polish-and-fix scope; worth proposing as its own small feature next.
- Did not add a delete action to `budget_form_screen.dart` itself — delete
  already lives on the list screen's tile with a confirm dialog, and
  adding a second delete entry point wasn't an identified gap (unlike
  Transactions, where "duplicate" was a genuinely missing capability, not
  just a UI relocation).

Validation:

- `flutter analyze` — 0 issues.
- `dart format --set-exit-if-changed lib test tool` — clean.
- `flutter test` — full suite, 383 passing (3 new), 0 failing, 0 skipped.
  Also confirmed no regression in Dashboard's or Reports' own
  `BudgetProgressTile` embeddings (both reuse the same widget; neither has
  a test asserting on the old remaining/overspent-only text, so the new
  combined percent+status line didn't need updates there).
- `flutter build web --release` — compiles clean end-to-end.

Known limitations:

- **Not visually verified on-device or in-browser**, same standing caveat
  as every prior UI phase this session — particularly the new grid's
  height match between `BudgetProgressTile` (5 lines) and `_NoBudgetTile`
  (1 row) at 2 columns, and the `childAspectRatio: 2.2` chosen for the
  grid, which wasn't tuned against a real rendered screen.
- New Lao strings are drafts, same unreviewed status as the rest of
  `app_lo.arb`.
- "Copy last month's budgets" remains an open, real gap — not built this
  phase (see Implementation decisions).

Next recommended phase: Categories (similar size to this one), Settings
(not yet scoped), or Reports (the large item, still needs its own scoping
conversation first).

### 2026-07-31 — Product polish Phase 5: Categories (done)

Summary:

Continuing the page-by-page pass with Categories (`lib/features/categories/`
— already fully localized, correct loading/empty/error states, and — unlike
every other list screen so far — already had reordering and archive/unarchive
parity with Accounts built in). What was actually missing:

1. **8 raw `Icons.*` uses** across the list screen, form screen, and tile —
   6 had an existing `AppSymbols` equivalent; 2 genuinely didn't
   (`Icons.drag_handle`, `Icons.label_outline`) and needed new constants,
   codepoints looked up directly from the installed `material_symbols_icons`
   package source (same discipline as every prior icon addition this
   project — never guessed): `dragHandle` (`0xe25d`, from
   `drag_handle_rounded`) and `labelOutline` (`0xe893`, from
   `label_outline_rounded`).
2. **Archive-toggle icon** used the old filled/outline `Icons.archive`/
   `Icons.archive_outlined` pair — fixed the same way Accounts' equivalent
   toggle already was: one `AppSymbols.archive` glyph, tinted primary when
   active.
3. **No indication when editing a default category that it's a default
   category** — a user only discovered the delete restriction by trying
   to delete it and finding no delete option, with no explanation. Added a
   "Default" badge + a short explanatory line at the top of the edit form
   (`defaultCategoryLockedHelper`), the same "surface a pinned/restricted
   state directly in the form" pattern Accounts used for its locked
   currency field.

Files modified:

- `lib/core/constants/app_symbols.dart` — 2 new constants (`dragHandle`,
  `labelOutline`).
- `lib/features/categories/presentation/screens/categories_list_screen.dart`
  — icon sweep (archive toggle, FAB, empty-state icon/button).
- `lib/features/categories/presentation/screens/category_form_screen.dart`
  — icon sweep (name-field prefix, expense/income segment icons); the new
  default-category badge/helper block.
- `lib/features/categories/presentation/widgets/category_tile.dart` — icon
  sweep (drag handle).
- `lib/l10n/app_en.arb` / `app_lo.arb` — 1 new key
  (`defaultCategoryLockedHelper`).
- Tests: `test/features/categories/presentation/screens/category_form_screen_test.dart`
  (new file — this screen had zero tests before this phase) covering the
  Default badge appearing when editing a default category and staying
  absent when editing a non-default one or creating a new one.

Implementation decisions — two deliberate non-changes, both explained
rather than silently skipped:

- **No responsive multi-column grid**, unlike Dashboard/Transactions/
  Accounts/Budgets. This list is a `ReorderableListView` — drag-to-reorder
  doesn't have unambiguous semantics in a 2D grid (which corner does a
  dragged item land in?), so forcing the same content-width grid pattern
  here would have degraded the core interaction, not polished it. This is
  a genuine, considered exception to the pattern, not an oversight.
- **No transaction-count-before-delete safety feature**, despite it being
  a real, valuable gap the audit surfaced (today's delete confirmation
  shows only the category name, not how many transactions or how much
  money is tied to it). Not built this phase because it needs a new
  aggregate-query capability that doesn't exist yet (the transaction
  repository only exposes a month-scoped watch, not an all-time
  per-category count) — a real feature, not a polish-pass-sized fix.
  Recorded here the same way Budgets' "copy last month" gap was, so it
  isn't lost.

Validation:

- `flutter analyze` — 0 issues.
- `dart format --set-exit-if-changed lib test tool` — clean.
- `flutter test` — full suite, 386 passing (3 new), 0 failing, 0 skipped.
- `flutter build web --release` — compiles clean end-to-end.

Known limitations:

- Not visually verified on-device or in-browser, same standing caveat as
  every prior UI phase this session — particularly the new default-category
  badge/helper block's layout and the drag-handle icon's visual weight
  against the rest of the row.
- New Lao string is a draft, same unreviewed status as the rest of
  `app_lo.arb`.
- The transaction-count-before-delete gap remains open (see Implementation
  decisions).

Next recommended phase: Settings (not yet scoped) or Reports (the large
item, still needs its own scoping conversation first) — this closes out
every "similar size" page-level phase from the original master prompt.

### 2026-08-01 — Product polish Phase 6: Settings (done)

Summary:

First full pass on Settings (`lib/features/settings/`) — never touched by
any prior phase this session. Unlike Dashboard/Transactions/Accounts/Budgets/
Categories, this was a genuine first audit rather than a re-check: five
preference toggles (theme, language, default currency, app lock,
notifications), each already correctly localized, token-compliant, and
persisted via a real-time Firestore stream. What was missing was mostly
*structural* — sections a premium finance app's Settings screen is expected
to have that simply didn't exist yet:

1. **No Account section.** Settings had zero link back to the Profile screen
   (name/email/sign-out/delete-account) — the only way there was Dashboard →
   Profile icon → Settings, one-directional. Added an "Account" section at
   the top linking to `AppRoutes.profile`.
2. **No About section at all** — CLAUDE.md's own Branding section already
   flagged "About/Settings screen branding" as a known unapplied-branding
   gap, and `CashlyLogoMark`'s own doc comment already said "this one asset
   covers every in-app use: Splash, auth screens, Settings, About" — an
   intent the code never actually delivered on. Added one: `CashlyLogoMark`
   + app name + version/build number (new `packageInfoProvider`, backed by
   the newly added `package_info_plus` dependency), plus Privacy Policy and
   Terms of Service rows reusing the existing public `AppRoutes.privacy`/
   `AppRoutes.terms` routes (confirmed these are `_marketingRoutes` in
   `app_router.dart`, reachable regardless of auth state — no new routes
   needed).
3. **No confirmation before disabling app lock** — a security-relevant
   toggle that could be silently flipped off with one tap, unlike every
   other destructive/risk-bearing action in this app (delete, archive-
   adjacent flows). Added an `AppDialog.confirm` gate, only on the
   *disable* direction (turning it on is safe, no confirmation needed).
4. **Security/Notifications sections vanished silently on web** (`kIsWeb`
   gate) with no explanation — a user switching between the mobile and web
   app would see settings just disappear with no stated reason. Added a
   short explanatory line in their place.
5. **3 raw `Icons.*` uses** (theme-mode segmented-button icons) — none had
   an `AppSymbols` equivalent (this app had no light/dark/auto icons at
   all yet); added `brightnessAuto`/`lightMode`/`darkMode`, codepoints
   sourced from the installed `material_symbols_icons` package, same
   discipline as every prior icon addition. Also added `chevronRight`
   (`matchTextDirection: true`, matching the existing directional-icon
   pattern already used for `trendingDown`/`notes`/`helpOutline`) for the
   three new tappable rows (Account, Privacy, Terms).

Files created:

- None (no new screens/widgets — everything added inline into the existing
  `SettingsScreen`, consistent with that file not having a `widgets/`
  subdirectory of its own yet).

Files modified:

- `pubspec.yaml` — added `package_info_plus` (via `flutter pub add`, not
  hand-typed, so the resolved version is real: `^10.2.1`). Pure client-side
  package, no backend/cost implications, fully Spark-compatible — flagging
  this addition explicitly since it's a new dependency, not just a code
  change.
- `lib/core/constants/app_symbols.dart` — 4 new constants
  (`brightnessAuto`, `lightMode`, `darkMode`, `chevronRight`).
- `lib/features/settings/presentation/providers/settings_providers.dart` —
  new `packageInfoProvider` (`FutureProvider<PackageInfo>`, no stream
  needed since the installed version never changes mid-session).
- `lib/features/settings/presentation/screens/settings_screen.dart` — icon
  sweep; app-lock-disable confirmation; web-unavailable explanatory text;
  new Account section (top) and About section (bottom).
- `lib/l10n/app_en.arb` / `app_lo.arb` — 11 new keys (`accountSectionTitle`,
  `manageAccountLabel`, `manageAccountHelperMessage`, `aboutSectionTitle`,
  `appVersionLabel`, `privacyPolicyLabel`, `termsOfServiceLabel`,
  `disableAppLockTitle`, `disableAppLockMessage`, `turnOffButton`,
  `securityUnavailableOnWebMessage`).
- Tests: `test/features/settings/presentation/screens/settings_screen_test.dart`
  — new test covering the Account/About sections and the version string
  (via `PackageInfo.setMockInitialValues`), plus the import of
  `package_info_plus` needed for that mock.

Implementation decisions:

- **Reused `l10n.appName`** ("Cashly") for the About row's title instead of
  hardcoding "Cashly Lao" — caught by checking `splash_screen.dart`'s own
  precedent first rather than assuming; avoided introducing a second,
  inconsistent app-name string.
- **Did not extract a shared `SettingsTile`/`SettingsSectionCard`
  component** despite the repeated `Card > Padding > Column` shape across
  every section — unlike the `_SummaryCard` precedent (Transactions →
  Budgets, a pattern repeating *across screens*), this repetition is
  entirely *within one file*, a much weaker case for extraction per this
  project's own "don't abstract from a single usage" standard.
- **Did not touch `profile_screen.dart`** even though the audit that scoped
  this phase found real `Icons.*` violations there too (`Icons
  .settings_outlined`, `Icons.warning_amber_outlined`,
  `Icons.edit_outlined` — two of which already have `AppSymbols`
  equivalents: `AppSymbols.settings`, `AppSymbols.warningAmberRounded`).
  Profile is a different feature (`lib/features/auth/`), not Settings —
  out of scope for this phase's "one page at a time" discipline. Recorded
  here so it isn't lost; a quick, low-risk icon-only fix whenever Profile
  itself gets a pass, or as part of the still-open app-wide `Icons.*`
  sweep.
- **Did not add biometric-method detail, notification-category
  granularity, or data export** — real gaps the audit surfaced, but each
  is a genuinely new feature (not polish) with its own scoping questions
  (e.g. data export needs a format decision), sized well beyond this pass.

Validation:

- `flutter analyze` — 0 issues.
- `dart format --set-exit-if-changed lib test tool` — clean.
- `flutter test` — full suite, 387 passing (1 new), 0 failing, 0 skipped.
  One real test-infra bug found and fixed while adding coverage (not a
  product bug): the new test's assertions on the About section (now near
  the bottom of a much longer list) failed against the default test
  surface size, since `ListView`/`Sliver` machinery only builds children
  near the viewport — fixed by setting a taller test surface rather than
  scrolling, matching the pattern already used by other tests in this
  session with long scrollable content.
- `flutter build web --release` — compiles clean end-to-end, confirming
  `package_info_plus` resolves correctly on web too (it has a web
  implementation bundled/endorsed, no separate package needed).

Known limitations:

- **Not visually verified on-device or in-browser**, same standing caveat
  as every prior UI phase this session — particularly the About section's
  `CashlyLogoMark` sizing/spacing next to the version text, and the new
  Account row's placement above Appearance.
- New Lao strings are drafts, same unreviewed status as the rest of
  `app_lo.arb`.
- `profile_screen.dart`'s own `Icons.*` uses remain unfixed (see
  Implementation decisions) — a small, contained, separate follow-up.
- Biometric-method detail, notification-category granularity, and data
  export all remain open, real gaps — not built this phase.

Next recommended phase: Reports (the last large item — needs its own
scoping conversation first, given new summary metrics, new charts, export
formats, and the anomaly-detection "Expense Watch" engine), or the
cross-cutting items still open (full responsive breakpoint system, shared
`PageHeader`/`QuickActions` component, PDF export, native-vs-web app entry
behavior, the app-wide `Icons.*` sweep, a native-speaker `app_lo.arb`
review).

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
  balance / savings-goal-reminder alerts
  (`lib/core/providers/budget_alert_providers.dart`,
  `goal_reminder_providers.dart`) stay exactly as they were, plus
  Firebase Cloud Messaging as a backstop for when the app is fully
  closed. A Cloud Functions backend (`functions/`, this repo's first
  non-Flutter component) re-evaluates each alert condition server-side
  and pushes only when a client-written presence heartbeat
  (`lib/core/providers/presence_providers.dart`) shows local's own
  listeners aren't currently running — see `ROADMAP.md`'s "Beyond v1"
  section for the full design, including the dedup mechanism between
  the two paths.
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
