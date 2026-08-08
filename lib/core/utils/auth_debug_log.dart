import 'package:flutter/foundation.dart';

/// Mirror of the `[AUTH-NN]` debugPrint trail, kept on-screen in debug builds
/// only (via [AuthDebugOverlay]) so a plain screenshot of the page shows
/// exactly which stage a login attempt reached -- no DevTools console
/// needed. Gated entirely behind [kDebugMode]: a release build (including
/// every deployed production build) never prints these lines and never
/// populates [entries], so [AuthDebugOverlay] always renders empty there
/// regardless of whether it's still wired in.
class AuthDebugLog {
  AuthDebugLog._();

  // A full sign-out + sign-in-again cycle alone generates ~20 entries
  // (AUTH-10/11/11b fire on every redirect re-evaluation, not just once per
  // action) -- 14 was proven too small during live testing, truncating
  // exactly the entries needed to see the router's actual decision.
  static const _maxEntries = 40;

  static final ValueNotifier<List<String>> entries = ValueNotifier(const []);

  static void log(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
    final next = [...entries.value, message];
    entries.value = next.length > _maxEntries
        ? next.sublist(next.length - _maxEntries)
        : next;
  }
}
