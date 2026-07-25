import type { Firestore } from 'firebase-admin/firestore';
import { Timestamp } from 'firebase-admin/firestore';
import { FakeFirestore } from '../helpers/fakeFirestore';
import { recomputeBudgetSpend } from '../../src/budget/recomputeBudgetSpend';

describe('recomputeBudgetSpend', () => {
  let fakeDb: FakeFirestore;
  let db: Firestore;
  const userId = 'user1';

  beforeEach(() => {
    fakeDb = new FakeFirestore();
    db = fakeDb as unknown as Firestore;
    fakeDb.seed(`users/${userId}/categories/cat1`, { name: 'Groceries' });
    fakeDb.seed(`users/${userId}/accounts/acc-lak`, { currencyCode: 'LAK' });
    fakeDb.seed(`users/${userId}/accounts/acc-usd`, { currencyCode: 'USD' });
  });

  function seedBudget(limitAmount: number, currencyCode = 'LAK') {
    fakeDb.seed(`users/${userId}/budgets/cat1_2026-07`, {
      categoryId: 'cat1',
      limitAmount,
      currencyCode,
    });
  }

  function seedTransaction(
    id: string,
    { type = 'expense', accountId = 'acc-lak', amount = 0, day = 15 } = {},
  ) {
    fakeDb.seed(`users/${userId}/transactions/${id}`, {
      type,
      categoryId: 'cat1',
      accountId,
      amount,
      date: Timestamp.fromDate(new Date(Date.UTC(2026, 6, day, 10))), // well inside July, ICT-safe
    });
  }

  it('returns null when no budget exists for the category/month', async () => {
    const result = await recomputeBudgetSpend({ db, userId, categoryId: 'cat1', year: 2026, month: 6 });
    expect(result).toBeNull();
  });

  it('is not overspent when there are no transactions at all', async () => {
    seedBudget(100000);
    const result = await recomputeBudgetSpend({ db, userId, categoryId: 'cat1', year: 2026, month: 6 });
    expect(result).toEqual({ budgetId: 'cat1_2026-07', categoryName: 'Groceries', isOverspent: false });
  });

  it('sums same-currency expense transactions and flags overspend past the limit', async () => {
    seedBudget(100000, 'LAK');
    seedTransaction('t1', { amount: 60000 });
    seedTransaction('t2', { amount: 50000 });

    const result = await recomputeBudgetSpend({ db, userId, categoryId: 'cat1', year: 2026, month: 6 });
    expect(result?.isOverspent).toBe(true); // 110,000 > 100,000
  });

  it('is not overspent when the same total sits exactly at the limit', async () => {
    seedBudget(100000, 'LAK');
    seedTransaction('t1', { amount: 100000 });

    const result = await recomputeBudgetSpend({ db, userId, categoryId: 'cat1', year: 2026, month: 6 });
    expect(result?.isOverspent).toBe(false); // strictly greater-than, not >=
  });

  it('excludes transactions on an account whose currency does not match the budget', async () => {
    seedBudget(10, 'LAK'); // tiny limit — would overspend instantly if the USD txn counted
    seedTransaction('t1', { accountId: 'acc-usd', amount: 1000 });

    const result = await recomputeBudgetSpend({ db, userId, categoryId: 'cat1', year: 2026, month: 6 });
    expect(result?.isOverspent).toBe(false);
  });

  it('excludes transactions whose account no longer exists', async () => {
    seedBudget(10, 'LAK');
    seedTransaction('t1', { accountId: 'acc-deleted', amount: 1000 });

    const result = await recomputeBudgetSpend({ db, userId, categoryId: 'cat1', year: 2026, month: 6 });
    expect(result?.isOverspent).toBe(false);
  });

  it('excludes non-expense transactions (income, transfer) even in the same category', async () => {
    seedBudget(10, 'LAK');
    seedTransaction('t1', { type: 'income', amount: 1000 });

    const result = await recomputeBudgetSpend({ db, userId, categoryId: 'cat1', year: 2026, month: 6 });
    expect(result?.isOverspent).toBe(false);
  });

  it('excludes transactions outside the target month', async () => {
    seedBudget(10, 'LAK');
    seedTransaction('t-june', { day: 30 }); // still resolves inside June in this fixture window
    fakeDb.write(`users/${userId}/transactions/t-june`, {
      type: 'expense',
      categoryId: 'cat1',
      accountId: 'acc-lak',
      amount: 1000,
      date: Timestamp.fromDate(new Date(Date.UTC(2026, 5, 30, 10))), // June, not July
    });

    const result = await recomputeBudgetSpend({ db, userId, categoryId: 'cat1', year: 2026, month: 6 });
    expect(result?.isOverspent).toBe(false);
  });
});
