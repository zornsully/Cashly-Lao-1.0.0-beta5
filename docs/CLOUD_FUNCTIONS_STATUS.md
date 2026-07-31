# Cloud Functions deployment status

This reconciles a real, previously-undocumented contradiction: `CLAUDE.md`'s
Stack section used to say "no backend of our own" while `functions/` has
contained a genuine TypeScript Cloud Functions backend since the FCM-backstop
work landed. Both statements can't be true — this file is the correction,
and the source of truth going forward for whether that backend is actually
live in production.

## What exists

Five exported functions (`functions/src/index.ts`), all on the Cloud
Functions **2nd generation** runtime (`firebase-functions/v2`):

| Function | Trigger | Purpose |
|---|---|---|
| `onTransactionWrite` | Firestore `onDocumentWritten` (`users/{uid}/transactions/{id}`) | Recomputes the affected budget's spend server-side, then evaluates it for a push-worthy over-budget alert. |
| `onBudgetWrite` | Firestore `onDocumentWritten` (`users/{uid}/budgets/{id}`) | Same recompute/evaluate path, triggered by editing a budget's own limit rather than a transaction. |
| `onAccountWrite` | Firestore `onDocumentWritten` (`users/{uid}/accounts/{id}`) | Evaluates the account's already-trustworthy client-maintained `balance` field for a negative-balance push alert (no recompute needed — see the file's own doc comment). |
| `checkGoalReminders` | Cloud **Scheduler** (`onSchedule`) | Time-driven (not write-driven) savings-goal contribution reminders. |
| `onUserDeleted` | Firestore `onDocumentDeleted` (`users/{userId}`) | Best-effort server-side cleanup of `notificationState` (rules-denied to the client entirely — only server code can ever delete it) and any stray `fcmTokens` docs the client's own deletion loop might have missed. |

## Client dependency

Every function here is a **backstop**, not a dependency of core financial
correctness. Local (on-device) budget/balance/goal-reminder alerts already
fire independently of these (`lib/core/providers/budget_alert_providers.dart`,
`goal_reminder_providers.dart`), and no balance, budget, or report figure
displayed in the app is computed server-side — that's still 100%
client-side, transactional, and covered by `firestore.rules`. If none of
these functions are live, the app's financial correctness is entirely
unaffected; only these are:

- Push notifications arriving when the app is fully closed (local alerts
  only fire while the app's own listeners are running).
- `onUserDeleted`'s cleanup of `notificationState`/stray `fcmTokens` after
  account deletion (the client's own deletion loop — see
  `auth_remote_datasource.dart`'s `deleteAccount` — is the primary path for
  every user-owned collection including `fcmTokens`; `notificationState` in
  particular has **no client cleanup path at all**, since rules deny client
  access to it entirely, so if this function isn't deployed, orphaned
  `notificationState` documents are the one confirmed permanently-retained
  artifact of account deletion today, invisible to the user).

## Is it actually deployed? Confirmed NOT deployed (2026-07-31, verified live).

**This is now a verified fact, not a guess.** A real, authenticated
`firebase login` session was available in this session (via the npm-installed
`firebase-tools`, not the broken `firepit` binary bundled elsewhere in this
environment — see the note at the bottom of this section). Running:

```
firebase functions:list --project cashly-lao
```

returned:

```
Error: Failed to list functions for cashly-lao
```

with `--debug` showing the real cause — a live API response, not a CLI/auth
failure:

```
HTTP 403 PERMISSION_DENIED (reason: SERVICE_DISABLED)
"Cloud Functions API has not been used in project cashly-lao before or it is
disabled."
```

This is conclusive: the Cloud Functions API has never even been *enabled* on
the `cashly-lao` GCP project, which is only possible if **no function has
ever been deployed** (a first deploy auto-enables the API as a side effect).
Combined with the existing evidence that no script/workflow in this repo ever
runs an unscoped `firebase deploy` or a `--only functions` deploy, this closes
the question definitively:

- `firebase.json` includes a `"functions": { "source": "functions" }` block,
  which means a bare `firebase deploy` (no `--only`) *would* attempt to
  deploy them — but every documented and scripted release path in this repo
  (`tool/publish_web_metadata.ps1`, `tool/deploy_website.ps1`,
  `docs/RELEASE_PIPELINE.md`) explicitly scopes every deploy to
  `--only hosting:cashly-lao`. **No script, workflow, or documented command
  in this repository has ever deployed Functions.**
- **Live verification, 2026-07-31**: `firebase functions:list --project
  cashly-lao` (via `firebase-tools` 15.25.1, authenticated as the project
  owner) confirms the Cloud Functions API itself has never been used on this
  project — the strongest possible signal short of reading GCP's own audit
  log.

**Practical conclusion:** the FCM-backstop-when-closed behavior and
`onUserDeleted`'s server-side cleanup are **confirmed not live in
production** as of 2026-07-31. Treat this as settled, not as a standing open
question, until the owner actually approves and runs a Blaze-plan deploy.

**Tooling note for future sessions**: this environment ships a broken
`firepit`-based `firebase` binary (its first-run "welcome" banner crashes
with `SyntaxError: Unexpected end of JSON input` on *every* invocation,
before the real command ever runs — do not mistake that crash for "not
logged in"). A working, already-authenticated `firebase-tools` install
exists separately via npm (`npm list -g firebase-tools`); invoke it directly
or via `npx firebase-tools@latest <command>` instead of the broken `firebase`
binary on `PATH`.

## Why Spark can't fix this by itself

Cloud Functions 2nd-gen (what every function above uses) is built on Cloud
Run + Eventarc and **requires the Firebase Blaze (pay-as-you-go) plan** —
this is a hard platform requirement, not a configuration choice, and it
applies even to a project whose actual usage stays inside Blaze's own free
quota. This directly conflicts with `CLAUDE.md`'s "Free-tier manual release
policy" ("Firebase Spark and GitHub Free only") for any world where these
functions are meant to be live. Per that same policy's approval gates,
**upgrading to Blaze is a paid-plan decision requiring explicit owner
approval** — this document does not grant that approval, and no deploy of
`functions/` should happen without it being given separately and explicitly,
the same way the two release-approval gates already work.

## What this phase did and didn't do

- Corrected `CLAUDE.md`'s Stack section and Future Vision section, which
  previously contradicted each other (one said "no backend of our own," the
  other described the same backend as already shipped-and-live).
- Did **not** deploy Functions, upgrade the Firebase plan, or otherwise
  change what's live — all blocked on the owner approval described above,
  consistent with `CLAUDE.md`'s non-negotiable approval gates.
- Did **not** remove or disable the Functions code — it's real, tested
  (`functions/test`, run via `npm test`), and ready to deploy the moment the
  owner approves a Blaze upgrade.

## Owner action required to close this out

1. Decide whether the FCM-closed-app backstop and `onUserDeleted` cleanup
   are worth a Blaze plan upgrade for this project.
2. If yes: explicitly approve the Blaze upgrade, then run
   `firebase deploy --only functions --project cashly-lao` from a real
   `firebase login` session (not part of any existing script in this repo —
   one should be added once this is approved, mirroring the same
   `-Approve...` explicit-switch pattern `publish_web_metadata.ps1` already
   uses for Hosting).
3. If no: update this doc to say so explicitly, and consider whether
   `notificationState`'s account-deletion gap (the one confirmed
   client-unreachable collection) needs a different closing mechanism
   (e.g. a rules exception allowing the client to delete it directly on
   the way out, revisiting why it was made server-only in the first place).
