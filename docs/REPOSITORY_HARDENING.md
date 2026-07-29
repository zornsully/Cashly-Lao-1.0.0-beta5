# Repository release hardening

These are account-level GitHub controls. They are intentionally documented,
not automated from this repository: a workflow must not be able to weaken the
rules that protect it.

## Default GitHub Actions permissions

In Settings -> Actions -> General, set the default workflow permission to
Read repository contents. Do not allow Actions to create or approve pull
requests. The release workflow elevates to contents: write only inside its
second protected production job.

## Protect the default branch

Create a ruleset or branch rule for main that requires pull requests, passing
CI and web-preview checks, and code-owner review. Disallow force pushes and
direct workflow edits. Enable Require review from Code Owners so
.github/CODEOWNERS protects workflow, release-tool, and release-document
changes.

## Make release tags immutable

Create a tag ruleset for v* that permits creation only by release managers
and prevents update or deletion after creation. The workflows resolve the
remote tag to an immutable commit before protected signing and publication;
the ruleset prevents a tag from moving in the interval between those checks.

## Restrict release and Hosting mutation

GitHub release records and Firebase Hosting versions are not protected by the
tag ruleset alone. Limit the ability to create, edit, delete, or replace
release evidence to the same small set of release managers who can approve
production. Never overwrite a versioned Hosting APK path. If a public artifact
is wrong, keep the evidence available for audit and fix forward with a new
immutable version tag and APK filename. The protected workflow must
checksum-verify the Firebase preview APK, then clone that exact Hosting version
to live; it must not make source-code visibility a condition of download.

## Protect production

Follow [the production environment guide](PRODUCTION_ENVIRONMENT.md): create
the exact production Environment, add required reviewers, scope secrets to
that Environment only, and restrict deployment refs to the approved release
tag policy. A manual release.yml dispatch should be started from the exact
release tag in GitHub's ref selector, not an unrelated branch.

## Periodic review

At least quarterly, review release managers, required reviewers, OIDC workload
identity bindings, GitHub Actions permissions, tag rules, Firebase Hosting
version retention, and the current version of all pinned workflow actions.
Remove access that is no longer needed.
