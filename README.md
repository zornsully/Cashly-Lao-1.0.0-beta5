# Cashly Lao

Cashly Lao is a personal finance app built for Laos. Its public landing page
can be visited without sign-in and reads release information from a verified
JSON manifest.

## Free-tier development releases

This project deliberately uses Firebase Spark and GitHub Free during
development. Firebase Hosting serves only the Flutter website and its small
release manifest; it never hosts APKs or other installers. The source
repository stays private.

When an Android build is ready, a separate public GitHub distribution
repository will contain only the approved APK, `SHA256SUMS.txt`, release
evidence, and reviewed release notes. No distribution repository is approved
yet: `assets/release/distribution_policy.json` is intentionally unconfigured,
and the website therefore keeps its Android button in a safe “Coming soon”
state.

No GitHub Action publishes or deploys. A signed APK is built and checked
locally, then the release owner explicitly approves public GitHub publication.
Only after an anonymous public download matches its expected size and SHA-256
may the website manifest be updated. Firebase Spark deployment requires a
separate explicit owner approval.

The tools and safety checks are documented here:

- [Manual release pipeline](docs/RELEASE_PIPELINE.md)
- [Firebase Spark and GitHub delivery](docs/FIREBASE_HOSTING_APK_DELIVERY.md)
- [Local credential handling](docs/RELEASE_SECRETS.md)
- [Manual approval checklist](docs/PRODUCTION_ENVIRONMENT.md)
- [Repository hardening](docs/REPOSITORY_HARDENING.md)
- [Website metadata rollback](docs/ROLLBACK.md)

## Release metadata trust boundary

The bundled fallback at `assets/release/release_manifest.json` remains
informational and never enables a download. A current manifest is accepted
only when it names the exact repository approved in the bundled distribution
policy and uses the canonical GitHub release page and asset URL for the exact
tag, version, and filename. Query strings, fragments, ports, user info,
encoded paths, source-repository assets, and arbitrary GitHub repositories are
rejected.

The local tools are intentionally separate:

1. `tool/prepare_manual_release.ps1` builds the signed APK (published) and
   AAB (local Play-Store-readiness evidence only) and produces immutable
   local evidence.
2. `tool/publish_github_release.ps1` requires `-ApprovePublicRelease` and
   publishes only after local validation.
3. `tool/publish_web_metadata.ps1` requires
   `-ApproveWebsiteMetadata` and verifies the public asset again before any
   website metadata change. Firebase deployment additionally requires
   `-DeployToSpark -ApproveSparkDeployment`.
4. `tool/rollback_web_metadata.ps1` restores a website link to a preserved,
   verified public release without changing GitHub assets.
