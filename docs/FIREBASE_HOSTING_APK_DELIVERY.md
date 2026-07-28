# Firebase Hosting APK delivery

## Approved public delivery target

Cashly Lao keeps its source repository private. The public Android download is
served only by the Firebase Hosting site configured in this repository:

| Item | Approved value |
| --- | --- |
| Firebase project | `cashly-lao` |
| Hosting target / site ID | `cashly-lao` |
| Public site | `https://cashly-lao.web.app` |
| Release manifest | `https://cashly-lao.web.app/release-manifest.json` |
| Android asset | `https://cashly-lao.web.app/downloads/Cashly-Lao-Android-<version>.apk` |

The schema-v2 manifest must use that exact Android URL. A private GitHub
release may retain checksums, notes, and provenance for release managers, but
the public manifest must never link to a GitHub release asset or another host.

## Billing and capacity gate

Firebase Hosting on the Spark plan blocks Android `.apk` uploads and hosting.
Before the first direct APK release, a Firebase project owner must confirm that
the `cashly-lao` project is on the pay-as-you-go **Blaze** plan, has an active
Cloud Billing account, and has budget alerts. This is an account-level
prerequisite, not a repository setting.

Review the Hosting storage and data-transfer usage before every production
release. Retained Hosting versions count toward storage, and an APK is a large
download. Do not revert to a ZIP merely to bypass this gate; the approved path
is a direct, signed APK.

## Immutable content contract

The release workflow must copy the already signed and checksum-verified APK to
the final website bundle without repacking it:

```text
build/web/downloads/Cashly-Lao-Android-<version>.apk
```

Only a semver versioned filename may receive the long immutable cache policy in
`firebase.json`. Never overwrite an existing versioned filename, even for a
rollback. A corrected application always receives a new version and a new
filename. The manifest remains `no-store` so visitors promptly receive the
currently approved metadata.

Before approval, the workflow must compare the staged file's size and SHA-256
with the output of Android signature validation and with the manifest. A
private GitHub release record, if used, is evidence only; it is not the public
delivery mechanism.

## Secure deployment identity

GitHub Actions authenticates with Google Cloud Workload Identity Federation
(OIDC), never with a Firebase token or a downloadable service-account key.

- Store `FIREBASE_PROJECT_ID`, `GCP_WORKLOAD_IDENTITY_PROVIDER`, and
  `GCP_SERVICE_ACCOUNT` only in the protected GitHub `production` environment.
- Use a dedicated deploy service account. Grant the documented Firebase
  Hosting deployment permissions (`roles/firebasehosting.admin` and
  `roles/serviceusage.apiKeysViewer`) rather than project Owner or Editor.
- Grant `roles/iam.workloadIdentityUser` on that service account only to the
  GitHub workload identity principal set restricted to this repository and the
  `production` environment. Do not grant the whole workload identity pool.
- Require `id-token: write` only in the protected deployment job. Generated
  `gha-creds-*.json` files and local Firebase CLI state are ignored by Git.

An administrator should record the provider attribute condition and service
account IAM bindings in the release change record. Rotation means replacing or
removing the binding; it never means adding a long-lived JSON key to GitHub.

## Preview, verify, and promote

The protected production job must deploy the final bundle to a short-lived
Firebase Hosting preview channel first. Use the preview URL returned by the
Firebase CLI rather than constructing a URL by hand. Validate all of the
following from that public preview URL:

1. The page shell and `main.dart.js` load.
2. `release-manifest.json` has `Cache-Control: no-store` and names the exact
   tag, commit, version, SHA-256, and Firebase APK URL.
3. The direct APK download is non-empty, has the approved file size and
   SHA-256, and is Android-signed with the approved certificate.
4. The APK response has `Content-Type: application/vnd.android.package-archive`,
   `Content-Disposition: attachment`, `X-Content-Type-Options: nosniff`, and
   an immutable cache policy.

After the final protected approval, promote the exact reviewed preview content
with a Hosting clone, not a second deploy from a workspace:

```text
firebase hosting:clone cashly-lao:<preview-channel> cashly-lao:live --project cashly-lao --non-interactive
```

The clone makes the live channel serve the same Hosting version that passed
preview checks. Then download the public live APK in full, recheck its SHA-256
and size, and revalidate the live manifest before marking the internal release
record healthy.

## Failure and rollback

- Before the live clone: fail the release and leave the live site unchanged.
- After the live clone but before the final health check: stop publication,
  keep the evidence, and restore the last known-good Hosting version through
  the protected rollback workflow.
- A rollback always restores one Hosting version containing the matching page,
  manifest, and APK. Never roll back only a manifest or point it at a different
  APK.

Record the known-good Hosting version ID, tag, Android SHA-256, and manifest
SHA-256 for every successful release. To restore a recorded version, the
protected workflow uses the same site and its live channel:

```text
firebase hosting:clone cashly-lao:@<known-good-version-id> cashly-lao:live --project cashly-lao --non-interactive
```

After rollback, repeat the live page, manifest, direct-download, signature,
size, and checksum checks before announcing it. Keep the broken version and
all private release evidence for audit; do not reuse its APK filename.

## References

- [Firebase Hosting preview channels, cloning, and rollback](https://firebase.google.com/docs/hosting/manage-hosting-resources)
- [Firebase Hosting direct APK / Blaze requirement](https://firebase.google.com/docs/hosting/test-preview-deploy)
- [Firebase Hosting quotas and pricing](https://firebase.google.com/docs/hosting/usage-quotas-pricing)
- [Google Cloud Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
