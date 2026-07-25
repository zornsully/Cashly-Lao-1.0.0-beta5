import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/savings_goals/domain/entities/savings_goal_entity.dart';
import '../../features/savings_goals/presentation/providers/savings_goal_providers.dart';
import '../../features/savings_goals/presentation/utils/goal_contribution_frequency_label.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';
import '../../l10n/app_localizations.dart';
import 'local_notifications_providers.dart';

/// Which goals have already triggered a local reminder notification this
/// app session — so a reminder fires once per new due *crossing* (an
/// auto-contribution schedule's next occurrence arriving), not on every
/// rebuild while it stays due. Cleared the moment a goal is no longer due
/// (a contribution landed), so a genuine new crossing later in the session
/// reminds again. Same pattern as `budget_alert_providers.dart`'s
/// `_AlertedIds` — kept as its own notifier here rather than reusing that
/// one, since goals and budgets are unrelated alert sources.
class _AlertedGoalIds extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void add(String id) => state = {...state, id};

  void remove(String id) => state = {...state}..remove(id);
}

final _alertedDueGoalIdsProvider =
    NotifierProvider<_AlertedGoalIds, Set<String>>(_AlertedGoalIds.new);

/// Wires up savings-goal auto-contribution-due local notifications for the
/// current app session. Called once from `HomeShellScreen.build`, alongside
/// `watchBudgetAndBalanceAlerts` — both share the same `notificationsEnabled`
/// preference (see that provider's doc comment for why this doesn't get its
/// own separate Settings toggle).
void watchGoalReminders(WidgetRef ref, AppLocalizations l10n) {
  ref.listen(savingsGoalsProvider(false), (previous, next) {
    _handleGoals(ref, l10n, next);
  });
}

void _handleGoals(
  WidgetRef ref,
  AppLocalizations l10n,
  AsyncValue<List<SavingsGoalEntity>> next,
) {
  final goals = next.value;
  if (goals == null) return;
  if (!(ref.read(userPreferencesProvider).value?.notificationsEnabled ??
      false)) {
    return;
  }

  final now = DateTime.now();
  final alertedIds = ref.read(_alertedDueGoalIdsProvider);
  final currentlyDueIds = <String>{};

  for (final goal in goals) {
    if (!goal.isReminderDue(now)) continue;
    currentlyDueIds.add(goal.id);

    if (alertedIds.contains(goal.id)) continue;
    ref.read(_alertedDueGoalIdsProvider.notifier).add(goal.id);
    showLocalNotification(
      ref.read(localNotificationsPluginProvider),
      id: notificationIdFor('goal', goal.id),
      title: l10n.goalReminderNotificationTitle,
      body: l10n.goalReminderNotificationBody(
        goal.autoContributionFrequency!.localizedLabel(l10n),
        goal.name,
      ),
      channel: goalRemindersChannel,
    );
  }

  // A goal that was alerted but is no longer due (contribution made,
  // schedule disabled, or archived) can alert again if it becomes due a
  // second time.
  for (final id in alertedIds.difference(currentlyDueIds)) {
    ref.read(_alertedDueGoalIdsProvider.notifier).remove(id);
  }
}
