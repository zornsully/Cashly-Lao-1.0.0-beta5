import { ictComponents, ictMidnightInstant } from '../lib/ictCalendar';

export type GoalContributionFrequency = 'weekly' | 'biweekly' | 'monthly';

const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Faithful TypeScript port of
 * `lib/features/savings_goals/domain/entities/goal_contribution_frequency.dart`'s
 * `nextDueDate` — the next occurrence strictly after `from`. Weekly/biweekly
 * are pure instant arithmetic (matching Dart's `from.add(Duration(days: n))`
 * exactly — no timezone involved). Monthly reconstructs the same
 * day-of-month next month at *midnight*, matching Dart's
 * `DateTime(from.year, from.month + 1, from.day)` (which drops from's time-
 * of-day entirely) — see `../lib/ictCalendar.ts` for why ICT specifically
 * is used to read/construct the calendar day server-side.
 */
export function nextDueDate(from: Date, frequency: GoalContributionFrequency): Date {
  switch (frequency) {
    case 'weekly':
      return new Date(from.getTime() + 7 * DAY_MS);
    case 'biweekly':
      return new Date(from.getTime() + 14 * DAY_MS);
    case 'monthly': {
      const { year, month, day } = ictComponents(from);
      return ictMidnightInstant(year, month + 1, day);
    }
  }
}

/** Mirrors `SavingsGoalEntity.isReminderDue` (`!nextDueDate(...).isAfter(now)`). */
export function isReminderDue(
  lastContributionAt: Date,
  frequency: GoalContributionFrequency,
  now: Date,
): boolean {
  return nextDueDate(lastContributionAt, frequency).getTime() <= now.getTime();
}
