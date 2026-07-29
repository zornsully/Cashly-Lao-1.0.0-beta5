# Cashly Lao

Cashly Lao is a cross-platform personal finance app for Laos. The public
landing page is available without sign-in and reads its release details from a
central JSON manifest instead of embedding release numbers or download links in
the app UI.

## Secure releases

The repository contains a credential-free, approval-gated release pipeline.
It can prepare and validate artifacts automatically, but production publishing
and Firebase Hosting deployment require a GitHub production environment
approval. See:

- [Release pipeline](docs/RELEASE_PIPELINE.md)
- [Firebase Hosting APK delivery](docs/FIREBASE_HOSTING_APK_DELIVERY.md)
- [Required secrets](docs/RELEASE_SECRETS.md)
- [Production environment setup](docs/PRODUCTION_ENVIRONMENT.md)
- [Repository hardening](docs/REPOSITORY_HARDENING.md)
- [Rollback procedure](docs/ROLLBACK.md)

## Release metadata

assets/release/release_manifest.json is a bundled, informational fallback. The
public website reads the verified schema-v2 manifest served from Firebase
Hosting; a legacy fallback can describe availability but cannot unlock a
download button. For the private-source release model, Firebase Hosting serves
the signed Android APK directly at an immutable, versioned URL. GitHub release
records are private provenance only and are never used as public download URLs.

The manifest and APK are generated only after the matching Android artifact is
validated in a protected workflow. The exact website bundle, manifest, and APK
are reviewed in a Firebase preview channel before final approval; production
receives that same checked Hosting version through a preview-to-live clone.

The manifest provides each platform's availability, version, build number,
release date, file size, minimum OS, immutable Firebase download URL, SHA-256
checksum, reviewed notes, and latest-stable status. Browser visitors retain the
last verified public manifest during a temporary release-service outage.

Use the workflows and tools described in
[the release pipeline guide](docs/RELEASE_PIPELINE.md). Direct APK delivery
requires the Firebase project to be on the Blaze plan; do not use the legacy
ZIP staging scripts for a production release.
