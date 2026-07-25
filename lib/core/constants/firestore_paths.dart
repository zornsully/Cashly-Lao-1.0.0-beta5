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
}
