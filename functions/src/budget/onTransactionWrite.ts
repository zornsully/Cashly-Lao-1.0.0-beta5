import {
  onDocumentWritten,
  type FirestoreEvent,
  type Change,
} from 'firebase-functions/v2/firestore';
import { getFirestore, type Timestamp, type DocumentSnapshot } from 'firebase-admin/firestore';
import { recomputeBudgetSpend } from './recomputeBudgetSpend';
import { evaluateAndNotify } from '../lib/evaluateAndNotify';
import { ictComponents } from '../lib/ictCalendar';

interface DirtyBudgetKey {
  categoryId: string;
  year: number;
  month: number;
}

function dirtyKeyFor(data: FirebaseFirestore.DocumentData | undefined): DirtyBudgetKey | null {
  if (!data || data.type !== 'expense') return null;
  const categoryId = data.categoryId as string | undefined;
  const date = (data.date as Timestamp | undefined)?.toDate();
  if (!categoryId || !date) return null;
  const { year, month } = ictComponents(date);
  return { categoryId, year, month };
}

function keyId(key: DirtyBudgetKey): string {
  return `${key.categoryId}_${key.year}-${key.month}`;
}

/**
 * A transaction write can push a budget's spend over (or back under) its
 * limit. Up to two distinct (categoryId, month) pairs can be dirty on a
 * single update — before and after a category or date edit — mirroring why
 * the client's own `budgetProgressForMonthProvider` recomputes whenever
 * transactions change (`budget_providers.dart`). No-ops entirely if
 * neither before nor after is an expense.
 *
 * Exported separately from the `onDocumentWritten` wrapper below so tests
 * can call it directly with a plain event object, without needing to fight
 * the Functions v2 SDK's opaque `CloudFunction` return type.
 */
export async function handleTransactionWrite(
  event: FirestoreEvent<
    Change<DocumentSnapshot> | undefined,
    { userId: string; transactionId: string }
  >,
): Promise<void> {
  const { userId } = event.params;
  const keys = new Map<string, DirtyBudgetKey>();
  for (const key of [dirtyKeyFor(event.data?.before.data()), dirtyKeyFor(event.data?.after.data())]) {
    if (key) keys.set(keyId(key), key);
  }
  if (keys.size === 0) return;

  const db = getFirestore();
  for (const { categoryId, year, month } of keys.values()) {
    const result = await recomputeBudgetSpend({ db, userId, categoryId, year, month });
    if (!result) continue;
    await evaluateAndNotify({
      db,
      userId,
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
}

export const onTransactionWrite = onDocumentWritten(
  'users/{userId}/transactions/{transactionId}',
  handleTransactionWrite,
);
