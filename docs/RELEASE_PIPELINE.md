# Cashly Lao release pipeline

## Safety model

The repository can prepare and validate release candidates automatically. It
cannot publish a public APK, replace production downloads, or deploy the
website until an authorized reviewer approves a GitHub Environment named
production.

Production secrets are never available to pull-request workflows. The built-in
GITHUB_TOKEN receives write permission only in the private release-provenance
job. Account-level protections that keep workflow edits and release tags
immutable are listed in [Repository release hardening](REPOSITORY_HARDENING.md).

## Architecture

    Pull request -> verification and preview artifact only
    main branch  -> verification and staging-ready web artifact only
    v* tag/manual release -> version checks, platform builds, review artifacts
    first production approval -> protected Android signing
    exact signed Android + website bundle -> final artifact summary -> second production approval
    private GitHub provenance + Firebase preview -> hosted APK verification -> exact preview-to-live clone -> live health check

GitHub releases remain private immutable provenance for release managers.
Firebase Hosting serves the website, release manifest, and signed Android APK.
The public site only receives a new manifest after the matching versioned
Firebase preview APK is downloaded, signature-checked, and checksum-verified.
The private source repository is never made public to deliver an APK.

## Workflows

| Workflow | Trigger | What it may do |
|---|---|---|
| ci.yml | Pull requests and main pushes | Format, lint, test, Functions checks; no deployment secrets |
| web-preview.yml | Pull requests and main pushes | Build a reviewable web artifact; no production deploy |
| release.yml | v* tag or manual dispatch | Prepare validated platform artifacts and request protected approval before publication |
| rollback-production.yml | Manual dispatch | Restore the checksum-verified Firebase Hosting version for a known-good release tag after protected approval |

## Standard release process

1. Update version in pubspec.yaml and the reviewed RELEASE_NOTES.md.
2. Confirm the cashly-lao Firebase project is on Blaze and that budget alerts
   are active. Spark blocks direct APK Hosting.
3. Run Flutter analysis and tests locally.
4. Commit and push the intended changes.
5. Create and push the matching tag, for example v1.0.3 for version 1.0.3+4.
   A tag push prepares review candidates only; it never publishes a release or
   deploys the production website.
6. Review the generated validation summary, artifacts, checksums, platform
   availability, draft release notes, and known warnings.
7. Start release.yml manually for the same immutable tag, choose publish,
   confirm that the tag's release notes were reviewed, and use the tag in
   GitHub's ref selector rather than an unrelated branch.
8. Approve or reject the first production environment request. It is the only
   point where protected Android signing credentials can be used.
9. Review the final artifact summary: notes hash; signed APK name, size,
   SHA-256, and signer identity; exact website package; strict manifest
   validation; Firebase Hosting plan; and unavailable platforms. Then approve
   or reject the second production request.
10. After the second approval, the workflow creates private provenance, stages
    the exact signed APK at the Firebase URL, and validates a Firebase preview:
    page, JavaScript, no-store manifest, APK headers, APK signature, byte size,
    and checksum. It then clones that exact preview version to live and repeats
    the live checks. Confirm the final report shows the expected version.

## Notes review

tool/generate_release_notes.dart creates a review-only Markdown draft from
local Git history. It never publishes anything. Edit and commit
RELEASE_NOTES.md before tagging; that reviewed file is the source used for a
production release.

## Platform availability

Every configured platform receives a build/availability job. A platform without
the required signing or packaging configuration is reported as unavailable and
remains Coming soon; the workflow does not fabricate an asset or download
button.

The initial approved production targets are Android APK and Web. Android AAB,
iOS/TestFlight, Windows, and macOS distribution are enabled only after their
respective account-level requirements are configured.

## Version and artifact checks

tool/verify_release.dart rejects tag/version mismatches, invalid artifact
names, empty files, bad checksums, malformed manifest documents, and, when
requested, an unsigned or invalid Android APK. It produces a JSON summary for
approval review.

tool/generate_release_manifest.dart writes schema-v2 metadata only from a
verified signed artifact staged at the exact, versioned Firebase Hosting URL.
The website bundle, APK, and manifest are fully verified before final approval,
then the exact reviewed preview Hosting version is cloned to live. The app
accepts only the official cashly-lao.web.app Android URL for the declared
version and artifact name; prereleases never displace a stable website download.

## Retry and failure handling

- A failed validation or build ends the workflow before publication.
- A failed private provenance upload, Firebase OIDC authentication, or preview
  deployment leaves the live Hosting version and manifest unchanged.
- A failed preview APK checksum, header, signature, or manifest check ends
  before promotion. Do not clone or redeploy that preview to live.
- A failed live health check after a clone requires the protected rollback
  workflow or a new version; keep the failed Hosting version and evidence for
  investigation.
- Do not delete historical private GitHub release evidence or Firebase Hosting
  versions.

## Common issues

| Symptom | Safe response |
|---|---|
| Tag/version mismatch | Correct pubspec.yaml or create the matching tag; do not retag an already published release. |
| Android signing failure | Recreate protected Android secrets from the owned keystore; never add key.properties or the keystore to Git. |
| production approval unavailable | A repository administrator must create the environment and set required reviewers. |
| Firebase authentication failure | Verify the Workload Identity Federation binding, service account, Hosting roles, and protected environment; do not add a personal token. |
| APK upload blocked | Confirm the cashly-lao project is on the Blaze plan; Spark blocks APK Hosting. |
| Preview differs from expected APK | Stop before cloning. Compare the signed artifact, staged path, manifest, headers, size, and SHA-256. |
| Website points to an old release | Inspect the deployed schema-v2 manifest and use the protected rollback workflow if necessary. |

## Adding a platform

1. Add the Flutter runner and platform identifier.
2. Add the platform's signed build/packaging job and explicit availability
   output to release.yml.
3. Add its credential names and setup instructions to RELEASE_SECRETS.md.
4. Extend manifest validation and download-card tests.
5. Verify a review artifact before allowing a protected production release.
