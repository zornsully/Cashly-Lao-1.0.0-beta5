# Firebase Spark website metadata delivery

Firebase Hosting is used on the Spark plan for static website files and
`release-manifest.json` only. It must not host `.apk`, `.ipa`, `.exe`, `.msi`,
or other installer files. The Firebase configuration has no installer header
rules, and the local metadata tool rejects a web bundle containing one.

The APK is delivered from an owner-approved **public GitHub distribution
repository**. The private source repository is never a public download source.
This separation is required because Firebase Spark does not allow direct APK
hosting.

## Required order

1. Build and validate the signed APK locally.
2. Publish a GitHub Release only after explicit owner approval.
3. Re-download the public APK anonymously and compare its byte size and
   SHA-256 to the locally validated evidence.
4. Only then generate the website manifest and build the static site.
5. Obtain separate explicit approval before a Spark deploy.
6. Run only:

   ```powershell
   firebase deploy --only hosting:cashly-lao --project cashly-lao
   ```

7. Fetch the live manifest and run the same strict schema, repository, tag,
   filename, and checksum-policy validation.

The metadata script can run the deploy only when both `-DeployToSpark` and
`-ApproveSparkDeployment` are supplied. It never deploys Firestore rules or
Cloud Functions as part of a website release.

If public GitHub verification, local web build, or live-manifest validation
fails, do not update the public link again. Keep the current Hosting state and
use the documented manual metadata rollback if necessary.
