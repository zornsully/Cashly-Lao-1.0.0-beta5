import {
  onDocumentDeleted,
  type FirestoreEvent,
  type QueryDocumentSnapshot,
} from 'firebase-functions/v2/firestore';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';

/**
 * `deleteAccount` (`auth_remote_datasource.dart`) deletes the user doc
 * first, as its own commit, specifically so a mid-failure retry is safe —
 * meaning there's a real window where the user doc is gone but
 * subcollections aren't yet. `notificationState` is rules-denied to the
 * client entirely, so only server code can ever clean it up; this
 * best-effort deletes it, plus any stray `fcmTokens` docs as a backstop
 * (the client's own chunked-delete loop is the primary cleanup path for
 * tokens — see that file — this only catches what it might miss).
 *
 * Takes `db`/`userId` as parameters so tests can supply a fake Firestore
 * directly — see `budget/onTransactionWrite.ts`'s doc comment for why.
 */
export async function cleanupDeletedUser(db: Firestore, userId: string): Promise<void> {
  const userRef = db.collection('users').doc(userId);

  for (const collectionName of ['notificationState', 'fcmTokens']) {
    const snapshot = await userRef.collection(collectionName).get();
    if (snapshot.empty) continue;
    const batch = db.batch();
    for (const doc of snapshot.docs) batch.delete(doc.ref);
    await batch.commit();
  }
}

export const onUserDeleted = onDocumentDeleted(
  'users/{userId}',
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, { userId: string }>) => {
    await cleanupDeletedUser(getFirestore(), event.params.userId);
  },
);
