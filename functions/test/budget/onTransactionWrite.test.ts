import type { Timestamp as TimestampType } from 'firebase-admin/firestore';
import { FakeFirestore } from '../helpers/fakeFirestore';

let fakeDb: FakeFirestore;
jest.mock('firebase-admin/firestore', () => ({
  ...jest.requireActual('firebase-admin/firestore'),
  getFirestore: () => fakeDb,
}));

const sendEachForMulticast = jest.fn();
jest.mock('firebase-admin/messaging', () => ({
  getMessaging: () => ({ sendEachForMulticast }),
}));

import { Timestamp } from 'firebase-admin/firestore';
import { handleTransactionWrite } from '../../src/budget/onTransactionWrite';

const userId = 'user1';

function txnSnapshot(data: Record<string, unknown> | undefined) {
  return { data: () => data, exists: data !== undefined };
}

function julyDate(day: number): TimestampType {
  return Timestamp.fromDate(new Date(Date.UTC(2026, 6, day, 10))); // 10:00 UTC = safely inside the ICT day
}

describe('handleTransactionWrite', () => {
  beforeEach(() => {
    fakeDb = new FakeFirestore();
    sendEachForMulticast.mockReset();
    sendEachForMulticast.mockResolvedValue({ responses: [{ success: true }] });

    fakeDb.seed(`users/${userId}`, { notificationsEnabled: true, lastActiveAt: null });
    fakeDb.seed(`users/${userId}/categories/cat1`, { name: 'Groceries' });
    fakeDb.seed(`users/${userId}/accounts/acc1`, { currencyCode: 'LAK' });
    fakeDb.seed(`users/${userId}/fcmTokens/token1`, { token: 'token1' });
  });

  it('does nothing when neither before nor after is an expense', async () => {
    fakeDb.seed('users/user1/budgets/cat1_2026-07', {
      categoryId: 'cat1',
      limitAmount: 100,
      currencyCode: 'LAK',
    });

    await handleTransactionWrite({
      params: { userId, transactionId: 't1' },
      data: {
        before: txnSnapshot(undefined),
        after: txnSnapshot({
          type: 'transfer',
          categoryId: '',
          accountId: 'acc1',
          amount: 100000,
          date: julyDate(10),
        }),
      },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any);

    expect(fakeDb.read('users/user1/notificationState/budget:cat1_2026-07')).toBeUndefined();
    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('recomputes and pushes when a new expense transaction crosses the budget limit', async () => {
    fakeDb.seed('users/user1/budgets/cat1_2026-07', {
      categoryId: 'cat1',
      limitAmount: 100,
      currencyCode: 'LAK',
    });
    fakeDb.seed('users/user1/transactions/t1', {
      type: 'expense',
      categoryId: 'cat1',
      accountId: 'acc1',
      amount: 150,
      date: julyDate(10),
    });

    await handleTransactionWrite({
      params: { userId, transactionId: 't1' },
      data: {
        before: txnSnapshot(undefined),
        after: txnSnapshot({
          type: 'expense',
          categoryId: 'cat1',
          accountId: 'acc1',
          amount: 150,
          date: julyDate(10),
        }),
      },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any);

    expect(sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ type: 'budget_exceeded' }) }),
    );
    expect(fakeDb.read('users/user1/notificationState/budget:cat1_2026-07')).toMatchObject({
      active: true,
    });
  });

  it('evaluates both categories when an edit moves a transaction from one to another', async () => {
    // Category A drops below its limit once this transaction leaves it;
    // category B crosses over its limit once the transaction lands in it.
    fakeDb.seed('users/user1/categories/cat2', { name: 'Dining' });
    fakeDb.seed('users/user1/budgets/cat1_2026-07', {
      categoryId: 'cat1',
      limitAmount: 100,
      currencyCode: 'LAK',
    });
    fakeDb.seed('users/user1/budgets/cat2_2026-07', {
      categoryId: 'cat2',
      limitAmount: 100,
      currencyCode: 'LAK',
    });
    fakeDb.seed('users/user1/notificationState/budget:cat1_2026-07', {
      active: true,
      notifiedAt: null,
    });
    // The edited transaction now lives under cat2 with enough amount to overspend it;
    // cat1 has no other transactions left, so it should clear back to inactive.
    fakeDb.seed('users/user1/transactions/t1', {
      type: 'expense',
      categoryId: 'cat2',
      accountId: 'acc1',
      amount: 150,
      date: julyDate(10),
    });

    await handleTransactionWrite({
      params: { userId, transactionId: 't1' },
      data: {
        before: txnSnapshot({
          type: 'expense',
          categoryId: 'cat1',
          accountId: 'acc1',
          amount: 150,
          date: julyDate(10),
        }),
        after: txnSnapshot({
          type: 'expense',
          categoryId: 'cat2',
          accountId: 'acc1',
          amount: 150,
          date: julyDate(10),
        }),
      },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any);

    expect(fakeDb.read('users/user1/notificationState/budget:cat1_2026-07')).toMatchObject({
      active: false,
    });
    expect(fakeDb.read('users/user1/notificationState/budget:cat2_2026-07')).toMatchObject({
      active: true,
    });
  });
});
