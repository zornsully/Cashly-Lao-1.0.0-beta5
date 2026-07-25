import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/google_sign_in_button.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final l10n = AppLocalizations.of(context)!;
    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );

    if (!success && mounted) {
      final message =
          ref.read(authControllerProvider.notifier).failure?.message ??
          l10n.registerFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  Future<void> _continueWithGoogle() async {
    final l10n = AppLocalizations.of(context)!;
    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();

    if (!success && mounted) {
      final message =
          ref.read(authControllerProvider.notifier).failure?.message ??
          l10n.googleSignInFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final l10n = AppLocalizations.of(context)!;

    return AuthScaffold(
      title: l10n.registerTitle,
      subtitle: l10n.registerSubtitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: l10n.fullNameLabel,
                controller: _nameController,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.person_outline,
                validator: (value) => Validators.displayName(context, value),
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.emailLabel,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.email_outlined,
                validator: (value) => Validators.email(context, value),
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: AppSpacing.md),
              AppPasswordField(
                label: l10n.passwordLabel,
                controller: _passwordController,
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.password(context, value),
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: AppSpacing.md),
              AppPasswordField(
                label: l10n.confirmPasswordLabel,
                controller: _confirmPasswordController,
                textInputAction: TextInputAction.done,
                validator: (value) => Validators.confirmPassword(
                  context,
                  value,
                  _passwordController.text,
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: l10n.createAccountButton,
                isLoading: isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                l10n.orDividerLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GoogleSignInButton(
          label: l10n.continueWithGoogle,
          isLoading: isLoading,
          onPressed: _continueWithGoogle,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.haveAccountPrompt),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.login),
              child: Text(l10n.signIn),
            ),
          ],
        ),
      ],
    );
  }
}
