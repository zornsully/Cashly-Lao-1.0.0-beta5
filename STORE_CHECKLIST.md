# Play Console Checklist — Everything Left to Launch

Stage 7 (Store Readiness & Launch) prep work — listing copy, screenshots, a
feature graphic, and a signed release build — is done and sitting in this
repo. Everything below needs your own Google Play Console account and
judgment calls only you can make; none of it can be done from a PR.

## What's already prepared for you

| Asset | Location |
|---|---|
| Signed release bundle (upload this) | `build/app/outputs/bundle/release/app-release.aab` |
| App icon, 512×512 | `assets/logo/play_store_icon_512.png` |
| Feature graphic, 1024×500 | `store_assets/feature_graphic_1024x500.png` |
| Phone screenshots (Lao + English, 5 each) | `store_assets/screenshots/` |
| Store listing copy (short + full description, EN + LO) | `STORE_LISTING.md` |
| Privacy policy content | `PRIVACY_POLICY.md` |

The screenshots show realistic sample data (two accounts in LAK and USD,
a few transactions, a budget with progress) rather than empty states —
swap in fresh ones later if the app's visual design changes.

## 1. Google Play Console account

- [ ] Enroll as a developer at [play.google.com/console](https://play.google.com/console) if you haven't (one-time $25 fee, ID verification required — this can take a few days, so start it early).
- [ ] Create a new app, package name **`com.cashlylao.app`** (must match exactly — this is fixed by `android/app/build.gradle.kts`'s `applicationId` and can't be changed later).

## 2. Store listing

- [ ] Paste in the short/full description from `STORE_LISTING.md`. Play Console supports per-language listings — add both an English (en-US) and Lao (lo-LA) listing if you want the Lao text to show for Lao-locale devices, using the Lao draft translations (get a native speaker to review them first, per the note at the top of that file).
- [ ] Upload the app icon, feature graphic, and 2–8 screenshots from the tables above.
- [ ] Category: **Finance**.
- [ ] Contact details: reuse the email/developer name from `PRIVACY_POLICY.md`.

## 3. Privacy policy — needs a real URL

Play Console requires a **live, publicly reachable URL** for the privacy
policy, not a file. `PRIVACY_POLICY.md`'s content is ready; you still need
to:
- [ ] Host it somewhere (a simple static page on your own domain, a GitHub Pages site, Firebase Hosting, or similar).
- [ ] Paste that URL into Play Console's "Privacy policy" field.

## 4. Data Safety form

Fill this in directly from what `PRIVACY_POLICY.md` documents:
- [ ] Data collected: email, display name, optional profile photo (Firebase Auth); financial data the user enters — accounts, transactions, categories, budgets (Firestore); crash diagnostics (Crashlytics).
- [ ] Purpose: account functionality, app functionality, and (for crash data) analytics/diagnostics.
- [ ] Data sharing: none, beyond the Google/Firebase infrastructure processing it on your behalf.
- [ ] Data deletion: yes — in-app self-service (Profile → Delete account), which cascades to all of the user's financial data (verified in code, see `auth_remote_datasource.dart`'s `deleteAccount`).
- [ ] Encryption in transit: yes (Firebase uses HTTPS throughout).

## 5. Content rating & app content declarations

- [ ] Complete the content rating questionnaire (a personal finance tracker with no user-generated content, ads, or social features should land in the lowest rating tier, but answer it yourself — don't guess on Google's behalf).
- [ ] **Financial features declaration**: Play Console asks specifically about apps handling financial data. Cashly does not move real money, connect to bank accounts, or process payments — it's a manual tracker — declare accordingly.
- [ ] Target audience: not designed for children (`PRIVACY_POLICY.md` already states this; keep the declarations consistent with it).

## 6. Closed testing track (this is the actual beta rollout)

- [ ] Create a Closed testing track, upload `app-release.aab`.
- [ ] **Enroll in Play App Signing** if prompted (Google's recommended default) — this re-signs the app for distribution with a Google-managed key while still trusting your upload key. If you skip it, your upload keystore (`android/app/upload-keystore.jks`, gitignored, back it up now if you haven't) becomes the only key that can ever update this app.
- [ ] Add your beta testers — either individual emails or a Google Group. This is on you to recruit; a handful of real users who'll actually poke at every screen is worth more than a large silent list.
- [ ] Publish the closed testing release and share the opt-in link Play Console generates.

## 7. Watch the beta, then decide

- [ ] Give it real time — this is inherently paced by how fast your testers actually use the app, not something to rush.
- [ ] Watch Crashlytics for the crash-free rate and any new crash groups (recall: Crashlytics only collects from release builds, per `lib/main.dart`'s `!kDebugMode` gate — debug installs won't show up here).
- [ ] Collect feedback from testers directly (a shared doc, a form, whatever's easiest for them).
- [ ] Make the go/no-go call for public release yourself, backed by that crash-free-rate number and the feedback — this is exactly the kind of judgment call the roadmap flags as needing a human, not something to automate.

## Known gap: iOS

Everything above is Android-only. This project has never been built, signed, or
tested on iOS — there's no App Store Connect equivalent of any of this yet.
