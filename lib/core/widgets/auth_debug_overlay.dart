import 'package:flutter/material.dart';

import '../utils/auth_debug_log.dart';

/// TEMPORARY diagnostic overlay -- shows the same `[AUTH-NN]` trail as the
/// browser console, directly on screen, behind every route. A plain
/// screenshot of the page is enough to see exactly where a login attempt
/// stalled or failed, without opening DevTools. Remove once the live web
/// auth investigation is closed; see CLAUDE.md's dated entries for context.
class AuthDebugOverlay extends StatelessWidget {
  const AuthDebugOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: IgnorePointer(
            child: ValueListenableBuilder<List<String>>(
              valueListenable: AuthDebugLog.entries,
              builder: (context, log, _) {
                if (log.isEmpty) return const SizedBox.shrink();
                return Container(
                  constraints: const BoxConstraints(maxHeight: 420),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xE6000000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final line in log)
                          Text(
                            line,
                            style: const TextStyle(
                              color: Color(0xFF69F0AE),
                              fontSize: 10,
                              fontFamily: 'monospace',
                              height: 1.3,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
