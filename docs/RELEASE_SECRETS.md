# Release secrets checklist

Never paste secret values into issues, pull requests, chat, source code, or
workflow files. Add them in GitHub Settings -> Environments -> production ->
Environment secrets only after the production environment has required
reviewers.

## Required for the initial Android + Web release

| Name | Purpose | How to obtain |
|---|---|---|
| ANDROID_UPLOAD_KEYSTORE_BASE64 | Owned Android upload keystore, encoded for CI | Export the existing owned .jks file and encode it locally; do not commit the file. |
| ANDROID_KEYSTORE_PASSWORD | Opens the keystore | Obtain from the Android signing-key custodian. |
| ANDROID_KEY_ALIAS | Selects the upload key | Obtain from the signing-key custodian. |
| ANDROID_KEY_PASSWORD | Unlocks the selected upload key | Obtain from the signing-key custodian. |
| ANDROID_SIGNING_CERT_SHA256 | Approved SHA-256 fingerprint of the Android upload certificate | Export from the owned keystore with keytool -list -v; store only the normalized 64-character fingerprint. |

Firebase deployment uses GitHub OIDC / Google Cloud Workload Identity
Federation rather than a long-lived Firebase token. Store these only in the
protected production environment:

| Variable | Purpose | How to obtain |
|---|---|---|
| FIREBASE_PROJECT_ID | Firebase project to deploy | Firebase Console project settings (cashly-lao). |
| GCP_WORKLOAD_IDENTITY_PROVIDER | GitHub trust provider resource name | Created by a Google Cloud project administrator. |
| GCP_SERVICE_ACCOUNT | Narrowly scoped Hosting deploy service account | Created by a Google Cloud project administrator. |

The site ID is deliberately not a secret or a workflow input. It is fixed in
.firebaserc and firebase.json as cashly-lao, so a secret cannot redirect a
public download to another Hosting site. The trusted direct Android URL is
https://cashly-lao.web.app/downloads/Cashly-Lao-Android-<version>.apk.

## Firebase APK delivery prerequisite

The cashly-lao Firebase project must be on the pay-as-you-go Blaze plan before
deploying an .apk. Spark projects block Android APK hosting. Verify the billing
account and budget alerts in the Firebase / Google Cloud console; neither is a
GitHub secret and neither should be simulated in a workflow.

Use a dedicated OIDC deploy service account with Firebase Hosting deployment
permissions only. Do not add FIREBASE_TOKEN, GOOGLE_APPLICATION_CREDENTIALS,
or a service-account JSON secret. Bind roles/iam.workloadIdentityUser only to a
GitHub identity restricted to this repository and its protected production
environment. See [Firebase Hosting APK delivery](FIREBASE_HOSTING_APK_DELIVERY.md)
for the required preview, clone, and rollback checks.

## Conditional integrations

| Integration | Names | When needed |
|---|---|---|
| Google Play | GOOGLE_PLAY_SERVICE_ACCOUNT_JSON | Only when publishing an AAB to Google Play. |
| iOS/TestFlight | IOS_DISTRIBUTION_CERT_BASE64, IOS_DISTRIBUTION_CERT_PASSWORD, IOS_APPSTORE_PROFILE_BASE64, APP_STORE_CONNECT_API_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_API_KEY_BASE64 | Only after Apple Developer enrollment and App Store Connect configuration. |
| macOS signed/notarized distribution | MACOS_DEVELOPER_ID_CERT_BASE64, MACOS_DEVELOPER_ID_CERT_PASSWORD, APP_STORE_CONNECT_API_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_API_KEY_BASE64 | Only after Developer ID and notarization setup. |
| Windows signing | WINDOWS_SIGNING_CERT_PFX_BASE64, WINDOWS_SIGNING_CERT_PASSWORD | Only before public Windows installer publication. |

## Built-in token

The release job uses GitHub's short-lived GITHUB_TOKEN with contents: write
only when it records approved private GitHub Release provenance. Do not add a
personal access token for this purpose. The public APK is served from Firebase
Hosting, not from a GitHub asset URL.

## Rotation

If a signing credential is lost, exposed, or access changes, rotate it with
the appropriate issuer, replace the protected environment secret, and revoke
the old credential. Do not expose old or replacement values while diagnosing
the issue.

When rotating the Android upload key, update ANDROID_SIGNING_CERT_SHA256 in the
same protected environment change. The release workflow rejects a
validly-signed APK if its signer certificate does not exactly match this
approved fingerprint.

## Optional staging preview

Create a separate GitHub Environment named staging only if you want trusted
main-branch Firebase preview channels. Copy only the three Firebase OIDC
configuration entries above into that environment, set the repository variable
CASHLY_ENABLE_STAGING_PREVIEW to true, and do not add Android or store signing
credentials to staging. Staging previews must not promote direct APK downloads
to the live site.
