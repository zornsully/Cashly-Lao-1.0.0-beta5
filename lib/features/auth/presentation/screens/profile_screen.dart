import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
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

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _EditDisplayNameDialog(l10n: l10n, initialName: user.displayName),
    );

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

    // `null` means cancelled; a non-null string means confirmed (empty for
    // a Google-only account, which has no password field to submit).
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _DeleteAccountDialog(
        l10n: l10n,
        hasPasswordProvider: hasPasswordProvider,
      ),
    );

    if (password == null || !context.mounted) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount(password: hasPasswordProvider ? password : null);

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
            icon: const Icon(AppSymbols.settings),
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
                          icon: const Icon(AppSymbols.edit, size: 20),
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
                            ? AppSymbols.verified
                            : AppSymbols.warningAmberRounded,
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
                        leading: const Icon(AppSymbols.calendarToday),
                        title: Text(l10n.memberSinceLabel),
                        subtitle: Text(
                          DateFormat.yMMMMd().format(user.createdAt),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    DestructiveButton(
                      label: l10n.signOutButton,
                      icon: AppSymbols.logout,
                      onPressed: () => _logout(context, ref, l10n),
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DestructiveButton(
                      label: l10n.deleteAccountButtonLabel,
                      icon: AppSymbols.deleteForever,
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

/// Owns its own `TextEditingController`, disposed only when Flutter
/// actually removes this widget's Element from the tree -- i.e. only
/// once the dialog's *own* exit transition has fully finished, not the
/// moment `Navigator.pop()` is called. A controller created and disposed
/// manually around a `showDialog` call (the previous shape of this
/// dialog) gets disposed the instant `pop()` returns, but the dialog's
/// route keeps animating out for several more frames after that -- its
/// still-live `TextFormField` reacts to that transition and touches the
/// now-disposed controller, throwing "A TextEditingController was used
/// after being disposed." Confirmed via `integration_test/
/// app_flow_test.dart`'s account-deletion step, reproducible with no
/// prior app state at all (register, then immediately delete).
class _EditDisplayNameDialog extends StatefulWidget {
  const _EditDisplayNameDialog({required this.l10n, required this.initialName});

  final AppLocalizations l10n;
  final String? initialName;

  @override
  State<_EditDisplayNameDialog> createState() => _EditDisplayNameDialogState();
}

class _EditDisplayNameDialogState extends State<_EditDisplayNameDialog> {
  late final _controller = TextEditingController(
    text: widget.initialName ?? '',
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.editNameDialogTitle),
      content: Form(
        key: _formKey,
        // AlertDialog sizes its content with an internal IntrinsicWidth,
        // which doesn't compose reliably with a TextFormField descendant
        // -- a well-known Flutter/Material gotcha. Giving the content an
        // explicit width hands IntrinsicWidth a concrete value instead of
        // asking it to measure the field intrinsically.
        child: SizedBox(
          width: double.maxFinite,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.fullNameLabel),
            validator: (value) => Validators.displayName(context, value),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// See `_EditDisplayNameDialog`'s doc comment for why this dialog owns
/// its own controller as a `StatefulWidget` rather than a manually
/// disposed local variable -- this is the dialog where the bug was
/// actually found. Pops the entered password directly (an empty string
/// for a Google-only account, which has no password field) rather than
/// having the caller read a controller's `.text` after the dialog
/// closes, so nothing outside this widget needs to know about the
/// controller at all.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({
    required this.l10n,
    required this.hasPasswordProvider,
  });

  final AppLocalizations l10n;
  final bool hasPasswordProvider;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.deleteUserAccountTitle),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.hasPasswordProvider
                    ? l10n.deleteUserAccountMessageWithPassword
                    : l10n.deleteUserAccountMessageGoogle,
              ),
              if (widget.hasPasswordProvider) ...[
                const SizedBox(height: AppSpacing.md),
                AppPasswordField(
                  label: l10n.confirmYourPasswordLabel,
                  controller: _passwordController,
                  autofillHints: const [],
                  validator: (value) => (value == null || value.isEmpty)
                      ? l10n.passwordRequiredError
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () {
            if (!widget.hasPasswordProvider ||
                (_formKey.currentState?.validate() ?? false)) {
              Navigator.of(
                context,
              ).pop(widget.hasPasswordProvider ? _passwordController.text : '');
            }
          },
          child: Text(l10n.deleteAccountConfirmButton),
        ),
      ],
    );
  }
}
