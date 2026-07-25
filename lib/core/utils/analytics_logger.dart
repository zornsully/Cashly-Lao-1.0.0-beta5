import 'package:firebase_analytics/firebase_analytics.dart';

/// Fire-and-forget analytics logging. Swallows any failure — no Firebase
/// app in a test environment, no network, collection disabled — so an
/// instrumentation call can never break the user-facing action it's
/// attached to (a failed analytics log must never fail an account
/// creation, for instance).
///
/// Takes a closure (`() => ref.read(analyticsProvider)`) rather than the
/// resolved instance directly — `ref.read` itself is what throws when
/// there's no Firebase app (e.g. in a test), so that read has to happen
/// *inside* this function's try block, not as an argument evaluated by
/// the caller before this function is ever entered. Also sidesteps `Ref`
/// vs. `WidgetRef` not sharing a type: callers pass a closure either way.
Future<void> logAnalyticsEvent(
  FirebaseAnalytics Function() analytics,
  String name, [
  Map<String, Object>? parameters,
]) async {
  try {
    await analytics().logEvent(name: name, parameters: parameters);
  } catch (_) {}
}
