import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/platform_capabilities.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/google_sign_in_button.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final l10n = AppLocalizations.of(context)!;
    final success = await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!success && mounted) {
      final message =
          ref.read(authControllerProvider.notifier).failure?.message ??
          l10n.loginFailedMessage;
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
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                textInputAction: TextInputAction.done,
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.passwordRequiredError
                    : null,
                onFieldSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.password],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context.push(AppRoutes.forgotPassword),
                  child: Text(l10n.forgotPasswordLink),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: l10n.signIn,
                isLoading: isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
        if (AppPlatformCapabilities.supportsGoogleSignIn) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  l10n.orDividerLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        ],
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.noAccountPrompt),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => context.push(AppRoutes.register),
              child: Text(l10n.signUpLink),
            ),
          ],
        ),
      ],
    );
  }
}
