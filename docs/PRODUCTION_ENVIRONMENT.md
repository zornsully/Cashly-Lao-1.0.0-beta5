# Manual release approval checklist

Cashly Lao does not require a GitHub Environment, required reviewers, OIDC,
GitHub Enterprise, GitHub Team, or Firebase Blaze during development. The
release owner performs two explicit manual approvals instead.

## Approval 1: public APK publication

Review all of the following from the local release evidence before allowing a
GitHub Release:

- immutable source tag and commit;
- `pubspec.yaml` version and Android build number;
- package ID `com.cashlylao.app`;
- APK signature and approved certificate SHA-256 fingerprint;
- APK filename, size, and SHA-256;
- `SHA256SUMS.txt` and reviewed `RELEASE_NOTES.md`;
- exact approved public `owner/repository` distribution target.

The owner must explicitly approve this set before
`publish_github_release.ps1 -ApprovePublicRelease` is run.

## Approval 2: website metadata deployment

After the GitHub Release is public, review the anonymous public APK download:

- exact canonical GitHub release page and download URL;
- public asset name, byte size, and SHA-256;
- generated manifest tag, source commit, and distribution repository;
- web bundle contains no installer binaries.

The owner must explicitly approve the metadata update. A Firebase Spark deploy
also requires the explicit `-ApproveSparkDeployment` switch. No approval may
be implied by a tag push, a CI success, a draft release, or a previous release.
