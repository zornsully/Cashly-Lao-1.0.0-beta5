# Responsive coverage audit

Inventories every screen against the completion-mission's responsive
requirements: mobile/tablet/desktop/wide-desktop status, which shared
primitive (if any) it uses, problems found, fixes applied, and visual
verification status. Read the actual code for every screen listed below —
nothing here is assumed from a feature's name alone.

## Canonical breakpoints (as specified for this audit)

| Range | Tier |
|---|---|
| 0–599px | Mobile |
| 600–1023px | Tablet |
| 1024–1439px | Desktop |
| 1440px+ | Wide desktop |

**Important divergence, flagged rather than silently reconciled**: every
screen audited below was already built against its own locally-chosen
breakpoint (e.g. `home_shell_screen.dart`'s sidebar switch at 760px,
Dashboard's two-column switch at 500/960px, `ResponsiveCenter`'s 720px
content cap) rather than this four-tier scheme, which didn't exist in the
codebase before this document. These existing thresholds were each a
deliberate per-screen decision (see `PROJECT_PROGRESS.md`'s per-phase
entries), not arbitrary. **This audit does not silently rewrite them to
match the four-tier scheme** — that would be a real behavior change
requiring its own review, not a documentation exercise. Where a screen's
existing breakpoint falls inside the tablet tier (600–1023px) but was tuned
by eye against real content rather than the exact tier boundary, that's
called out per-row below rather than corrected.

## Navigation shell

| Screen | Mobile | Tablet | Desktop | Wide desktop | Primitive | Problems found | Fix applied | Visual verification |
|---|---|---|---|---|---|---|---|---|
| `home_shell_screen.dart` (bottom-nav / sidebar shell) | Bottom `NavigationBar`, single column | Sidebar switches on at **760px** (mid-tablet, not the 600px tier start) | Sidebar, collapsed (76px rail) until 1180px | Sidebar expands (244px) at **1180px** (inside the desktop tier, not at the 1440px wide-desktop boundary) | `LayoutBuilder` + two private breakpoint constants | None — deliberate content-driven thresholds, not tier-boundary-driven. Between 600–759px, a tablet in portrait still gets bottom-nav, which is a legitimate product choice (a 600–759px-wide surface is usually a phone in landscape or a small tablet in portrait, where a persistent sidebar would crowd the content) | None needed | Not visually verified |

## Feature screens (list/detail — content-heavy)

