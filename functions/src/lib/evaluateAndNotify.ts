import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { isPresenceFresh } from './presence';
import { readNotificationState, writeNotificationState } from './notificationState';
import { sendPushToUser } from './sendPush';

export interface EvaluateAndNotifyParams {
  db: Firestore;
  userId: string;
  /** e.g. `budget:{budgetId}`, `account:{accountId}`, `goal:{goalId}`. */
  stateId: string;
  isActiveNow: boolean;
  /**
   * Receives the user's stored `language` (`'english'` | `'lao'`, the raw
   * `AppLanguage` enum name — see `lib/core/constants/app_language.dart`),
   * already resolved from the same user-doc read this helper needs anyway
   * for `notificationsEnabled`/`lastActiveAt`, so callers only need to
   * supply the alert-type-specific fields.
   */
  buildPushData: (lang: string) => Record<string, string>;
}

/**
 * The single shared dedup/transition helper every alert-type trigger calls.
 * Mirrors `budget_alert_providers.dart`'s `_AlertedIds` false->true/
 * true->false transition shape client-side, made durable across cold
 * starts via `notificationState`, and gated on both `notificationsEnabled`
 * and a presence heartbeat so a push is never sent when the client's own
 * local listener is already covering the same crossing. See the FCM plan's
 * "The dedup mechanism" section for the full design rationale, including
 * the deliberate accepted gaps.
 */
export async function evaluateAndNotify({
  db,
  userId,
  stateId,
  isActiveNow,
  buildPushData,
}: EvaluateAndNotifyParams): Promise<void> {
  const userSnapshot = await db.collection('users').doc(userId).get();
  const userData = userSnapshot.data();
  // Re-enabling notifications later doesn't retroactively notify about a
  // condition that became true while off — only a *new* crossing after
  // re-enabling pushes. No state mutation at all while disabled.
  if (userData?.notificationsEnabled !== true) return;

  const state = await readNotificationState(db, userId, stateId);

  if (!isActiveNow) {
    if (state.active) {
      await writeNotificationState(db, userId, stateId, { active: false, notifiedAt: null });
    }
    return;
  }

  if (state.active) return; // true -> true: already notified/suppressed for this streak.

  // false -> true: a new crossing.
  const lastActiveAt = userData?.lastActiveAt as Timestamp | undefined;
  if (isPresenceFresh(lastActiveAt)) {
    // Local notifications already cover this — record the crossing
    // (without sending) so a later reversion still clears state correctly.
    await writeNotificationState(db, userId, stateId, { active: true, notifiedAt: null });
    return;
  }

  const lang = (userData?.language as string | undefined) ?? 'english';
  await sendPushToUser(db, userId, buildPushData(lang));
  await writeNotificationState(db, userId, stateId, { active: true, notifiedAt: Timestamp.now() });
}
