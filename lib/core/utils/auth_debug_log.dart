import 'package:flutter/foundation.dart';

/// TEMPORARY mirror of the `[AUTH-NN]` debugPrint trail, kept on-screen (via
/// [AuthDebugOverlay]) so a plain screenshot of the page shows exactly which
/// stage a login attempt reached -- no DevTools console needed. Remove once
/// the live web auth investigation is closed; see CLAUDE.md's dated entries.
class AuthDebugLog {
  AuthDebugLog._();

  static const _maxEntries = 14;

  static final ValueNotifier<List<String>> entries = ValueNotifier(const []);

  static void log(String message) {
    debugPrint(message);
    final next = [...entries.value, message];
    entries.value = next.length > _maxEntries
        ? next.sublist(next.length - _maxEntries)
        : next;
  }
}
