import type { Firestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

const DEAD_TOKEN_ERROR_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/**
 * Sends a data-only push (no `notification` block) to every device
 * registered for a user, then prunes any token the send reports as dead.
 * Data-only so both foreground and background delivery funnel through the
 * Flutter app's own content-building + local-notification display path
 * (`fcm_notification_content.dart` / `fcm_background_handler.dart`)
 * instead of a second, hard-to-keep-in-sync server-rendered notification —
 * see the FCM plan's dedup-mechanism section for the full rationale.
 *
 * An orphaned token is never proactively deleted client-side (e.g. on
 * `onTokenRefresh`) — this pruning, triggered by the token's own first
 * failed send, is the only cleanup path for a stale token.
 */
export async function sendPushToUser(
  db: Firestore,
  userId: string,
  data: Record<string, string>,
): Promise<void> {
  const tokensCollection = db.collection('users').doc(userId).collection('fcmTokens');
  const tokensSnapshot = await tokensCollection.get();
  if (tokensSnapshot.empty) return;

  const tokens = tokensSnapshot.docs.map((doc) => doc.id);
  const response = await getMessaging().sendEachForMulticast({ tokens, data });

  const deadTokens = response.responses
    .map((result, index) => ({ result, token: tokens[index] }))
    .filter(
      ({ result }) => !result.success && DEAD_TOKEN_ERROR_CODES.has(result.error?.code ?? ''),
    )
    .map(({ token }) => token);
  if (deadTokens.length === 0) return;

  const batch = db.batch();
  for (const token of deadTokens) {
    batch.delete(tokensCollection.doc(token));
  }
  await batch.commit();
}
