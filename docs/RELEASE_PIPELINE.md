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

## 1. Prepare a signed APK locally

Check out a clean, immutable stable source tag. Then run:

```powershell
.\tool\prepare_manual_release.ps1 `
  -ReleaseTag vX.Y.Z `
  -ExpectedAndroidCertificateSha256 YOUR_APPROVED_CERTIFICATE_SHA256
```

The tool refuses a dirty checkout or a tag/version mismatch. It builds the
release APK locally with CI signing enforcement, then validates:

- package ID `com.cashlylao.app`;
- version name and Android version code;
- APK signature and exact certificate fingerprint;
- canonical artifact filename and positive byte size;
- SHA-256 and `SHA256SUMS.txt`;
- reviewed notes and source commit provenance.

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
