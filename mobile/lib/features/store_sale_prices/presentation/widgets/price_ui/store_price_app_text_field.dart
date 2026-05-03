import 'package:flutter/material.dart';

import 'store_price_design_tokens.dart';

/// Non-transparent text field: white fill, light border, blue focus — store forms.
class StorePriceAppTextField extends StatelessWidget {
  const StorePriceAppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      decoration: StorePriceDesignTokens.inputDecoration(label: label, hint: hint),
    );
  }
}
