import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'app_text_field.dart';

/// A password [AppTextField] with a built-in visibility toggle. Used by
/// login, register, and (later) change-password / PIN-related screens.
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    required this.label,
    super.key,
    this.controller,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppTextField(
      label: widget.label,
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
        tooltip: _obscure
            ? l10n.showPasswordTooltip
            : l10n.hidePasswordTooltip,
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