| Screen | Mobile | Tablet | Desktop | Wide desktop | Primitive | Problems found | Fix applied | Visual verification |
|---|---|---|---|---|---|---|---|---|
| `dashboard_screen.dart` | Single column, Quick Actions stack | 2-col metric grid ≥500px, Quick Actions 2-col | 4-col metric grid ≥960px, trend/category panels 2-col ≥980px | Same as desktop (`ResponsiveCenter` caps at 720px so wide-desktop doesn't stretch further) | `ResponsiveCenter` + 3 internal `LayoutBuilder`s | None | — | Not visually verified |
| `accounts_list_screen.dart` | 1 column | 2 columns (content width ÷360, clamped 1–3) | 3 columns | 3 columns (capped by `ResponsiveCenter`) | `ResponsiveCenter` + content-width-driven grid | None | — | Not visually verified |
| `transactions_list_screen.dart` | 1 column, existing AppBar search/filter | Desktop summary cards appear ≥640px (4 cards) vs 2 | Same | Same (capped) | `ResponsiveCenter` + internal grid | None | — | Not visually verified |
| `budgets_list_screen.dart` | 1 column | 1 column until 480px, then 3 (unusually low threshold vs other screens — tuned for `BudgetProgressTile`'s own minimum comfortable width, not a copy-paste of another screen's number) | 3 columns | 3 columns (capped) | `ResponsiveCenter` + internal grid | None | — | Not visually verified |
| `categories_list_screen.dart` | 1 column (`ReorderableListView`) | 1 column | 1 column | 1 column (capped at 720px) | `ResponsiveCenter` only, **no grid** | **Deliberate, documented exception** — drag-to-reorder has no unambiguous semantics in a 2D grid (see `PROJECT_PROGRESS.md`'s Categories phase entry) | None needed — confirmed still the right call | Not visually verified |
| `reports_screen.dart` | 1 column | Insights row 2-col, account/category charts stack | Insights row 4-col ≥640px | Same (capped) | `ResponsiveCenter` + internal grid | None | — | Not visually verified |
| `savings_goals_list_screen.dart` | 1 column list | 2–3 columns (content width ÷360, clamped 1–3, same convention as Accounts) | Same | Same (capped by `ResponsiveCenter`) | `ResponsiveCenter` + content-width-driven grid | **Fixed.** A real 1.2px `RenderFlex` overflow was caught by the existing widget test the moment the grid path activated (`childAspectRatio: 2.6` gave `GoalCard` too little height) — not assumed away. Widened to `2.2` (matching Budgets' own tile-shape precedent) and reverified. | `LayoutBuilder` + `GridView.builder`/`ListView.separated` switch added, mirroring `accounts_list_screen.dart` exactly; new widget test added covering 2 goals rendering in the grid (`test/.../savings_goals_list_screen_test.dart`) | Not visually verified |
| `savings_goal_detail_screen.dart` | 1 column | 1 column (capped at 720px) | Same | Same | `ResponsiveCenter` | None — a detail screen's natural shape (one goal, sequential sections) doesn't benefit from multi-column the way a list screen does | — | Not visually verified |
| `settings_screen.dart` | 1 column list of section cards | 1 column (capped at 720px) | Same | Same | `ResponsiveCenter` | None — a settings list is inherently sequential, matches Categories' own reasoning | — | Not visually verified |

## Forms (all consistently capped, same pattern across every feature)

| Screen | Mobile | Tablet+ | Primitive | Problems found |
|---|---|---|---|---|
| `transaction_form_screen.dart` | Full width | Capped + centered at 520px | `ConstrainedBox` (520px) | None |
| `budget_form_screen.dart` | Full width | Capped + centered at 520px | Same | None |
| `category_form_screen.dart` | Full width | Capped + centered at 520px | Same | None |
| `account_form_screen.dart` | Full width | Capped + centered at 520px | Same | None |
| `savings_goal_form_screen.dart` | Full width | Capped + centered at 520px | Same | None |

All five forms independently converged on the same 520px cap — a real,
consistent pattern, not a coincidence worth re-deriving from scratch.

## Authentication (all via shared `AuthScaffold`)

| Screen | Mobile | Tablet+ | Primitive | Problems found |
|---|---|---|---|---|
| `login_screen.dart` | Full width | Capped + centered at 440px | `AuthScaffold` | None |
| `register_screen.dart` | Full width | Capped + centered at 440px | `AuthScaffold` | None |
| `forgot_password_screen.dart` | Full width | Capped + centered at 440px | `AuthScaffold` | None |
| `verify_email_screen.dart` | Full width | Capped + centered at 440px | `AuthScaffold` | None |
| `profile_screen.dart` | Full width | Capped + centered at 440px | Hand-rolled `Center`+`ConstrainedBox` (identical values to `AuthScaffold`, doesn't reuse it since Profile has an `AppBar`/menu `AuthScaffold` doesn't model) | None — the duplication is small and intentional, not an oversight |

## Minimal-content screens (inherently width-agnostic, no primitive needed)

| Screen | Why no responsive primitive is needed |
|---|---|
| `splash_screen.dart` | `Center` + `Column(mainAxisSize: MainAxisSize.min)` — content is a logo/spinner, shrinks to its own size and centers at any width. Confirmed correct, not an oversight. |
| `lock_screen.dart` | Same pattern (logo + message + one button) |

## Public web (landing + legal + download section)

| Screen | Mobile | Tablet | Desktop | Wide desktop | Primitive | Problems found |
|---|---|---|---|---|---|---|
| `landing_page.dart` | Nav collapses, hero stacks <760px, feature/screenshot grids single-column <440–620px depending on section | Each section has its own tuned `LayoutBuilder` breakpoint (460/600/620/700/720/760/800/920/1040px depending on section) | Multi-column grids activate (2–4 columns depending on section) | Same, page has no outer width cap (deliberately, per its own established local design convention — see `TODO.md`'s landing-page exemption note) | Per-section `LayoutBuilder`s, **not** `ResponsiveCenter`/`AppSpacing` (confirmed deliberate — this page has never used the authenticated app's design-token system, it's the public marketing page with its own established convention) | None found this pass — already has the most thorough per-section responsive coverage of any screen in the app, just via a different (and already-documented) mechanism than the rest of the app |
| `legal_document_page.dart` | Full width, scrollable | Capped + centered at 850px | Same | Same | Hand-rolled `Center`+`ConstrainedBox`, same local-design-convention exemption as `landing_page.dart` | None |
| Download section (`_ApkDownloadSection` inside `landing_page.dart`) | Stacks | Stacks until its own threshold | Side-by-side | Side-by-side | Same per-section `LayoutBuilder` as the rest of the landing page | None found | — |

## Summary

- **22 of 23 screens** (everything except the two landing-page files, which
  have their own established, deliberate local convention) already have
  real, working responsive behavior — this was substantially built during
  the earlier "Product polish" phases (see `PROJECT_PROGRESS.md`), not
  newly discovered as missing.
- **The one real gap found — `savings_goals_list_screen.dart` never
  gridding into multiple columns — is now fixed**, mirroring Accounts'
  exact pattern. Fixing it surfaced a genuine layout bug (a 1.2px overflow
  in `GoalCard` at the chosen aspect ratio), caught by the existing widget
  test rather than assumed away — the same class of bug this project's own
  history has hit and caught before during grid additions (Budgets,
  Transactions). Corrected and reverified; new test coverage added for the
  multi-column path specifically.
- **No screen was found stretching a mobile layout edge-to-edge on desktop,
  or squeezing a desktop layout into a phone viewport** — the two failure
  modes the completion-mission spec specifically warns against.
- **Every breakpoint number in this app is a deliberate, code-visible
  choice**, not a magic number picked at random — but none of them match
  the newly-introduced four-tier canonical scheme exactly. That scheme was
  never part of this codebase before this document; reconciling every
  screen's breakpoint to it would be a real, visible behavior change (e.g.
  `home_shell_screen.dart`'s sidebar would need to appear 160px earlier)
  and should be a deliberate product decision, not a side effect of writing
  an audit.
- **Visual verification status: attempted, partially blocked.** This audit
  confirms structural correctness (the code that decides what renders at
  what width) via direct code reading, not rendered appearance at each
  breakpoint — with one real exception: `build/web` was served locally
  (`python -m http.server`, via `.claude/launch.json`) and loaded in this
  session's Browser tool. Confirmed via the browser's own console and
  network logs (not guessed): the app loads with **zero console errors**,
  Firebase initializes cleanly (`core`/`firestore`/`analytics`/`auth`/
  `messaging`, all six SDKs), and every asset request returned `200 OK`
  (fonts, `MaterialSymbolsRounded.ttf`, the logo, store screenshots,
  `release_manifest.json`, `distribution_policy.json`). This is the first
  time this project's own web build has been loaded in an actual browser
  session rather than only `flutter build web --release` exiting cleanly.
  **What this does NOT confirm**: actual pixel-level rendering at any
  breakpoint — the Browser tool's screenshot capability failed with "the
  Browser pane is not displayed, so the page is not compositing frames" on
  every attempt this session, a client-side display-state limitation this
  session couldn't work around, not a bug in the app. So: load-time
  correctness is now genuinely verified; rendered appearance at 320/375/
  600/768/1024/1280/1440px is still not. See `CLAUDE.md`'s standing "not
  visually verified" caveat for the remainder.

## Suggested next actions

1. **Decide whether to reconcile per-screen breakpoints to the new
   canonical four-tier scheme.** Not done in this pass — a real product/
   design decision, not a mechanical fix. If yes, `home_shell_screen.dart`'s
   sidebar switch (currently 760px) is the highest-visibility one to
   reconsider, since it's the one navigational decision every authenticated
   screen inherits.
2. ~~Give `savings_goals_list_screen.dart` a multi-column grid~~ — done.
3. **Real visual verification** — on an actual device/browser, at minimum
   the required test widths (320/375/600/768/1024/1280/1440px) — remains
   the single largest gap between "structurally correct" and "actually
   verified," for every screen in this app, not just the ones touched this
   session.
