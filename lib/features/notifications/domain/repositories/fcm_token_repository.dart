import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

/// Registers/unregisters this device's FCM token against the signed-in
/// user's profile, so Cloud Functions know where to push. No read/list
/// method exists here deliberately — the client never needs to enumerate
/// its own registered tokens, only write or remove one by value (see
/// `firestore.rules`' `fcmTokens` block, keyed by the token itself).
abstract interface class FcmTokenRepository {
  Future<Either<Failure, Unit>> registerToken({
    required String token,
    required String platform,
  });

  Future<Either<Failure, Unit>> unregisterToken(String token);
}
