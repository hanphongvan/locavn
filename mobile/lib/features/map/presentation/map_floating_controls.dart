import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'map_providers.dart';
import 'map_screen_palette.dart';

/// Nút zoom + vị trí nổi bên phải bản đồ.
class MapFloatingControls extends ConsumerWidget {
  const MapFloatingControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundMapButton(
          icon: Icons.add_rounded,
          onPressed: () async {
            final c = ref.read(mapGoogleMapControllerProvider);
            if (c == null) return;
            final z = await c.getZoomLevel();
            await c.animateCamera(CameraUpdate.zoomTo(z + 1));
          },
        ),
        const SizedBox(height: 10),
        _RoundMapButton(
          icon: Icons.remove_rounded,
          onPressed: () async {
            final c = ref.read(mapGoogleMapControllerProvider);
            if (c == null) return;
            final z = await c.getZoomLevel();
            await c.animateCamera(CameraUpdate.zoomTo((z - 1).clamp(3, 21)));
          },
        ),
        const SizedBox(height: 10),
        _RoundMapButton(
          icon: Icons.my_location_rounded,
          filled: true,
          onPressed: () async {
            final origin = await ref.read(mapSheetUserOriginProvider.future);
            if (!context.mounted) return;
            if (origin == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chưa có vị trí GPS.')),
              );
              return;
            }
            ref.read(mapCameraTargetProvider.notifier).state = origin;
          },
        ),
      ],
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  const _RoundMapButton({
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? MapScreenPalette.primaryBlue : MapScreenPalette.cardWhite;
    final fg = filled ? Colors.white : MapScreenPalette.textPrimary;
    return Material(
      color: bg,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: fg, size: 22),
        ),
      ),
    );
  }
}
