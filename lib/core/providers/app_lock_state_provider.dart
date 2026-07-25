import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the current app session has been unlocked (via biometric/device
/// credential) since the app-lock gate last required it — see
/// `AppRoutes.lock` / `app_router.dart`'s redirect. Ephemeral, unlike the
/// persisted `appLockEnabled` preference: this resets to `false` whenever
/// the app is backgrounded (`CashlyApp`'s `WidgetsBindingObserver`), so
/// returning to the app after switching away re-requires unlocking — the
/// same behavior most banking apps use. Also resets on every fresh app
/// launch, since it's a plain in-memory provider.
class AppLockState extends Notifier<bool> {
  @override
  bool build() => false;

  void unlock() => state = true;

  void lock() => state = false;
}

final isUnlockedProvider = NotifierProvider<AppLockState, bool>(
  AppLockState.new,
);
