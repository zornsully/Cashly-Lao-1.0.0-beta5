# Firestore rules-emulator tests

Real Firestore Security Rules Emulator tests for `../firestore.rules`. This
harness did not exist before this pass — every prior `firestore.rules`
change in this project's history was reviewed manually against precedent,
not verified by execution (see `CLAUDE.md`'s Phase 1 project-memory entry).

## Running

```powershell
cd firestore-tests
npm ci
npm test
```

`npm test` runs `firebase emulators:exec --only firestore "jest"`, which:

1. Downloads the Firestore Emulator JAR on first run (cached by the
   `firebase` CLI outside this repo — needs network access once).
2. Starts a local, ephemeral Firestore emulator instance.
3. Uploads `../firestore.rules`' real content to it via
   `@firebase/rules-unit-testing`.
4. Runs `rules.test.js` against it, then tears the emulator down.

No real Firebase project, credentials, or network access to production
Firebase is ever used — this is fully local and side-effect-free.

## Scope

Covers the highest-risk categories from the project's security audit:
unauthenticated denial, cross-user read/write denial, ownership
enforcement, pinned/immutable fields, amount validation, transfer-currency
validation, and default-deny (including the server-only `notificationState`
collection). **Not exhaustive of every field on every collection** — see
`TODO.md` for what's intentionally left for a follow-up pass.

## Adding to CI

Not yet wired into `.github/workflows/ci.yml` — the Firestore emulator
needs a JVM (`java`) on the runner, which `ci.yml` doesn't currently
provision. Add a `firestore-rules` job mirroring the existing Functions
job (`npm ci && npm test` in this directory) once that's set up, guarded
the same way `ci.yml` already guards the Functions job on `functions/**`
changes — guard this one on changes to `firestore.rules` or
`firestore-tests/**`.
