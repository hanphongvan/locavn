import 'package:flutter/material.dart';

import '../../../../stations/presentation/station_review/station_review_compose_theme.dart';
import '../violation_options.dart';

/// Multi-select violation cards (tap to toggle).
class ViolationTypeSelector extends StatelessWidget {
  const ViolationTypeSelector({
    super.key,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn nội dung vi phạm',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: StationReviewComposeTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Có thể chọn nhiều mục',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...kViolationTypeOptions.map((o) {
          final selected = selectedIds.contains(o.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final next = Set<String>.from(selectedIds);
                  if (selected) {
                    next.remove(o.id);
                  } else {
                    next.add(o.id);
                  }
                  onSelectionChanged(next);
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? StationReviewComposeTheme.primary.withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? StationReviewComposeTheme.primary
                          : theme.colorScheme.outlineVariant,
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        o.icon,
                        size: 26,
                        color: selected
                            ? StationReviewComposeTheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          o.label,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: selected
                                ? StationReviewComposeTheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: StationReviewComposeTheme.accent,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
