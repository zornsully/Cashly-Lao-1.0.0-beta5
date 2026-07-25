import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getFirestore, type Firestore, type Timestamp } from 'firebase-admin/firestore';
import { evaluateAndNotify } from '../lib/evaluateAndNotify';
import { isReminderDue, type GoalContributionFrequency } from './goalDueDate';

const REMINDABLE_FREQUENCIES: GoalContributionFrequency[] = ['weekly', 'biweekly', 'monthly'];

/**
 * Goal reminders are driven by time passing, not a write — a due date can
 * arrive with zero intervening writes to the goal doc (see
 * `SavingsGoalEntity.isReminderDue`, compared against `DateTime.now()`).
 * A write-triggered function would simply never fire for that case, so
 * this runs on a schedule instead of a Firestore trigger, unlike every
 * other alert type in this codebase.
 *
 * Takes `db`/`now` as parameters (rather than resolving them internally)
 * so tests can supply a fake Firestore and a fixed clock directly — see
 * `budget/onTransactionWrite.ts`'s doc comment for the same reasoning
 * applied to the write-triggered functions.
 */
export async function runGoalReminderCheck(db: Firestore, now: Date): Promise<void> {
  // isReminderDue() itself has no archived check (mirrors the client,
  // which only ever watches savingsGoalsProvider(false)) — filtered
  // explicitly here, or archived goals would remind forever.
  const snapshot = await db
    .collectionGroup('savingsGoals')
    .where('isArchived', '==', false)
    .where('autoContributionFrequency', 'in', REMINDABLE_FREQUENCIES)
    .get();

  for (const doc of snapshot.docs) {
    const userId = doc.ref.parent.parent?.id;
    if (!userId) continue;

    const data = doc.data();
    const frequency = data.autoContributionFrequency as GoalContributionFrequency;
    const lastContributionAt = (data.lastContributionAt as Timestamp | undefined)?.toDate();
    if (!lastContributionAt) continue;

    await evaluateAndNotify({
      db,
      userId,
      stateId: `goal:${doc.id}`,
      isActiveNow: isReminderDue(lastContributionAt, frequency, now),
      buildPushData: (lang) => ({
        type: 'goal_reminder',
        id: doc.id,
        goalName: (data.name as string | undefined) ?? '',
        frequency,
        lang,
      }),
    });
  }
}

export const checkGoalReminders = onSchedule('every 1 hours', async () => {
  await runGoalReminderCheck(getFirestore(), new Date());
});
