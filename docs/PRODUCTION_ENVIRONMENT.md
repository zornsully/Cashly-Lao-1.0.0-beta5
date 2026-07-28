# Configure the protected production environment

This is an account-level change. It is intentionally not automated from the
repository.

1. Open the Cashly Lao GitHub repository settings.
2. Create an Environment named exactly production.
3. Enable Required reviewers and add the authorized release reviewers.
4. Restrict deployment branches/tags to the release policy, including matching
   v* tags where supported by your GitHub plan.
5. Confirm the cashly-lao Firebase project is on the Blaze plan, has an active
   billing account, and has budget alerts before enabling direct APK delivery.
6. Configure the Firebase Hosting target cashly-lao, enable the Hosting API,
   and keep the public canonical origin as https://cashly-lao.web.app.
7. Add the Android environment secrets (including the approved upload
   certificate SHA-256 fingerprint) and Firebase OIDC secrets from
   RELEASE_SECRETS.md.
8. Create a dedicated deploy service account with Firebase Hosting deployment
   permissions and bind it through Workload Identity Federation only to this
   repository's protected production environment. Do not create a JSON key.
9. Confirm that no production secret is available to ordinary pull-request
   workflows.
10. Review the workflow permissions: read-only by default; contents: write
    only in the release publication job and id-token: write only in the
    protected Firebase deployment job.
11. Complete the account-level [repository hardening checklist](REPOSITORY_HARDENING.md)
    before enabling the release workflow.

The approval screen should be reviewed against the release summary: tag,
commit, tests, artifacts, sizes, SHA-256 values, reviewed notes, Firebase
preview URL, website changes, unavailable platforms, and warnings.

Reject the approval if any asset, checksum, version, note, Firebase preview
URL, or Hosting target is unexpected. Rejection leaves the current public
website unchanged. The only allowed production promotion is a clone of the
verified Firebase preview version; see
[Firebase Hosting APK delivery](FIREBASE_HOSTING_APK_DELIVERY.md).
