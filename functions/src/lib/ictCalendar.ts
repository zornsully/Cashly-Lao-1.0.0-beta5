/**
 * Cashly's Dart-side date arithmetic (a budget's `month`, a savings goal's
 * `nextDueDate`, etc.) is built on plain local `DateTime`s — see
 * `transaction_remote_datasource.dart`'s `watchTransactionsForMonth`
 * (`DateTime(month.year, month.month)`, no `.utc`) and
 * `goal_contribution_frequency.dart`'s monthly case. That means "month" and
 * "day" boundaries are anchored to whatever timezone the user's *device* is
 * set to. Cloud Functions have no device and no stored per-user timezone
 * field, so this hardcodes Laos time (ICT, UTC+7, no DST) as the deliberate
 * stand-in — consistent with Cashly's Lao-market positioning (CLAUDE.md).
 * A user traveling in a different timezone may see a small disagreement
 * right at month/day boundaries; an accepted, documented simplification,
 * not an oversight.
 */
const ICT_OFFSET_MS = 7 * 60 * 60 * 1000;

export interface IctDateComponents {
  year: number;
  /** 0-indexed, matching `Date`'s own month convention. */
  month: number;
  day: number;
}

/** Extracts the ICT calendar day an absolute instant falls on. */
export function ictComponents(instant: Date): IctDateComponents {
  const shifted = new Date(instant.getTime() + ICT_OFFSET_MS);
  return {
    year: shifted.getUTCFullYear(),
    month: shifted.getUTCMonth(),
    day: shifted.getUTCDate(),
  };
}

/**
 * The absolute instant corresponding to ICT midnight on the given
 * (0-indexed month) calendar day. Overflowing `month`/`day` normalize the
 * same way `Date.UTC` already does (e.g. month 12 rolls into next year).
 */
export function ictMidnightInstant(year: number, month: number, day = 1): Date {
  return new Date(Date.UTC(year, month, day) - ICT_OFFSET_MS);
}
