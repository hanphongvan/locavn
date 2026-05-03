import 'package:flutter/material.dart';

import '../my_vehicles_palette.dart';

/// Rounded-rectangle vehicle image or car fallback.
///
/// [showDefaultBadge] — icon sao trên góc phải ảnh (xe mặc định).
class VehicleImageThumb extends StatelessWidget {
  const VehicleImageThumb({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 14,
    this.showDefaultBadge = false,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final bool showDefaultBadge;

  static double _badgeOuter(double w) => (w * 0.26).clamp(24.0, 36.0);

  Widget _defaultBadge() {
    final outer = _badgeOuter(width);
    final icon = outer * 0.55;
    return Container(
      width: outer,
      height: outer,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: MyVehiclesPalette.borderSoft.withValues(alpha: 0.85)),
      ),
      child: Icon(
        Icons.star_rounded,
        size: icon,
        color: const Color(0xFFFFB020),
      ),
    );
  }

  Widget _fallbackFill() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MyVehiclesPalette.accentBlue.withValues(alpha: 0.08),
        border: Border.all(color: MyVehiclesPalette.borderSoft.withValues(alpha: 0.6)),
      ),
      child: Center(
        child: Icon(
          Icons.directions_car_rounded,
          size: (width * 0.32).clamp(28.0, 44.0),
          color: MyVehiclesPalette.primary.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = imageUrl?.trim();
    final radius = BorderRadius.circular(borderRadius);

    final Widget imageLayer = u != null && u.isNotEmpty
        ? Image.network(
            u,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallbackFill(),
          )
        : _fallbackFill();

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: showDefaultBadge
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(child: imageLayer),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _defaultBadge(),
                  ),
                ],
              )
            : imageLayer,
      ),
    );
  }
}
