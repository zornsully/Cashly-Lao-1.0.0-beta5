import type { Firestore, Timestamp } from 'firebase-admin/firestore';

export interface NotificationState {
  active: boolean;
  notifiedAt: Timestamp | null;
}

const DEFAULT_STATE: NotificationState = { active: false, notifiedAt: null };

function stateDocRef(db: Firestore, userId: string, stateId: string) {
  return db.collection('users').doc(userId).collection('notificationState').doc(stateId);
}

/**
 * The durable, cross-invocation counterpart of
 * `budget_alert_providers.dart`'s in-memory `_AlertedIds`: whether a given
 * budget/account/goal crossing has already been alerted, surviving Cloud
 * Function cold starts (unlike the client's session-scoped Set). Rules-
 * denied to the client entirely — see `firestore.rules`'
 * `notificationState` block — so this collection only ever exists via
 * these two functions.
 */
export async function readNotificationState(
  db: Firestore,
  userId: string,
  stateId: string,
): Promise<NotificationState> {
  const snapshot = await stateDocRef(db, userId, stateId).get();
  if (!snapshot.exists) return DEFAULT_STATE;
  const data = snapshot.data() as Partial<NotificationState> | undefined;
  return {
    active: data?.active ?? false,
    notifiedAt: data?.notifiedAt ?? null,
  };
}

export async function writeNotificationState(
  db: Firestore,
  userId: string,
  stateId: string,
  state: NotificationState,
): Promise<void> {
  await stateDocRef(db, userId, stateId).set(state);
}
