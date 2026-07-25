import 'package:cashly_lao/core/providers/local_notifications_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression test: notificationIdFor was extracted from three separate
  // inline `'<type>-$id'.hashCode` expressions in budget_alert_providers
  // .dart/goal_reminder_providers.dart. This proves the extraction is
  // behavior-preserving — an already-shipped budget/account/goal alert's
  // tray notification ID must not change out from under it.
  test('matches the original inline hashCode expressions exactly', () {
    expect(notificationIdFor('budget', 'cat1_2026-07'), 'budget-cat1_2026-07'.hashCode);
    expect(notificationIdFor('account', 'acc1'), 'account-acc1'.hashCode);
    expect(notificationIdFor('goal', 'goal1'), 'goal-goal1'.hashCode);
  });

  test('different types with the same id produce different notification ids', () {
    expect(
      notificationIdFor('budget', 'shared-id'),
      isNot(notificationIdFor('account', 'shared-id')),
    );
  });
}
