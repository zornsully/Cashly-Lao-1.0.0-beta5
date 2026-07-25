import type { Firestore } from 'firebase-admin/firestore';
import { FakeFirestore } from '../helpers/fakeFirestore';
import { sendPushToUser } from '../../src/lib/sendPush';

const sendEachForMulticast = jest.fn();
jest.mock('firebase-admin/messaging', () => ({
  getMessaging: () => ({ sendEachForMulticast }),
}));

describe('sendPushToUser', () => {
  let fakeDb: FakeFirestore;
  let db: Firestore;

  beforeEach(() => {
    fakeDb = new FakeFirestore();
    db = fakeDb as unknown as Firestore;
    sendEachForMulticast.mockReset();
  });

  it('does nothing when the user has no registered tokens', async () => {
    await sendPushToUser(db, 'user1', { type: 'budget_exceeded' });
    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('sends to every registered token with the given data payload', async () => {
    fakeDb.seed('users/user1/fcmTokens/token-a', { token: 'token-a', platform: 'android' });
    fakeDb.seed('users/user1/fcmTokens/token-b', { token: 'token-b', platform: 'android' });
    sendEachForMulticast.mockResolvedValue({
      responses: [{ success: true }, { success: true }],
    });

    await sendPushToUser(db, 'user1', { type: 'budget_exceeded', id: 'b1' });

    expect(sendEachForMulticast).toHaveBeenCalledWith({
      tokens: expect.arrayContaining(['token-a', 'token-b']),
      data: { type: 'budget_exceeded', id: 'b1' },
    });
  });

  it('prunes tokens reported as not-registered or invalid, but keeps tokens that failed for other reasons', async () => {
    fakeDb.seed('users/user1/fcmTokens/dead-token', { token: 'dead-token', platform: 'android' });
    fakeDb.seed('users/user1/fcmTokens/invalid-token', { token: 'invalid-token', platform: 'android' });
    fakeDb.seed('users/user1/fcmTokens/live-token', { token: 'live-token', platform: 'android' });
    fakeDb.seed('users/user1/fcmTokens/transient-failure-token', {
      token: 'transient-failure-token',
      platform: 'android',
    });

    sendEachForMulticast.mockImplementation(async ({ tokens }: { tokens: string[] }) => ({
      responses: tokens.map((token) => {
        if (token === 'dead-token') {
          return { success: false, error: { code: 'messaging/registration-token-not-registered' } };
        }
        if (token === 'invalid-token') {
          return { success: false, error: { code: 'messaging/invalid-registration-token' } };
        }
        if (token === 'transient-failure-token') {
          return { success: false, error: { code: 'messaging/internal-error' } };
        }
        return { success: true };
      }),
    }));

    await sendPushToUser(db, 'user1', { type: 'negative_balance' });

    expect(fakeDb.read('users/user1/fcmTokens/dead-token')).toBeUndefined();
    expect(fakeDb.read('users/user1/fcmTokens/invalid-token')).toBeUndefined();
    expect(fakeDb.read('users/user1/fcmTokens/live-token')).toBeDefined();
    expect(fakeDb.read('users/user1/fcmTokens/transient-failure-token')).toBeDefined();
  });
});
