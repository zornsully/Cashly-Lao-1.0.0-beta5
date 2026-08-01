import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_language.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/constants/app_theme_mode.dart';
import '../../../../core/providers/local_notifications_providers.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/cashly_logo_mark.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/settings_controller.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _changeThemeMode(
    BuildContext context,
    WidgetRef ref,
    AppThemeModePreference mode,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final success = await ref
        .read(settingsControllerProvider.notifier)
        .updateThemeMode(mode);

    if (!context.mounted || success) return;
    final message =
        ref.read(settingsControllerProvider.notifier).failure?.message ??
        l10n.themeUpdateFailedMessage;
    AppSnackbar.showError(context, message);
  }

  Future<void> _changeDefaultCurrency(
    BuildContext context,
    WidgetRef ref,
    AppCurrency currency,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final success = await ref
        .read(settingsControllerProvider.notifier)
        .updateDefaultCurrency(currency.code);

    if (!context.mounted || success) return;
    final message =
        ref.read(settingsControllerProvider.notifier).failure?.message ??
        l10n.defaultCurrencyUpdateFailedMessage;
    AppSnackbar.showError(context, message);
  }

  Future<void> _changeLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLanguage language,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final success = await ref
        .read(settingsControllerProvider.notifier)
        .updateLanguage(language);

    if (!context.mounted || success) return;
    final message =
        ref.read(settingsControllerProvider.notifier).failure?.message ??
        l10n.languageUpdateFailedMessage;
    AppSnackbar.showError(context, message);
  }

  Future<void> _changeAppLockEnabled(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    if (!enabled) {
      final confirmed = await AppDialog.confirm(
        context,
        title: l10n.disableAppLockTitle,
        message: l10n.disableAppLockMessage,
        confirmLabel: l10n.turnOffButton,
        cancelLabel: l10n.cancel,
      );
      if (!confirmed || !context.mounted) return;
    }

    final success = await ref
        .read(settingsControllerProvider.notifier)
        .updateAppLockEnabled(enabled);

    if (!context.mounted || success) return;
    final message =
        ref.read(settingsControllerProvider.notifier).failure?.message ??
        l10n.appLockUpdateFailedMessage;
    AppSnackbar.showError(context, message);
  }

  Future<void> _changeNotificationsEnabled(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    if (enabled) {
      final granted = await requestNotificationPermission(
        ref.read(localNotificationsPluginProvider),
      );
      if (!granted) {
        if (!context.mounted) return;
        AppSnackbar.showError(
          context,
          l10n.notificationsPermissionDeniedMessage,
        );
        return;
      }
    }

    if (!context.mounted) return;
    final success = await ref
        .read(settingsControllerProvider.notifier)
        .updateNotificationsEnabled(enabled);

    if (!context.mounted || success) return;
    final message =
        ref.read(settingsControllerProvider.notifier).failure?.message ??
        l10n.notificationsUpdateFailedMessage;
    AppSnackbar.showError(context, message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(userPreferencesProvider);
    final isSaving = ref.watch(settingsControllerProvider).isLoading;
    final isAppLockSupported =
        ref.watch(isAppLockSupportedProvider).value ?? false;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ResponsiveCenter(
        child: preferencesAsync.when(
          loading: () => const AppLoadingIndicator(),
          error: (error, _) => ErrorView(message: '$error'),
          data: (preferences) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _SectionHeader(title: l10n.accountSectionTitle),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  leading: Icon(
                    AppSymbols.personOutline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(l10n.manageAccountLabel),
                  subtitle: Text(l10n.manageAccountHelperMessage),
                  trailing: const Icon(AppSymbols.chevronRight),
                  onTap: () => context.push(AppRoutes.settingsAccount),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(title: l10n.appearanceSectionTitle),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.themeLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SegmentedButton<AppThemeModePreference>(
                        segments: [
                          ButtonSegment(
                            value: AppThemeModePreference.system,
                            label: Text(l10n.themeSystemLabel),
                            icon: const Icon(AppSymbols.brightnessAuto),
                          ),
                          ButtonSegment(
                            value: AppThemeModePreference.light,
                            label: Text(l10n.themeLightLabel),
                            icon: const Icon(AppSymbols.lightMode),
                          ),
                          ButtonSegment(
                            value: AppThemeModePreference.dark,
                            label: Text(l10n.themeDarkLabel),
                            icon: const Icon(AppSymbols.darkMode),
                          ),
                        ],
                        selected: {preferences.themeMode},
                        onSelectionChanged: isSaving
                            ? null
                            : (selection) => _changeThemeMode(
                                context,
                                ref,
                                selection.first,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!kIsWeb) ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(title: l10n.securitySectionTitle),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.appLockToggleLabel),
                          subtitle: Text(
                            isAppLockSupported
                                ? l10n.appLockToggleHelperMessage
                                : l10n.appLockUnsupportedMessage,
                          ),
                          value: preferences.appLockEnabled,
                          onChanged: isSaving || !isAppLockSupported
                              ? null
                              : (value) =>
                                    _changeAppLockEnabled(context, ref, value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(title: l10n.notificationsSectionTitle),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.notificationsToggleLabel),
                      subtitle: Text(l10n.notificationsToggleHelperMessage),
                      value: preferences.notificationsEnabled,
                      onChanged: isSaving
                          ? null
                          : (value) => _changeNotificationsEnabled(
                              context,
                              ref,
                              value,
                            ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.securityUnavailableOnWebMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(title: l10n.languageSectionTitle),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SegmentedButton<AppLanguage>(
                    segments: [
                      ButtonSegment(
                        value: AppLanguage.english,
                        label: Text(l10n.languageEnglish),
                      ),
                      ButtonSegment(
                        value: AppLanguage.lao,
                        label: Text(l10n.languageLao),
                      ),
                    ],
                    selected: {preferences.language},
                    onSelectionChanged: isSaving
                        ? null
                        : (selection) =>
                              _changeLanguage(context, ref, selection.first),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(title: l10n.defaultsSectionTitle),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.defaultCurrencyLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        l10n.defaultCurrencyHelperMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<AppCurrency>(
                        initialValue: SupportedCurrencies.byCode(
                          preferences.defaultCurrencyCode,
                        ),
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.currencyLabel,
                        ),
                        items: [
                          for (final currency in SupportedCurrencies.all)
                            DropdownMenuItem(
                              value: currency,
                              child: Text(
                                l10n.currencyDisplayFormat(
                                  currency.code,
                                  currency.name,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  _changeDefaultCurrency(context, ref, value);
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(title: l10n.aboutSectionTitle),
              Card(
                child: Column(
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final packageInfo = ref.watch(packageInfoProvider);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          leading: const CashlyLogoMark(size: 36),
                          title: Text(l10n.appName),
                          subtitle: switch (packageInfo) {
                            AsyncData(:final value) => Text(
                              l10n.appVersionLabel(
                                '${value.version}+${value.buildNumber}',
                              ),
                            ),
                            _ => null,
                          },
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      title: Text(l10n.privacyPolicyLabel),
                      trailing: const Icon(AppSymbols.chevronRight),
                      onTap: () => context.push(AppRoutes.privacy),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      title: Text(l10n.termsOfServiceLabel),
                      trailing: const Icon(AppSymbols.chevronRight),
                      onTap: () => context.push(AppRoutes.terms),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
