import { Timestamp } from 'firebase-admin/firestore';
import { isPresenceFresh } from '../../src/lib/presence';

describe('isPresenceFresh', () => {
  const now = new Date('2026-07-25T12:00:00Z');

  it('is stale when lastActiveAt is undefined (never heartbeated)', () => {
    expect(isPresenceFresh(undefined, now)).toBe(false);
  });

  it('is fresh just under the 3-minute threshold', () => {
    const lastActiveAt = Timestamp.fromDate(new Date(now.getTime() - 2 * 60 * 1000));
    expect(isPresenceFresh(lastActiveAt, now)).toBe(true);
  });

  it('is stale just over the 3-minute threshold', () => {
    const lastActiveAt = Timestamp.fromDate(new Date(now.getTime() - 4 * 60 * 1000));
    expect(isPresenceFresh(lastActiveAt, now)).toBe(false);
  });

  it('is stale exactly at the threshold boundary', () => {
    const lastActiveAt = Timestamp.fromDate(new Date(now.getTime() - 3 * 60 * 1000));
    expect(isPresenceFresh(lastActiveAt, now)).toBe(false);
  });
});
