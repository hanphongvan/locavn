import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_form_theme.dart';

/// Label-above, filled text field (not flat) — consistent with login-style forms.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.prefixIcon,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
  });

  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = AppFormTheme.outlineBorder(AppFormTheme.border);
    final focusBorder = AppFormTheme.outlineBorder(AppFormTheme.focusBorder, width: 2);
    final errorBorder = AppFormTheme.outlineBorder(scheme.error);
    final focused = _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (widget.prefixIcon != null) ...[
              Icon(widget.prefixIcon, size: 20, color: AppFormTheme.focusBorder),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppFormTheme.labelColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppFormTheme.fieldRadius),
            boxShadow: focused ? AppFormTheme.focusShadow : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppFormTheme.fieldRadius),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              validator: widget.validator,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              textCapitalization: widget.textCapitalization,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              onChanged: widget.onChanged,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppFormTheme.labelColor,
                    fontWeight: FontWeight.w500,
                  ),
              cursorColor: AppFormTheme.focusBorder,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppFormTheme.hintColor,
                      fontWeight: FontWeight.w400,
                    ),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: AppFormTheme.fieldPadding,
                border: border,
                enabledBorder: border,
                focusedBorder: focusBorder,
                errorBorder: errorBorder,
                focusedErrorBorder: AppFormTheme.outlineBorder(scheme.error, width: 2),
                disabledBorder: border,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
