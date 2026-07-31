# Manual free-tier release pipeline

This is the development release process for Cashly Lao. It uses Firebase Spark
for static website hosting and GitHub Free for source control and release
assets. It has no automatic publishing step.

## Before the first public APK

1. Keep `zornsully/Cashly-Lao-1.0.0-beta5` private.
2. Obtain explicit owner approval to create or nominate a separate public
   distribution repository containing release assets only. Do not create it
   from this process without that approval.
3. Review and commit the exact `owner/repository` in
   `assets/release/distribution_policy.json`. Until then it must stay `null`.
4. Build and deploy a website containing that reviewed bundled policy before
   asking the site to accept a schema-v3 public release manifest. This is not a
   download-link update and still requires normal source review.

## 1. Prepare a signed APK (and AAB) locally

Check out a clean, immutable stable source tag. Then run:

```powershell
.\tool\prepare_manual_release.ps1 `
  -ReleaseTag vX.Y.Z `
  -ExpectedAndroidCertificateSha256 YOUR_APPROVED_CERTIFICATE_SHA256
```

The tool refuses a dirty checkout or a tag/version mismatch. It builds
**both** the release APK and the release AAB locally with CI signing
enforcement, then validates the APK:

- package ID `com.cashlylao.app`;
- version name and Android version code;
- APK signature and exact certificate fingerprint;
- canonical artifact filename and positive byte size;
- SHA-256 and `SHA256SUMS.txt`;
- reviewed notes and source commit provenance.

The AAB is checksummed (`AAB_SHA256SUMS.txt`) and kept as local evidence
only, for future Play Store readiness — it is never published or linked
from the website, since an AAB isn't directly installable the way a
sideloaded APK is, and Play Store submission is a separate, not-yet-taken
step requiring its own owner approval.

It writes immutable local evidence to `build/manual-release/vX.Y.Z` and stops.
It does not contact GitHub, Firebase, or any public service.

## 2. Review and approve public publication

Review the local evidence, notes, certificate fingerprint, source tag/commit,
APK size, and checksum. The release owner must explicitly approve the exact
artifact and target distribution repository. Then run:

```powershell
.\tool\publish_github_release.ps1 `
  -DistributionRepository owner/public-release-repository `
  -PackageDirectory build\manual-release\vX.Y.Z `
  -ApprovePublicRelease
```

The tool verifies the policy and public repository visibility, refuses an
existing tag, uploads a **draft**, downloads it again while authenticated,
compares its hash, publishes the release, and downloads the release asset
anonymously. It will not update the website. If any check fails before the
release becomes public, the draft remains private; if a later check fails, the
site remains unchanged.

## 3. Review and approve website metadata

Only after the public APK's direct URL, size, and SHA-256 pass anonymous
verification, review the generated manifest inputs. Then run:

```powershell
.\tool\publish_web_metadata.ps1 `
  -DistributionRepository owner/public-release-repository `
  -PackageDirectory build\manual-release\vX.Y.Z `
  -ApproveWebsiteMetadata
```

This generates and validates the schema-v3 manifest, updates local web
metadata, and builds a Spark-safe web bundle. It does not deploy by default.
Generation diffs against the currently deployed `web/release-manifest.json`:
if that manifest's Android entry was `available` under a different version,
it is carried forward into the new manifest's `history` array (capped at the
10 most recent entries) instead of being discarded, so the landing page's
version history section can keep showing verified past downloads. For a
separately approved deployment, add:

```powershell
-DeployToSpark -ApproveSparkDeployment
```

The deploy command is always limited to `hosting:cashly-lao`; it does not
deploy Functions, Firestore rules, or an APK. The script fetches and validates
the live manifest after deployment.

## Web service-worker strategy (deliberate, unmodified)

`web/` has no hand-written or overridden service-worker code — no custom
`flutter_service_worker.js`, no custom registration logic in `index.html`
(it loads `flutter_bootstrap.js` with no `serviceWorkerSettings` override).
This is the deliberate choice, not an oversight: Flutter's own default web
bootstrap already generates a fresh `flutter_service_worker.js` on every
`flutter build web --release`, keyed by a content hash of the build's own
assets, so a redeploy's new JS/asset hashes don't collide with a
previously cached version — the standard mechanism Flutter's web tooling
uses to avoid serving stale JS after a deploy. Hand-rolling a custom
service worker on top of that would risk exactly the stale-asset problem
it's meant to prevent, without a corresponding benefit for this app (no
custom offline-first experience is scoped for the public website).
**Not yet verified through an actual redeploy cycle** in this environment
(no live `firebase deploy` session available) — confirm on the next real
website deploy that a hard-refreshed browser picks up the new build
rather than a stale cached one.

## Website-only content deploys

A second, narrower path exists for changes that are only about
[cashly-lao.web.app](https://cashly-lao.web.app)'s content — the landing
page, Privacy Policy, Terms, FAQ, screenshots, website localization, other
static web assets, and web-only bug/accessibility/responsive fixes. It is
**not** part of the app-release pipeline above and never touches release
data.

```powershell
.\tool\deploy_website.ps1
```

The script:

1. Refuses to run if the working tree or the commits ahead of `origin/main`
   touch `web/release-manifest.json`, `assets/release/**`, or an Android
   signing/version file — those changes must go through the manual release
   pipeline above instead.
2. Runs `flutter analyze`, the full `flutter test` suite, and
   `flutter build web --release`; any failure stops before deploying.
3. Confirms `.firebaserc` actually configures the `cashly-lao` Hosting
   target before deploying it.
4. Runs `firebase deploy --only hosting:cashly-lao --project cashly-lao`,
   using whichever local `firebase login` session the executing environment
   has — no credentials are stored in this repository.
5. Fetches the live site afterward to confirm the deploy actually landed,
   rather than trusting a clean `firebase deploy` exit code alone.

Per `CLAUDE.md`'s [Website-only content deploys](../CLAUDE.md#website-only-content-deploys-pre-approved)
policy, running this script does not itself require a separate approval once
its own checks pass — but it never authorizes a Git action (commit, push,
merge, tag), and it structurally cannot touch application-binary releases,
since it refuses to run the moment a release-trust file is in scope.

## CI's role

`release.yml`, `prepare-release.yml`, and `web-preview.yml` run read-only
formatting, analysis, tests, source-tag checks, release-note drafts, and web
review builds. `rollback-production.yml` is read-only guidance. None of them
has release-write, deployment, environment, OIDC, signing, or Firebase
credentials.

## Held platforms

Android is the only potential development distribution channel. iOS, Windows,
and macOS remain “Coming soon” until their signing, platform validation, and
separate owner approval are added.
