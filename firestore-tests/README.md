# Firestore rules-emulator tests

Real Firestore Security Rules Emulator tests for `../firestore.rules`. This
harness did not exist before this pass — every prior `firestore.rules`
change in this project's history was reviewed manually against precedent,
not verified by execution (see `CLAUDE.md`'s Phase 1 project-memory entry).

## Running

```powershell
cd firestore-tests
npm ci
# Firebase CLI 15 requires Java 21 or later. Ensure `java -version` reports 21+.
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

## CI

The `firestore-rules` job in `.github/workflows/ci.yml` runs this suite on
every push and pull request with Node 20 and the Ubuntu runner's Java 21.
`firebase-tools` is pinned in this package's development dependencies, so the
test never relies on a globally installed Firebase CLI.
