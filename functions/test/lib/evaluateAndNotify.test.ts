import type { Firestore } from 'firebase-admin/firestore';
import { Timestamp } from 'firebase-admin/firestore';
import { FakeFirestore } from '../helpers/fakeFirestore';
import { evaluateAndNotify } from '../../src/lib/evaluateAndNotify';
import { readNotificationState } from '../../src/lib/notificationState';

const sendEachForMulticast = jest.fn();
jest.mock('firebase-admin/messaging', () => ({
  getMessaging: () => ({ sendEachForMulticast }),
}));

describe('evaluateAndNotify', () => {
  let fakeDb: FakeFirestore;
  let db: Firestore;
  const userId = 'user1';
  const stateId = 'budget:cat1_2026-07';

  beforeEach(() => {
    fakeDb = new FakeFirestore();
    db = fakeDb as unknown as Firestore;
    sendEachForMulticast.mockReset();
    sendEachForMulticast.mockResolvedValue({ responses: [] });
  });

  function seedUser(overrides: Record<string, unknown> = {}) {
    fakeDb.seed(`users/${userId}`, { notificationsEnabled: true, ...overrides });
  }

  it('does nothing at all when notifications are disabled, even for a new crossing', async () => {
    seedUser({ notificationsEnabled: false });

    await evaluateAndNotify({
      db,
      userId,
      stateId,
      isActiveNow: true,
      buildPushData: (lang) => ({ type: 'budget_exceeded', lang }),
    });

    expect(sendEachForMulticast).not.toHaveBeenCalled();
    expect(await readNotificationState(db, userId, stateId)).toEqual({
      active: false,
      notifiedAt: null,
    });
  });

  it('false -> false is a pure no-op (no state write, no send)', async () => {
    seedUser();

    await evaluateAndNotify({
      db,
      userId,
      stateId,
      isActiveNow: false,
      buildPushData: (lang) => ({ type: 'budget_exceeded', lang }),
    });

    expect(sendEachForMulticast).not.toHaveBeenCalled();
    expect(fakeDb.read(`users/${userId}/notificationState/${stateId}`)).toBeUndefined();
  });

  it('true -> false clears an active state without sending', async () => {
    seedUser();
    fakeDb.seed(`users/${userId}/notificationState/${stateId}`, {
      active: true,
      notifiedAt: Timestamp.now(),
    });

    await evaluateAndNotify({
      db,
      userId,
      stateId,
      isActiveNow: false,
      buildPushData: (lang) => ({ type: 'budget_exceeded', lang }),
    });

    expect(sendEachForMulticast).not.toHaveBeenCalled();
    expect(await readNotificationState(db, userId, stateId)).toEqual({
      active: false,
      notifiedAt: null,
    });
  });

  it('true -> true is a no-op — already notified/suppressed for this streak', async () => {
    seedUser({ lastActiveAt: null }); // presence stale, so a real crossing WOULD send
    fakeDb.seed(`users/${userId}/notificationState/${stateId}`, {
      active: true,
      notifiedAt: null,
    });

    await evaluateAndNotify({
      db,
      userId,
      stateId,
      isActiveNow: true,
      buildPushData: (lang) => ({ type: 'budget_exceeded', lang }),
    });

    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('a new crossing (false -> true) with fresh presence records the crossing but does not send', async () => {
    seedUser({ lastActiveAt: Timestamp.now() }); // just heartbeated -> fresh

    await evaluateAndNotify({
      db,
      userId,
      stateId,
      isActiveNow: true,
      buildPushData: (lang) => ({ type: 'budget_exceeded', lang }),
    });

    expect(sendEachForMulticast).not.toHaveBeenCalled();
    expect(await readNotificationState(db, userId, stateId)).toEqual({
      active: true,
      notifiedAt: null,
    });
  });

  it('a new crossing (false -> true) with stale presence sends a push and records notifiedAt', async () => {
    seedUser({
      lastActiveAt: Timestamp.fromDate(new Date(Date.now() - 10 * 60 * 1000)), // 10 min ago -> stale
      language: 'lao',
    });
    fakeDb.seed(`users/${userId}/fcmTokens/token-a`, { token: 'token-a' });
    sendEachForMulticast.mockResolvedValue({ responses: [{ success: true }] });

    await evaluateAndNotify({
      db,
      userId,
      stateId,
      isActiveNow: true,
      buildPushData: (lang) => ({ type: 'budget_exceeded', lang, id: 'cat1_2026-07' }),
    });

    expect(sendEachForMulticast).toHaveBeenCalledWith({
      tokens: ['token-a'],
      data: { type: 'budget_exceeded', lang: 'lao', id: 'cat1_2026-07' },
    });
    const state = await readNotificationState(db, userId, stateId);
    expect(state.active).toBe(true);
    expect(state.notifiedAt).not.toBeNull();
  });

  it('a new crossing with no heartbeat at all (never enabled until now) is treated as stale and sends', async () => {
    seedUser(); // no lastActiveAt field at all
    fakeDb.seed(`users/${userId}/fcmTokens/token-a`, { token: 'token-a' });
    sendEachForMulticast.mockResolvedValue({ responses: [{ success: true }] });

    await evaluateAndNotify({
      db,
      userId,
      stateId,
      isActiveNow: true,
      buildPushData: (lang) => ({ type: 'budget_exceeded', lang }),
    });

    expect(sendEachForMulticast).toHaveBeenCalled();
  });

  it('defaults lang to "english" when the user has no language field set', async () => {
    seedUser({ lastActiveAt: null });
    fakeDb.seed(`users/${userId}/fcmTokens/token-a`, { token: 'token-a' });
    sendEachForMulticast.mockResolvedValue({ responses: [{ success: true }] });

    await evaluateAndNotify({
      db,
      userId,
      stateId,
      isActiveNow: true,
      buildPushData: (lang) => ({ type: 'budget_exceeded', lang }),
    });

    expect(sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ lang: 'english' }) }),
    );
  });
});
