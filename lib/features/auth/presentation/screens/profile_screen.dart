import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_controller.dart';
import '../providers/auth_providers.dart';

/// Post-login landing screen for Sprint 1. Once the Dashboard (Sprint 2)
/// ships, this becomes the "Profile" tab of the main navigation shell
/// rather than the initial route.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editDisplayName(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: user.displayName ?? '');
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editNameDialogTitle),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.fullNameLabel),
            validator: (value) => Validators.displayName(dialogContext, value),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    controller.dispose();
    if (newName == null || !context.mounted) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .updateDisplayName(newName);

    if (!context.mounted) return;

    if (success) {
      AppSnackbar.showSuccess(context, l10n.nameUpdatedMessage);
    } else {
      final message =
          ref.read(authControllerProvider.notifier).failure?.message ??
          l10n.nameUpdateFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final hasPasswordProvider = user.hasPasswordProvider;
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteUserAccountTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasPasswordProvider
                    ? l10n.deleteUserAccountMessageWithPassword
                    : l10n.deleteUserAccountMessageGoogle,
              ),
              if (hasPasswordProvider) ...[
                const SizedBox(height: AppSpacing.md),
                AppPasswordField(
                  label: l10n.confirmYourPasswordLabel,
                  controller: passwordController,
                  autofillHints: const [],
                  validator: (value) => (value == null || value.isEmpty)
                      ? l10n.passwordRequiredError
                      : null,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () {
              if (!hasPasswordProvider ||
                  (formKey.currentState?.validate() ?? false)) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: Text(l10n.deleteAccountConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      passwordController.dispose();
      return;
    }

    final password = hasPasswordProvider ? passwordController.text : null;
    passwordController.dispose();

    final success = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount(password: password);

    if (!context.mounted || success) return;
    final message =
        ref.read(authControllerProvider.notifier).failure?.message ??
        l10n.deleteUserAccountFailedMessage;
    AppSnackbar.showError(context, message);
  }

  Future<void> _logout(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final success = await ref.read(authControllerProvider.notifier).logout();

    if (!context.mounted || success) return;
    final failure = ref.read(authControllerProvider.notifier).failure;
    final message =
        failure is AuthFailure && failure.code == 'logout-pending-writes'
        ? l10n.logoutPendingWritesMessage
        : failure?.message ?? l10n.logoutFailedMessage;
    AppSnackbar.showError(context, message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateChangesProvider);
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => ErrorView(message: '$error'),
        data: (user) {
          if (user == null) return const AppLoadingIndicator();

          final theme = Theme.of(context);
          final initials = (user.displayName?.trim().isNotEmpty ?? false)
              ? user.displayName!.trim()[0].toUpperCase()
              : user.email[0].toUpperCase();

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        initials,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName?.isNotEmpty == true
                                ? user.displayName!
                                : l10n.addYourNameLabel,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: l10n.editDisplayNameTooltip,
                          onPressed: () => _editDisplayName(context, ref, user),
                        ),
                      ],
                    ),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Chip(
                      avatar: Icon(
                        user.emailVerified
                            ? Icons.verified_outlined
                            : Icons.warning_amber_outlined,
                        size: 18,
                        color: user.emailVerified
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                      label: Text(
                        user.emailVerified
                            ? l10n.emailVerifiedLabel
                            : l10n.notVerifiedLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text(l10n.memberSinceLabel),
                        subtitle: Text(
                          DateFormat.yMMMMd().format(user.createdAt),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    DestructiveButton(
                      label: l10n.signOutButton,
                      icon: Icons.logout,
                      onPressed: () => _logout(context, ref, l10n),
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DestructiveButton(
                      label: l10n.deleteAccountButtonLabel,
                      icon: Icons.delete_forever_outlined,
                      variant: DestructiveButtonVariant.text,
                      onPressed: () =>
                          _confirmDeleteAccount(context, ref, user),
                      isLoading: isLoading,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
