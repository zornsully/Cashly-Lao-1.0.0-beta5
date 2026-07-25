/// Central registry of Firestore collection names so datasources never
/// hardcode path strings inline.
abstract final class FirestorePaths {
  static const String users = 'users';

  /// Subcollection of `users/{uid}`: `users/{uid}/accounts/{accountId}`.
  static const String accounts = 'accounts';

  /// Subcollection of `users/{uid}`: `users/{uid}/categories/{categoryId}`.
  static const String categories = 'categories';

  /// Field on the `users/{uid}` document marking whether the default
  /// category set has already been seeded for this user.
  static const String defaultCategoriesSeededField = 'defaultCategoriesSeeded';

  /// Subcollection of `users/{uid}`: `users/{uid}/transactions/{transactionId}`.
  static const String transactions = 'transactions';

  /// Subcollection of `users/{uid}`: `users/{uid}/budgets/{budgetId}`.
  /// Document IDs are deterministic (`{categoryId}_{yyyy-MM}`), which is
  /// what makes "one budget per category per month" an invariant of the
  /// data model rather than something enforced by a query.
  static const String budgets = 'budgets';

  /// Subcollection of `users/{uid}`: `users/{uid}/savingsGoals/{goalId}`.
  static const String savingsGoals = 'savingsGoals';

  /// Subcollection of `users/{uid}`: `users/{uid}/fcmTokens/{tokenId}`.
  /// Document ID is the token string itself — see `firestore.rules`.
  static const String fcmTokens = 'fcmTokens';

  /// Subcollection of `users/{uid}`: `users/{uid}/notificationState/{stateId}`.
  /// Server-only (Cloud Functions Admin SDK) — the client never reads or
  /// writes this, so no Dart datasource ever references this constant
  /// directly; kept here only so the collection name has one source of
  /// truth alongside every other one.
  static const String notificationState = 'notificationState';

  /// Field on the `users/{uid}` document: a heartbeat timestamp the client
  /// writes periodically while the authenticated app is alive, so Cloud
  /// Functions can distinguish "local notifications already cover this"
  /// from "app is closed, push is needed." See
  /// `lib/core/providers/presence_providers.dart`.
  static const String lastActiveAtField = 'lastActiveAt';
}
