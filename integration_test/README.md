# Integration tests

`app_flow_test.dart` drives the real app end-to-end (register → accounts →
transactions → transfer → edit/delete → budget → savings goal → report →
language switch → logout/login → delete-account dialog verification)
against a local Firebase Emulator Suite. It never touches production
Firebase — see `main.dart`'s `_useFirebaseEmulator` gate, which only
activates when the test passes `--dart-define=USE_FIREBASE_EMULATOR=true`.

## Running it

1. Start the emulators (Auth + Firestore only — nothing else is needed):

   ```bash
   firebase emulators:start --only auth,firestore --project cashly-lao
   ```

   Leave this running in its own terminal. The app's `main.dart` points at
   `localhost:9099` (Auth) and `localhost:8080` (Firestore), matching the
   ports configured in `firebase.json`'s `emulators` block.

2. In another terminal, run the test against a real device target — the
   Flutter `integration_test` package doesn't support `-d chrome` for this
   kind of test (that needs `flutter drive` instead, a different, heavier
   setup), so on a machine without a mobile device/emulator attached,
   Windows desktop is the practical target:

   ```bash
   flutter test integration_test/app_flow_test.dart -d windows --dart-define=USE_FIREBASE_EMULATOR=true
   ```

   First-time setup on Windows needs Developer Mode enabled (Flutter
   requires symlink support to build plugins) and a working native
   C++ toolchain (Visual Studio with the Desktop development with C++
   workload, including the ATL component).

## Known limitation: account deletion isn't exercised end-to-end

Step 14 opens the delete-account dialog, verifies its password field
actually validates (an empty submission is rejected without attempting
deletion), and verifies Cancel safely returns to Profile — but it
deliberately never taps through to a real deletion.

Confirming would call `user.reauthenticateWithCredential(...)`
(`profile_screen.dart`), which never resolves against the Firebase Auth
Emulator on Windows desktop specifically. Windows' `firebase_auth` wraps
Firebase's native C++ SDK rather than a REST implementation (unlike
web/Android/iOS), and that native plugin's reauthentication path hangs
indefinitely against the emulator — confirmed directly with an isolated
call under an explicit 90-second timeout that never resolved. This is a
platform/SDK-level gap, not an app bug: the app's own
reauthenticate-before-delete flow is correct and matches Firebase's own
documented pattern, and works fine against real Firebase.

Real end-to-end account deletion remains a manual QA step before release,
on a real device/build where the emulator limitation doesn't apply.

## Test accounts

Each run registers a fresh user (`integration-test-<timestamp>@example.com`)
against the emulator, so runs don't collide with each other. Emulator data
is ephemeral — it resets whenever the emulator process restarts unless you
explicitly export it (`--export-on-exit`), so leftover test users/data
from a run that (deliberately) never deletes its account don't accumulate
across restarts.
