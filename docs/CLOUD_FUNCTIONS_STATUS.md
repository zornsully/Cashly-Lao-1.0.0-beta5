# Cloud Functions deployment status

This reconciles a real, previously-undocumented contradiction: `CLAUDE.md`'s
Stack section used to say "no backend of our own" while `functions/` has
contained a genuine TypeScript Cloud Functions backend since the FCM-backstop
work landed. Both statements can't be true — this file is the correction,
and the source of truth going forward for whether that backend is actually
live in production.

## Decision (2026-08-01): staying on Spark, not deploying

The owner decided to skip the Blaze upgrade for now — the FCM-closed-app
backstop and `onUserDeleted`'s server-side cleanup are not worth taking on a
paid plan at this stage. `functions/` stays in the repo, built and tested,
in case this is revisited later, but it is **not deployed and not going to
be** under the current policy. Nothing below the "Owner action required"
section reflects an open question anymore — see that section's note for
where this landed.

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

## Is it actually deployed? Unverified from this environment.

**This cannot be confirmed from the repository or this session.** Evidence,
not a guess:

- `firebase.json` includes a `"functions": { "source": "functions" }` block,
  which means a bare `firebase deploy` (no `--only`) *would* attempt to
  deploy them — but every documented and scripted release path in this repo
  (`tool/publish_web_metadata.ps1`, `tool/deploy_website.ps1`,
  `docs/RELEASE_PIPELINE.md`) explicitly scopes every deploy to
  `--only hosting:cashly-lao`. **No script, workflow, or documented command
  in this repository has ever deployed Functions.**
- This session has no authenticated `firebase login` session and no Firebase
  Console access, so live deployment state can't be checked directly.
- **The exact command an owner with a real `firebase login` session can run
  to check:** `firebase functions:list --project cashly-lao` (lists deployed
  functions, or errors/returns empty if none are deployed), or Firebase
  Console → your project → Functions.

**Practical conclusion:** absent independent evidence the owner deployed
these outside of this repo's own tooling, they are almost certainly **not
live**. Until confirmed otherwise, treat the FCM-backstop-when-closed
behavior and `onUserDeleted`'s server-side cleanup as **not currently
happening in production**, regardless of what any UI copy or prior
documentation implied.

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

## Owner action required to close this out — resolved (2026-08-01): no

The owner decided **no** — the Blaze upgrade isn't worth it for this
project right now. Consequences of that decision, worked through rather
than left implicit:

- Functions stay in the repo (`functions/`, still built and tested via
  `npm test`) but are not deployed, and no script in this repo should
  deploy them without a future, separate explicit approval reopening this
  question.
- The FCM-closed-app push backstop and `onUserDeleted`'s server-side
  cleanup are **not live** and should be treated as permanently inactive
  under the current policy, not "unverified."
- **The `notificationState` account-deletion gap this doc previously
  flagged turns out to be moot, not open.** That collection is written
  *only* by the Cloud Functions listed above (`onTransactionWrite`/
  `onBudgetWrite`/`onAccountWrite`, via the Admin SDK — `firestore.rules`
  denies the client read/write entirely). If those functions never run in
  production, no `notificationState` document is ever created in the
  first place, so there is nothing for `onUserDeleted` to have needed to
  clean up. No rules change or alternate cleanup mechanism is needed. This
  would need revisiting only if a future decision reopens Blaze/Functions
  deployment — at that point, re-examine whether `onUserDeleted`'s cleanup
  path is sufficient before treating this as closed again.
- Revisit this whole decision only via an explicit, separate owner
  approval — the same standard every other paid-plan/signing/publishing
  decision in this project already follows.
