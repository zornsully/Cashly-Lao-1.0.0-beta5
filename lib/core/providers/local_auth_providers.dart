import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Singleton `local_auth` instance, exposed through Riverpod — same
/// reasoning as [firebaseAuthProvider]/[firestoreProvider]: this is what
/// makes the app-lock flow mockable in tests instead of every call site
/// touching `LocalAuthentication()` directly.
final localAuthenticationProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});
