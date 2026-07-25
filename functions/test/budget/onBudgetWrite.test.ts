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
import { handleBudgetWrite } from '../../src/budget/onBudgetWrite';

const userId = 'user1';
const budgetId = 'cat1_2026-07';

// Mirrors budget_remote_datasource.dart's month field: local midnight on
// the 1st. 2026-07-01 00:00 ICT = 2026-06-30 17:00 UTC.
const julyMonth = Timestamp.fromDate(new Date('2026-06-30T17:00:00Z'));

/**
 * Writes the budget into the fake store *and* returns a matching event
 * payload — a real `onDocumentWritten` trigger only fires once the write
 * has already landed, so a handler's own independent `.get()` (which
 * `recomputeBudgetSpend` does) would see the same data the event carries.
 * Building both from one call is what keeps that in sync in the fixture.
 */
function seedBudgetWrite(data: Record<string, unknown> | undefined) {
  if (data) fakeDb.write(`users/${userId}/budgets/${budgetId}`, data);
  return { data: () => data, exists: data !== undefined };
}

describe('handleBudgetWrite', () => {
  beforeEach(() => {
    fakeDb = new FakeFirestore();
    sendEachForMulticast.mockReset();
    sendEachForMulticast.mockResolvedValue({ responses: [{ success: true }] });

    fakeDb.seed(`users/${userId}`, { notificationsEnabled: true, lastActiveAt: null });
    fakeDb.seed(`users/${userId}/categories/cat1`, { name: 'Groceries' });
    fakeDb.seed(`users/${userId}/accounts/acc1`, { currencyCode: 'LAK' });
    fakeDb.seed(`users/${userId}/fcmTokens/token1`, { token: 'token1' });
  });

  it('does nothing when the budget was deleted', async () => {
    await handleBudgetWrite({
      params: { userId, budgetId },
      data: { after: seedBudgetWrite(undefined) },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any);

    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('lowering the limit below already-existing spend triggers a push with no new transactions', async () => {
    fakeDb.seed(`users/${userId}/transactions/t1`, {
      type: 'expense',
      categoryId: 'cat1',
      accountId: 'acc1',
      amount: 150,
      date: Timestamp.fromDate(new Date(Date.UTC(2026, 6, 10, 10))),
    });

    await handleBudgetWrite({
      params: { userId, budgetId },
      data: {
        after: seedBudgetWrite({
          categoryId: 'cat1',
          month: julyMonth,
          limitAmount: 100, // lowered below the existing 150 spent
          currencyCode: 'LAK',
        }),
      },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any);

    expect(sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ type: 'budget_exceeded' }) }),
    );
    expect(fakeDb.read(`users/${userId}/notificationState/budget:${budgetId}`)).toMatchObject({
      active: true,
    });
  });

  it('raising the limit above existing spend clears a previously-active state', async () => {
    fakeDb.seed(`users/${userId}/notificationState/budget:${budgetId}`, {
      active: true,
      notifiedAt: Timestamp.now(),
    });
    fakeDb.seed(`users/${userId}/transactions/t1`, {
      type: 'expense',
      categoryId: 'cat1',
      accountId: 'acc1',
      amount: 50,
      date: Timestamp.fromDate(new Date(Date.UTC(2026, 6, 10, 10))),
    });

    await handleBudgetWrite({
      params: { userId, budgetId },
      data: {
        after: seedBudgetWrite({
          categoryId: 'cat1',
          month: julyMonth,
          limitAmount: 100,
          currencyCode: 'LAK',
        }),
      },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any);

    expect(sendEachForMulticast).not.toHaveBeenCalled();
    expect(fakeDb.read(`users/${userId}/notificationState/budget:${budgetId}`)).toMatchObject({
      active: false,
    });
  });
});
