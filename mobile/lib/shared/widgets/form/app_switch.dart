import 'package:flutter/material.dart';

import 'app_form_theme.dart';

/// Label left, switch right — "Đặt làm xe mặc định" style row.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.label,
    required this.switchValue,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool switchValue;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppFormTheme.labelColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: switchValue,
            onChanged: enabled ? onChanged : null,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (!enabled) return Colors.grey.shade400;
              if (states.contains(WidgetState.selected)) return Colors.white;
              return Colors.grey.shade400;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (!enabled) return Colors.grey.shade300;
              if (states.contains(WidgetState.selected)) {
                return AppFormTheme.focusBorder.withValues(alpha: 0.42);
              }
              return Colors.grey.shade300;
            }),
            trackOutlineColor: WidgetStateProperty.all(AppFormTheme.border),
          ),
        ],
      ),
    );
  }
}
