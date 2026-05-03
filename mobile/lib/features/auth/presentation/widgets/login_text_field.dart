import 'package:flutter/material.dart';

import 'login_screen_theme.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.label,
    this.hint,
    required this.prefixIcon,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.suffix,
  });

  final String label;
  /// When null or empty, no placeholder is shown.
  final String? hint;
  final IconData prefixIcon;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool enabled;
  final void Function(String)? onFieldSubmitted;
  final VoidCallback? onEditingComplete;
  final Widget? suffix;

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(LoginScreenTheme.controlRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final border = _border(LoginScreenTheme.fieldBorder);
    final focusBorder = _border(LoginScreenTheme.gradientStart, width: 2);
    final errorBorder = _border(Theme.of(context).colorScheme.error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(prefixIcon, size: 20, color: LoginScreenTheme.gradientStart),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: LoginScreenTheme.titleBlue,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          obscureText: obscureText,
          enabled: enabled,
          onFieldSubmitted: onFieldSubmitted,
          onEditingComplete: onEditingComplete,
          autocorrect: false,
          enableSuggestions: false,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: LoginScreenTheme.titleBlue,
              ),
          cursorColor: LoginScreenTheme.gradientStart,
          decoration: InputDecoration(
            hintText: hint?.isNotEmpty == true ? hint : null,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LoginScreenTheme.titleBlue.withValues(alpha: 0.38),
                ),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: border,
            enabledBorder: border,
            focusedBorder: focusBorder,
            errorBorder: errorBorder,
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LoginScreenTheme.controlRadius),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
            ),
            disabledBorder: border,
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ),
      ],
    );
  }
}
