import {
  onDocumentWritten,
  type FirestoreEvent,
  type Change,
} from 'firebase-functions/v2/firestore';
import { getFirestore, type DocumentSnapshot } from 'firebase-admin/firestore';
import { evaluateAndNotify } from '../lib/evaluateAndNotify';

/**
 * Unlike budget spend, `AccountEntity.balance` is a trustworthy
 * denormalized field — maintained transactionally by the client's own
 * `transaction_remote_datasource.dart` `runTransaction` writes — so this
 * trigger needs no recompute, just a direct read. A deliberate contrast
 * with the budget triggers (see `budget/recomputeBudgetSpend.ts`), not an
 * inconsistency: one alert type recomputes because its number is never
 * stored, the other doesn't because its number always is.
 *
 * Exported separately from the `onDocumentWritten` wrapper (see
 * `budget/onTransactionWrite.ts`'s doc comment for why).
 */
export async function handleAccountWrite(
  event: FirestoreEvent<Change<DocumentSnapshot> | undefined, { userId: string; accountId: string }>,
): Promise<void> {
  const after = event.data?.after;
  const data = after?.exists ? after.data() : undefined;
  const balance = (data?.balance as number | undefined) ?? 0;
  const accountName = (data?.name as string | undefined) ?? '';

  const db = getFirestore();
  await evaluateAndNotify({
    db,
    userId: event.params.userId,
    stateId: `account:${event.params.accountId}`,
    // A deleted account (after missing/not existing) can't be negative —
    // this correctly clears any existing notificationState for it.
    isActiveNow: after?.exists === true && balance < 0,
    buildPushData: (lang) => ({
      type: 'negative_balance',
      id: event.params.accountId,
      accountName,
      lang,
    }),
  });
}

export const onAccountWrite = onDocumentWritten(
  'users/{userId}/accounts/{accountId}',
  handleAccountWrite,
);
