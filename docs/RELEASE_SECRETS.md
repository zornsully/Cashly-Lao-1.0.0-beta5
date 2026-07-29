# Local release credentials

No release secret is stored in GitHub Actions, a GitHub Environment, this
repository, or a checked-in configuration file.

## Local-only material

- Android signing keystore, alias, and passwords stay in the operator's local
  secure keystore setup and `android/key.properties`, which is ignored.
- The expected Android signing certificate SHA-256 fingerprint is provided to
  the local preparation command and compared with `apksigner --print-certs`.
- GitHub authentication is the operator's local `gh auth login` session. Use a
  least-privilege account that can create releases only in the approved public
  distribution repository.
- Firebase authentication is the operator's local `firebase login` session and
  is used only after explicit approval to deploy `hosting:cashly-lao`.

Never paste a PAT, keystore, password, Firebase token, service-account JSON,
or certificate private key into source, release notes, workflow logs, issue
comments, or a public distribution repository. GitHub Actions remains
credential-free and read-only.
