import type { Firestore } from 'firebase-admin/firestore';
import { FakeFirestore } from '../helpers/fakeFirestore';
import { cleanupDeletedUser } from '../../src/cleanup/onUserDeleted';

describe('cleanupDeletedUser', () => {
  let fakeDb: FakeFirestore;
  let db: Firestore;
  const userId = 'user1';

  beforeEach(() => {
    fakeDb = new FakeFirestore();
    db = fakeDb as unknown as Firestore;
  });

  it('deletes every notificationState and fcmTokens doc under the deleted user', async () => {
    fakeDb.seed(`users/${userId}/notificationState/budget:cat1_2026-07`, { active: true, notifiedAt: null });
    fakeDb.seed(`users/${userId}/notificationState/account:acc1`, { active: false, notifiedAt: null });
    fakeDb.seed(`users/${userId}/fcmTokens/token1`, { token: 'token1' });

    await cleanupDeletedUser(db, userId);

    expect(fakeDb.read(`users/${userId}/notificationState/budget:cat1_2026-07`)).toBeUndefined();
    expect(fakeDb.read(`users/${userId}/notificationState/account:acc1`)).toBeUndefined();
    expect(fakeDb.read(`users/${userId}/fcmTokens/token1`)).toBeUndefined();
  });

  it('does not touch another user’s data', async () => {
    fakeDb.seed(`users/other-user/fcmTokens/token2`, { token: 'token2' });

    await cleanupDeletedUser(db, userId);

    expect(fakeDb.read('users/other-user/fcmTokens/token2')).toBeDefined();
  });

  it('is a no-op when there is nothing to clean up', async () => {
    await expect(cleanupDeletedUser(db, userId)).resolves.not.toThrow();
  });
});
