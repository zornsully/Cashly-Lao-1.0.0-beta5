import type { Timestamp } from 'firebase-admin/firestore';

/**
 * Generously above the client's 60s heartbeat cadence
 * (lib/core/providers/presence_providers.dart) to absorb jitter, brief
 * backgrounding, or a slow write — deliberately biased toward "assume
 * present" only when there's real recent evidence of it, not the reverse.
 */
const PRESENCE_FRESHNESS_MS = 3 * 60 * 1000;

/**
 * Whether `lastActiveAt` is recent enough that the client's own local
 * notification listeners are presumed still running, i.e. a push here
 * would be redundant. `undefined` (never heartbeated — notifications were
 * never enabled, or this is the very first crossing before one landed) is
 * always treated as stale, i.e. push is needed.
 */
export function isPresenceFresh(
  lastActiveAt: Timestamp | undefined,
  now: Date = new Date(),
): boolean {
  if (!lastActiveAt) return false;
  return now.getTime() - lastActiveAt.toMillis() < PRESENCE_FRESHNESS_MS;
}
