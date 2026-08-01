import 'package:flutter/material.dart';

/// Displays a real application state while required startup work is running.
///
/// Flutter's default web bootstrap has no UI of its own. Keeping this gate
/// above [CashlyApp] means a Firebase outage, a bad configuration, or a timed
/// out startup call can never leave visitors on an empty browser page.
class CashlyStartupApp extends StatefulWidget {
  const CashlyStartupApp({
    required this.initialize,
    this.appBuilder,
    super.key,
  });

  /// Performs only startup work that the core application actually needs.
  final Future<void> Function() initialize;

  /// Allows tests to supply a small ready app without creating Firebase-backed
  /// providers. Production uses [CashlyApp] through the default builder.
  final WidgetBuilder? appBuilder;

  @override
  State<CashlyStartupApp> createState() => _CashlyStartupAppState();
}

class _CashlyStartupAppState extends State<CashlyStartupApp> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _startInitialization();
  }

  void _retry() {
    final nextInitialization = _startInitialization();
    setState(() {
      _initialization = nextInitialization;
    });
  }

  Future<void> _startInitialization() async {
    try {
      await widget.initialize();
    } catch (error, stackTrace) {
      // Keep the user-facing screen deliberately generic, but retain a
      // diagnostic record in the browser/device console for support.
      debugPrint('Cashly required startup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return widget.appBuilder?.call(context) ?? const SizedBox.shrink();
        }

        final failed = snapshot.hasError;
        return MaterialApp(
          title: 'Cashly Lao',
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _CashlyMark(),
                        const SizedBox(height: 24),
                        Text(
                          failed
                              ? 'Cashly Lao could not start.'
                              : 'Loading Cashly Lao…',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          failed
                              ? 'Check your connection and try again.'
                              : 'Preparing your secure money workspace.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (failed) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Reference: ${snapshot.error.runtimeType}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (failed)
                          FilledButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          )
                        else
                          const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CashlyMark extends StatelessWidget {
  const _CashlyMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: const Icon(
        Icons.account_balance_wallet_rounded,
        color: Colors.white,
        size: 36,
      ),
    );
  }
}
