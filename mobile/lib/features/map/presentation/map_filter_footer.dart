import 'package:flutter/material.dart';

import 'map_screen_palette.dart';

/// Nút Áp dụng (gradient) + Đặt lại (viền), cố định dưới panel.
class MapFilterFooter extends StatelessWidget {
  const MapFilterFooter({
    super.key,
    required this.onApply,
    required this.onReset,
  });

  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        );
    final resetStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: MapScreenPalette.filterPrimary,
          fontWeight: FontWeight.w700,
        );

    return Material(
      color: MapScreenPalette.cardWhite,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: onApply,
                      child: Ink(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              MapScreenPalette.filterPrimary,
                              MapScreenPalette.filterAccent,
                            ],
                          ),
                        ),
                        child: SizedBox(
                          height: 52,
                          child: Center(
                            child: Text('ÁP DỤNG', style: titleStyle),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MapScreenPalette.filterPrimary,
                    side: const BorderSide(color: MapScreenPalette.filterPrimary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('ĐẶT LẠI', style: resetStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
