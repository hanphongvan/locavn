import 'package:flutter/material.dart';

import '../../data/models/vehicle_dto.dart';
import '../my_vehicles_palette.dart';
import 'fuel_type_chip.dart';
import 'vehicle_image_thumb.dart';
import 'vehicle_menu_row.dart';
import 'vehicle_overflow.dart';
import 'vehicle_stats_row.dart';

/// Highlighted default vehicle card.
class DefaultVehicleCard extends StatelessWidget {
  const DefaultVehicleCard({
    super.key,
    required this.vehicle,
    required this.onMenuAction,
  });

  final VehicleDto vehicle;
  final void Function(VehicleOverflowAction action) onMenuAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              MyVehiclesPalette.cardTint,
            ],
          ),
          borderRadius: BorderRadius.circular(MyVehiclesPalette.radiusLg),
          border: Border.all(color: MyVehiclesPalette.borderSoft, width: 1.2),
          boxShadow: MyVehiclesPalette.cardShadow(context, blur: 22, y: 10),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VehicleImageThumb(
                  imageUrl: vehicle.imageUrl,
                  width: 120,
                  height: 90,
                  borderRadius: 16,
                  showDefaultBadge: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 44),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.licensePlate,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: MyVehiclesPalette.navy,
                                letterSpacing: 0.8,
                                height: 1.1,
                              ),
                            ),
                            if (vehicle.vehicleName != null && vehicle.vehicleName!.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                vehicle.vehicleName!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: MyVehiclesPalette.muted,
                                ),
                              ),
                            ],
                            if (vehicle.fuelType != null && vehicle.fuelType!.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              FuelTypeChip(label: vehicle.fuelType!.trim()),
                            ],
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Material(
                          color: Colors.transparent,
                          child: _overflowMenu(context, includeSetDefault: false),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            VehicleStatsRow(
              fuelLevel: vehicle.fuelLevel,
              totalKm: vehicle.totalKm,
              year: vehicle.year,
              compact: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _overflowMenu(BuildContext context, {required bool includeSetDefault}) {
    return PopupMenuButton<VehicleOverflowAction>(
      icon: const Icon(Icons.more_horiz_rounded, color: MyVehiclesPalette.muted),
      tooltip: 'Tùy chọn',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: onMenuAction,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: VehicleOverflowAction.detail,
          child: VehicleMenuRow(icon: Icons.visibility_outlined, title: 'Xem chi tiết'),
        ),
        const PopupMenuItem(
          value: VehicleOverflowAction.edit,
          child: VehicleMenuRow(icon: Icons.edit_outlined, title: 'Chỉnh sửa'),
        ),
        if (includeSetDefault)
          const PopupMenuItem(
            value: VehicleOverflowAction.setDefault,
            child: VehicleMenuRow(icon: Icons.star_outline_rounded, title: 'Đặt mặc định'),
          ),
        PopupMenuItem(
          value: VehicleOverflowAction.delete,
          child: VehicleMenuRow(icon: Icons.delete_outline_rounded, title: 'Xóa', danger: true),
        ),
      ],
    );
  }
}
