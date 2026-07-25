import {
  onDocumentWritten,
  type FirestoreEvent,
  type Change,
} from 'firebase-functions/v2/firestore';
import { getFirestore, type Timestamp, type DocumentSnapshot } from 'firebase-admin/firestore';
import { recomputeBudgetSpend } from './recomputeBudgetSpend';
import { evaluateAndNotify } from '../lib/evaluateAndNotify';
import { ictComponents } from '../lib/ictCalendar';

/**
 * Editing a budget's own `limitAmount` can cross the overspent line with
 * zero new transactions — this is why budget overspend needs two trigger
 * entry points (see also `onTransactionWrite.ts`), not one.
 *
 * Exported separately from the `onDocumentWritten` wrapper (see that file's
 * doc comment for why).
 */
export async function handleBudgetWrite(
  event: FirestoreEvent<Change<DocumentSnapshot> | undefined, { userId: string; budgetId: string }>,
): Promise<void> {
  const after = event.data?.after;
  if (!after?.exists) return; // deleted budget can't be "overspent" — no-op, not a clear.
  const data = after.data();
  const categoryId = data?.categoryId as string | undefined;
  const month = (data?.month as Timestamp | undefined)?.toDate();
  if (!categoryId || !month) return;

  const db = getFirestore();
  const { year, month: monthIndex } = ictComponents(month);
  const result = await recomputeBudgetSpend({
    db,
    userId: event.params.userId,
    categoryId,
    year,
    month: monthIndex,
  });
  if (!result) return;

  await evaluateAndNotify({
    db,
    userId: event.params.userId,
    stateId: `budget:${result.budgetId}`,
    isActiveNow: result.isOverspent,
    buildPushData: (lang) => ({
      type: 'budget_exceeded',
      id: result.budgetId,
      categoryName: result.categoryName,
      lang,
    }),
  });
}

export const onBudgetWrite = onDocumentWritten('users/{userId}/budgets/{budgetId}', handleBudgetWrite);
