# Production rollback

## Principles

- Keep previous Firebase Hosting versions and private GitHub release evidence.
- Never overwrite a versioned APK or delete a Hosting version automatically.
- Require the protected production approval for every rollback.
- Restore the page, release manifest, and matching direct APK as one Hosting
  version.
- Verify the restored live site before announcing the rollback.

## Website and download rollback

1. Identify the recorded last known-good Firebase Hosting version ID, its
   release tag, and the approved Android SHA-256. Do not select a version based
   only on its date.
2. Start rollback-production.yml manually and supply the matching immutable
   release tag, for example v1.0.2.
3. Review the known-good Hosting version and approve the production environment
   request.
4. The protected workflow must clone that exact version to cashly-lao:live:

       firebase hosting:clone cashly-lao:@<known-good-version-id> cashly-lao:live --project cashly-lao --non-interactive

5. It downloads the restored APK in full from
   https://cashly-lao.web.app/downloads/Cashly-Lao-Android-<version>.apk,
   verifies its signature, size, and SHA-256, then validates the matching
   schema-v2 manifest and page shell.
6. Confirm the website and download metadata point to the intended release
   before announcing the rollback.

The rollback keeps later private release evidence and Hosting history for audit
and investigation. It does not make the repository public and it does not
reuse an APK filename for a corrected build.

## Partial publication failure

If preview validation fails, do not clone it to live. If live validation fails
after a clone, stop publication, record the failed Hosting version, and use the
protected rollback workflow or fix forward with a new immutable version. The
previous production version stays recoverable until all advertised Firebase
download links are verified.
