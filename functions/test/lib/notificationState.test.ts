import type { Firestore } from 'firebase-admin/firestore';
import { Timestamp } from 'firebase-admin/firestore';
import { FakeFirestore } from '../helpers/fakeFirestore';
import { readNotificationState, writeNotificationState } from '../../src/lib/notificationState';

describe('notificationState', () => {
  let fakeDb: FakeFirestore;
  let db: Firestore;

  beforeEach(() => {
    fakeDb = new FakeFirestore();
    db = fakeDb as unknown as Firestore;
  });

  it('defaults to inactive when no state doc exists yet', async () => {
    const state = await readNotificationState(db, 'user1', 'budget:cat1_2026-07');
    expect(state).toEqual({ active: false, notifiedAt: null });
  });

  it('round-trips a written state', async () => {
    const notifiedAt = Timestamp.now();
    await writeNotificationState(db, 'user1', 'budget:cat1_2026-07', {
      active: true,
      notifiedAt,
    });

    const state = await readNotificationState(db, 'user1', 'budget:cat1_2026-07');
    expect(state.active).toBe(true);
    expect(state.notifiedAt).toBe(notifiedAt);
  });

  it('scopes state by both userId and stateId independently', async () => {
    await writeNotificationState(db, 'user1', 'budget:cat1_2026-07', {
      active: true,
      notifiedAt: null,
    });

    expect(await readNotificationState(db, 'user2', 'budget:cat1_2026-07')).toEqual({
      active: false,
      notifiedAt: null,
    });
    expect(await readNotificationState(db, 'user1', 'account:acc1')).toEqual({
      active: false,
      notifiedAt: null,
    });
  });
});
