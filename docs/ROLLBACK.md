# Manual website metadata rollback

A rollback changes the Firebase Spark website manifest to point to a preserved,
previously verified public GitHub Release. It does **not** delete, overwrite,
unpublish, or retag any GitHub APK asset.

## Before a release

Keep the local release package directory created by
`prepare_manual_release.ps1`, including:

- `release-evidence.json`;
- `SHA256SUMS.txt`;
- reviewed `RELEASE_NOTES.md`;
- `public-release-verification.json` produced after anonymous verification.

## Rollback procedure

1. Select the known-good package directory and confirm it belongs to the
   approved public distribution repository.
2. Obtain explicit owner approval for a website-only rollback.
3. Run:

   ```powershell
   .\tool\rollback_web_metadata.ps1 `
     -DistributionRepository owner/public-release-repository `
     -PackageDirectory build\manual-release\vX.Y.Z `
     -ApproveWebsiteRollback
   ```

4. The script rechecks the public GitHub asset's canonical URL, size, and
   SHA-256 before generating the prior manifest. Review it.
5. For an approved Spark deployment, repeat with
   `-DeployToSpark -ApproveSparkDeployment`.
6. Fetch `https://cashly-lao.web.app/release-manifest.json` and validate it
   again. Test its Android button manually.

If the bad APK itself must be withdrawn, stop: that is a separate owner
decision outside this automated process. Do not silently delete history or
replace the APK at the same versioned URL. Publish a corrected new version and
record the incident in the release notes.
