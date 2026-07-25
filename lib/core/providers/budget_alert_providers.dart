import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accounts/domain/entities/account_entity.dart';
import '../../features/accounts/presentation/providers/account_providers.dart';
import '../../features/budget/domain/entities/budget_progress.dart';
import '../../features/budget/presentation/providers/budget_providers.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';
import '../../l10n/app_localizations.dart';
import 'local_notifications_providers.dart';

/// Which budgets/accounts have already triggered a local notification this
/// app session — so a notification fires once per new overspend/negative-
/// balance *crossing*, not on every rebuild while the condition stays true.
/// Cleared (per-item) the moment a budget/account is no longer in that
/// state, so a genuine new crossing later in the session alerts again.
class _AlertedIds extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void add(String id) => state = {...state, id};

  void remove(String id) => state = {...state}..remove(id);
}

final _alertedOverspentBudgetIdsProvider =
    NotifierProvider<_AlertedIds, Set<String>>(_AlertedIds.new);

final _alertedNegativeAccountIdsProvider =
    NotifierProvider<_AlertedIds, Set<String>>(_AlertedIds.new);

/// Wires up budget-exceeded and negative-balance local notifications for
/// the current app session. Called once from `HomeShellScreen.build` (the
/// persistent authenticated shell) — `ref.listen` calls are safe to make
/// from a plain function like this as long as they run during a widget's
/// build with that widget's own `WidgetRef`, which is exactly how this is
/// invoked.
void watchBudgetAndBalanceAlerts(WidgetRef ref, AppLocalizations l10n) {
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);

  ref.listen(budgetProgressForMonthProvider(currentMonth), (previous, next) {
    _handleBudgetProgress(ref, l10n, next);
  });

  ref.listen(accountsProvider(false), (previous, next) {
    _handleAccounts(ref, l10n, next);
  });
}

void _handleBudgetProgress(
  WidgetRef ref,
  AppLocalizations l10n,
  AsyncValue<List<BudgetProgress>> next,
) {
  final progressList = next.value;
  if (progressList == null) return;
  if (!(ref.read(userPreferencesProvider).value?.notificationsEnabled ??
      false)) {
    return;
  }

  final alertedIds = ref.read(_alertedOverspentBudgetIdsProvider);
  final currentlyOverspentIds = <String>{};

  for (final progress in progressList) {
    final id = progress.budget.id;
    if (!progress.isOverspent) continue;
    currentlyOverspentIds.add(id);

    if (alertedIds.contains(id)) continue;
    ref.read(_alertedOverspentBudgetIdsProvider.notifier).add(id);
    showLocalNotification(
      ref.read(localNotificationsPluginProvider),
      id: 'budget-$id'.hashCode,
      title: l10n.budgetExceededNotificationTitle,
      body: l10n.budgetExceededNotificationBody(progress.category.name),
      channel: budgetAlertsChannel,
    );
  }

  // A budget that was alerted but is no longer overspent (limit raised,
  // spend reduced/deleted) can alert again if it goes over a second time.
  for (final id in alertedIds.difference(currentlyOverspentIds)) {
    ref.read(_alertedOverspentBudgetIdsProvider.notifier).remove(id);
  }
}

void _handleAccounts(
  WidgetRef ref,
  AppLocalizations l10n,
  AsyncValue<List<AccountEntity>> next,
) {
  final accounts = next.value;
  if (accounts == null) return;
  if (!(ref.read(userPreferencesProvider).value?.notificationsEnabled ??
      false)) {
    return;
  }

  final alertedIds = ref.read(_alertedNegativeAccountIdsProvider);
  final currentlyNegativeIds = <String>{};

  for (final account in accounts) {
    if (account.balance >= 0) continue;
    currentlyNegativeIds.add(account.id);

    if (alertedIds.contains(account.id)) continue;
    ref.read(_alertedNegativeAccountIdsProvider.notifier).add(account.id);
    showLocalNotification(
      ref.read(localNotificationsPluginProvider),
      id: 'account-${account.id}'.hashCode,
      title: l10n.negativeBalanceNotificationTitle,
      body: l10n.negativeBalanceNotificationBody(account.name),
      channel: budgetAlertsChannel,
    );
  }

  for (final id in alertedIds.difference(currentlyNegativeIds)) {
    ref.read(_alertedNegativeAccountIdsProvider.notifier).remove(id);
  }
}
