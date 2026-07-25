import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures surfaced to the presentation
/// layer. Repositories translate low-level exceptions into these so the UI
/// never has to depend on Firebase types directly.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Raised for any Firebase Authentication failure (invalid credentials,
/// weak password, network issues during auth, etc.).
final class AuthFailure extends Failure {
  const AuthFailure(super.message, {this.code});

  /// The original `FirebaseAuthException.code`, kept for callers that need
  /// to branch on specific error types (e.g. showing a "resend" action for
  /// `email-already-in-use`).
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// Raised for Firestore/Storage read or write failures.
final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Raised when the device has no network connectivity.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// Raised when user-supplied input fails validation before reaching a
/// remote call.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Fallback for anything unexpected.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
