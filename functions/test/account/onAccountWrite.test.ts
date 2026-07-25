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

import { handleAccountWrite } from '../../src/account/onAccountWrite';

const userId = 'user1';
const accountId = 'acc1';

function accountSnapshot(data: Record<string, unknown> | undefined) {
  return { data: () => data, exists: data !== undefined };
}

describe('handleAccountWrite', () => {
  beforeEach(() => {
    fakeDb = new FakeFirestore();
    sendEachForMulticast.mockReset();
    sendEachForMulticast.mockResolvedValue({ responses: [{ success: true }] });
    fakeDb.seed(`users/${userId}`, { notificationsEnabled: true, lastActiveAt: null });
    fakeDb.seed(`users/${userId}/fcmTokens/token1`, { token: 'token1' });
  });

  it('sends a push directly off the denormalized balance field, with no recompute', async () => {
    await handleAccountWrite({
      params: { userId, accountId },
      data: { after: accountSnapshot({ name: 'Main Wallet', balance: -5000 }) },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any);

    expect(sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ type: 'negative_balance', accountName: 'Main Wallet' }),
      }),
    );
    expect(fakeDb.read(`users/${userId}/notificationState/account:${accountId}`)).toMatchObject({
      active: true,
    });
  });

  it('does not push for a non-negative balance', async () => {
    await handleAccountWrite({
      params: { userId, accountId },
      data: { after: accountSnapshot({ name: 'Main Wallet', balance: 1000 }) },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any);

    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('treats a deleted account (no after data) as clearing any active negative-balance state', async () => {
    fakeDb.seed(`users/${userId}/notificationState/account:${accountId}`, {
      active: true,
      notifiedAt: null,
    });

    await handleAccountWrite({
      params: { userId, accountId },
      data: { after: accountSnapshot(undefined) },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any);

    expect(sendEachForMulticast).not.toHaveBeenCalled();
    expect(fakeDb.read(`users/${userId}/notificationState/account:${accountId}`)).toMatchObject({
      active: false,
    });
  });
});
