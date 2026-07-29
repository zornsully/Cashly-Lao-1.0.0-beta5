# Free-tier repository hardening

The source repository remains private. A separate public distribution
repository may contain only reviewed APK assets, checksums, release evidence,
and release notes; it must not contain source code, signing material, user
data, or Firebase credentials.

## Required controls

- Keep all Actions workflows at `contents: read`; no release workflow may use
  `contents: write`, `id-token: write`, environments, deployment secrets, or
  Firebase credentials.
- Pin third-party Actions by immutable commit SHA.
- Treat tag-push and workflow-dispatch runs as verification only. CI success
  never publishes a release or deploys a site.
- Keep `assets/release/distribution_policy.json` unconfigured until the owner
  explicitly approves a public distribution repository. The app rejects every
  public download while it is null.
- Do not overwrite an existing release tag or append an asset to it. Publish a
  correction under a new version and leave existing evidence intact.
- Use a dedicated least-privilege GitHub account/session for the public
  distribution repository and enable account-level multi-factor authentication.

Optional GitHub Free branch and tag protections are worthwhile when available,
but they are defense in depth rather than a release prerequisite. The hard
release gates are local validation, exact URL policy, anonymous checksum
verification, and explicit owner approval.
