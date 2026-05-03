import 'package:flutter/material.dart';

import 'app_form_theme.dart';

/// Styled dropdown (non-flat) with trailing chevron — matches [AppTextField] chrome.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    this.prefixIcon,
    required this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.hint,
  });

  final String label;
  final IconData? prefixIcon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = AppFormTheme.outlineBorder(AppFormTheme.border);
    final focusBorder = AppFormTheme.outlineBorder(AppFormTheme.focusBorder, width: 2);
    final errorBorder = AppFormTheme.outlineBorder(scheme.error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, size: 20, color: AppFormTheme.focusBorder),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppFormTheme.labelColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          // Controlled field; `value` still required until SDK removes it.
          // ignore: deprecated_member_use
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: enabled ? AppFormTheme.labelColor : AppFormTheme.hintColor,
          ),
          dropdownColor: Colors.white,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppFormTheme.labelColor,
                fontWeight: FontWeight.w500,
              ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppFormTheme.hintColor,
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
      ],
    );
  }
}
