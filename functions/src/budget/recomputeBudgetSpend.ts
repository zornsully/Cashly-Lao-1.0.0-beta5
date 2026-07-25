import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { ictMidnightInstant } from '../lib/ictCalendar';

export interface RecomputeBudgetSpendParams {
  db: Firestore;
  userId: string;
  categoryId: string;
  /** ICT calendar year and 0-indexed month this budget applies to. */
  year: number;
  month: number;
}

export interface BudgetSpendResult {
  budgetId: string;
  categoryName: string;
  isOverspent: boolean;
}

function budgetDocId(categoryId: string, year: number, month: number): string {
  return `${categoryId}_${year}-${String(month + 1).padStart(2, '0')}`;
}

/**
 * Re-derives, in TypeScript, exactly the currency-matching sum
 * `BuildBudgetProgressUseCase` computes client-side
 * (`lib/features/budget/domain/usecases/build_budget_progress_usecase.dart`):
 * only expense transactions whose account currency matches the budget's own
 * `currencyCode` count against it. Recomputed from raw transactions rather
 * than trusting a denormalized field, because `BudgetProgress.spentAmount`
 * is never stored client-side either (see that entity's own doc comment) —
 * inventing a denormalized total here would be a second source of truth
 * that could drift from what the app shows.
 *
 * Returns `null` when no budget exists for this category/month — the
 * caller should treat that as "nothing to evaluate," not an error.
 */
export async function recomputeBudgetSpend({
  db,
  userId,
  categoryId,
  year,
  month,
}: RecomputeBudgetSpendParams): Promise<BudgetSpendResult | null> {
  const userRef = db.collection('users').doc(userId);
  const budgetId = budgetDocId(categoryId, year, month);

  const budgetSnapshot = await userRef.collection('budgets').doc(budgetId).get();
  if (!budgetSnapshot.exists) return null;
  const budget = budgetSnapshot.data()!;

  const categorySnapshot = await userRef.collection('categories').doc(categoryId).get();
  const categoryName = (categorySnapshot.data()?.name as string | undefined) ?? '';

  const monthStart = ictMidnightInstant(year, month);
  const monthEnd = ictMidnightInstant(year, month + 1);
  const transactionsSnapshot = await userRef
    .collection('transactions')
    .where('type', '==', 'expense')
    .where('categoryId', '==', categoryId)
    .where('date', '>=', Timestamp.fromDate(monthStart))
    .where('date', '<', Timestamp.fromDate(monthEnd))
    .get();

  let spent = 0;
  if (!transactionsSnapshot.empty) {
    const accountIds = [
      ...new Set(transactionsSnapshot.docs.map((doc) => doc.data().accountId as string)),
    ];
    const accountDocs = await Promise.all(
      accountIds.map((id) => userRef.collection('accounts').doc(id).get()),
    );
    const currencyByAccountId = new Map<string, string>();
    for (const doc of accountDocs) {
      if (doc.exists) currencyByAccountId.set(doc.id, doc.data()!.currencyCode as string);
    }

    for (const doc of transactionsSnapshot.docs) {
      const data = doc.data();
      // Missing account (deleted) or a different currency than the
      // budget's own — neither counts, same as build_budget_progress_
      // usecase.dart's accountsById null-check and currency keying.
      if (currencyByAccountId.get(data.accountId as string) !== budget.currencyCode) continue;
      spent += data.amount as number;
    }
  }

  return {
    budgetId,
    categoryName,
    isOverspent: spent > (budget.limitAmount as number),
  };
}
