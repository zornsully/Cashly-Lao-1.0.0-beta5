import type { Firestore } from 'firebase-admin/firestore';
import { Timestamp } from 'firebase-admin/firestore';
import { FakeFirestore } from '../helpers/fakeFirestore';

const sendEachForMulticast = jest.fn();
jest.mock('firebase-admin/messaging', () => ({
  getMessaging: () => ({ sendEachForMulticast }),
}));

import { runGoalReminderCheck } from '../../src/goals/checkGoalReminders';

describe('runGoalReminderCheck', () => {
  let fakeDb: FakeFirestore;
  let db: Firestore;
  const now = new Date('2026-08-01T00:00:00Z');

  beforeEach(() => {
    fakeDb = new FakeFirestore();
    db = fakeDb as unknown as Firestore;
    sendEachForMulticast.mockReset();
    sendEachForMulticast.mockResolvedValue({ responses: [{ success: true }] });
  });

  function seedGoal(
    userId: string,
    goalId: string,
    overrides: Record<string, unknown> = {},
  ) {
    fakeDb.seed(`users/${userId}`, { notificationsEnabled: true, lastActiveAt: null });
    fakeDb.seed(`users/${userId}/fcmTokens/token1`, { token: 'token1' });
    fakeDb.seed(`users/${userId}/savingsGoals/${goalId}`, {
      name: 'New Motorbike',
      isArchived: false,
      autoContributionFrequency: 'weekly',
      lastContributionAt: Timestamp.fromDate(new Date('2026-07-01T00:00:00Z')), // due a month ago
      ...overrides,
    });
  }

  it('sends a reminder for a goal whose weekly schedule is overdue', async () => {
    seedGoal('user1', 'goal1');

    await runGoalReminderCheck(db, now);

    expect(sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ type: 'goal_reminder', goalName: 'New Motorbike' }),
      }),
    );
    expect(fakeDb.read('users/user1/notificationState/goal:goal1')).toMatchObject({ active: true });
  });

  it('does not remind for a goal that is not yet due', async () => {
    seedGoal('user1', 'goal1', {
      lastContributionAt: Timestamp.fromDate(new Date('2026-07-30T00:00:00Z')), // due in ~6 days
    });

    await runGoalReminderCheck(db, now);

    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('excludes archived goals even when their schedule is overdue', async () => {
    seedGoal('user1', 'goal1', { isArchived: true });

    await runGoalReminderCheck(db, now);

    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('excludes goals with no auto-contribution schedule', async () => {
    seedGoal('user1', 'goal1', { autoContributionFrequency: '' });

    await runGoalReminderCheck(db, now);

    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('scans across every user via the collection group, not just one', async () => {
    seedGoal('user1', 'goal1');
    seedGoal('user2', 'goal2');

    await runGoalReminderCheck(db, now);

    expect(fakeDb.read('users/user1/notificationState/goal:goal1')).toMatchObject({ active: true });
    expect(fakeDb.read('users/user2/notificationState/goal:goal2')).toMatchObject({ active: true });
    expect(sendEachForMulticast).toHaveBeenCalledTimes(2);
  });
});
