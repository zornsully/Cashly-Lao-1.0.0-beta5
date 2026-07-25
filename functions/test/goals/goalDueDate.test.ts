import { isReminderDue, nextDueDate } from '../../src/goals/goalDueDate';

describe('nextDueDate', () => {
  it('weekly adds exactly 7 days, preserving time-of-day', () => {
    const from = new Date('2026-07-01T09:30:00Z');
    expect(nextDueDate(from, 'weekly').toISOString()).toBe('2026-07-08T09:30:00.000Z');
  });

  it('biweekly adds exactly 14 days, preserving time-of-day', () => {
    const from = new Date('2026-07-01T09:30:00Z');
    expect(nextDueDate(from, 'biweekly').toISOString()).toBe('2026-07-15T09:30:00.000Z');
  });

  it('monthly reconstructs the same ICT day-of-month next month, at ICT midnight (dropping time-of-day)', () => {
    // 2026-07-15 09:30 UTC = 2026-07-15 16:30 ICT.
    const from = new Date('2026-07-15T09:30:00Z');
    // Expected: ICT midnight on 2026-08-15 = 2026-08-14 17:00 UTC.
    expect(nextDueDate(from, 'monthly').toISOString()).toBe('2026-08-14T17:00:00.000Z');
  });

  it('monthly correctly rolls from December into January of the next year', () => {
    const from = new Date('2026-12-10T00:00:00Z'); // 2026-12-10 07:00 ICT
    expect(nextDueDate(from, 'monthly').toISOString()).toBe('2027-01-09T17:00:00.000Z');
  });

  it('monthly uses the ICT calendar day even when the UTC instant already rolled to the next day', () => {
    // 2026-07-01 23:00 UTC = 2026-07-02 06:00 ICT — already the 2nd in ICT.
    const from = new Date('2026-07-01T23:00:00Z');
    // Next month's occurrence should be the 2nd of August (ICT), not the 1st.
    expect(nextDueDate(from, 'monthly').toISOString()).toBe('2026-08-01T17:00:00.000Z');
  });
});

describe('isReminderDue', () => {
  it('is not due when the next occurrence is strictly after now', () => {
    const lastContributionAt = new Date('2026-07-01T00:00:00Z');
    const now = new Date('2026-07-05T00:00:00Z');
    expect(isReminderDue(lastContributionAt, 'weekly', now)).toBe(false);
  });

  it('is due the instant the next occurrence arrives (inclusive)', () => {
    const lastContributionAt = new Date('2026-07-01T00:00:00Z');
    const dueAt = nextDueDate(lastContributionAt, 'weekly');
    expect(isReminderDue(lastContributionAt, 'weekly', dueAt)).toBe(true);
  });

  it('is due when now is well past the next occurrence', () => {
    const lastContributionAt = new Date('2026-07-01T00:00:00Z');
    const now = new Date('2026-08-01T00:00:00Z');
    expect(isReminderDue(lastContributionAt, 'monthly', now)).toBe(true);
  });
});
