import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/savings_goals/domain/entities/goal_contribution_frequency.dart';
import '../../features/savings_goals/presentation/utils/goal_contribution_frequency_label.dart';
import '../../l10n/app_localizations.dart';
import '../providers/local_notifications_providers.dart';

/// Resolved title/body/channel for a push notification's data payload — the
/// one piece of FCM message handling that's pure Dart (no Firebase/Riverpod
/// involved), shared by both the foreground handler
/// (`fcm_message_providers.dart`) and the background isolate handler
/// (`fcm_background_handler.dart`) so a push displays identically either
/// way. Reuses the *exact* same `AppLocalizations` strings/channels local
/// alerts already use — this is what lets FCM ship with zero new ARB keys,
/// since Cloud Functions send only structured data, never pre-rendered text
/// (see `functions/src/lib/evaluateAndNotify.ts`).
///
/// Returns `null` for an unrecognized `type` or malformed `frequency` —
/// this is parsing data sent by our own Cloud Functions, but a push
/// payload still crosses a real boundary (unlike `fromFirestore` mapping
/// the app's own writes), so a background isolate handler silently drops
/// what it can't recognize rather than throwing.
({String title, String body, AndroidNotificationChannel channel})?
buildPushNotificationContent(AppLocalizations l10n, Map<String, dynamic> data) {
  switch (data['type']) {
    case 'budget_exceeded':
      return (
        title: l10n.budgetExceededNotificationTitle,
        body: l10n.budgetExceededNotificationBody(
          data['categoryName'] as String? ?? '',
        ),
        channel: budgetAlertsChannel,
      );
    case 'negative_balance':
      return (
        title: l10n.negativeBalanceNotificationTitle,
        body: l10n.negativeBalanceNotificationBody(
          data['accountName'] as String? ?? '',
        ),
        channel: budgetAlertsChannel,
      );
    case 'goal_reminder':
      final frequency = _parseFrequency(data['frequency'] as String?);
      if (frequency == null) return null;
      return (
        title: l10n.goalReminderNotificationTitle,
        body: l10n.goalReminderNotificationBody(
          frequency.localizedLabel(l10n),
          data['goalName'] as String? ?? '',
        ),
        channel: goalRemindersChannel,
      );
    default:
      return null;
  }
}

GoalContributionFrequency? _parseFrequency(String? name) {
  for (final frequency in GoalContributionFrequency.values) {
    if (frequency.name == name) return frequency;
  }
  return null;
}
