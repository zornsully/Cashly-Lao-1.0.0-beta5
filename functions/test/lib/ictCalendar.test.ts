import { ictComponents, ictMidnightInstant } from '../../src/lib/ictCalendar';

describe('ictComponents', () => {
  it('reads the ICT calendar day for an instant late in the ICT day (still same UTC day)', () => {
    // 2026-07-25 20:00 ICT = 2026-07-25 13:00 UTC
    expect(ictComponents(new Date('2026-07-25T13:00:00Z'))).toEqual({
      year: 2026,
      month: 6, // 0-indexed: July
      day: 25,
    });
  });

  it('reads the ICT calendar day for an instant just after UTC midnight (already next day in ICT)', () => {
    // 2026-07-26 03:00 UTC = 2026-07-26 10:00 ICT (still the 26th)
    expect(ictComponents(new Date('2026-07-26T03:00:00Z'))).toEqual({
      year: 2026,
      month: 6,
      day: 26,
    });
  });

  it('reads the ICT calendar day for an instant just before UTC midnight that is already the next ICT day', () => {
    // 2026-07-25 23:00 UTC = 2026-07-26 06:00 ICT — a full day ahead of the UTC date.
    expect(ictComponents(new Date('2026-07-25T23:00:00Z'))).toEqual({
      year: 2026,
      month: 6,
      day: 26,
    });
  });
});

describe('ictMidnightInstant', () => {
  it('produces the UTC instant 7 hours before UTC midnight', () => {
    // ICT midnight on 2026-07-25 = 2026-07-24 17:00 UTC.
    const instant = ictMidnightInstant(2026, 6, 25);
    expect(instant.toISOString()).toBe('2026-07-24T17:00:00.000Z');
  });

  it('normalizes an overflowing month into the next year, same as Date.UTC', () => {
    const instant = ictMidnightInstant(2026, 12, 1); // month 12 -> January of 2027
    expect(instant.toISOString()).toBe('2026-12-31T17:00:00.000Z');
  });

  it('round-trips with ictComponents for a plain midnight instant', () => {
    const instant = ictMidnightInstant(2026, 6, 25);
    expect(ictComponents(instant)).toEqual({ year: 2026, month: 6, day: 25 });
  });
});
