import 'package:flutter/material.dart';

import '../../data/models/vehicle_dto.dart';
import '../my_vehicles_palette.dart';
import 'fuel_type_chip.dart';
import 'vehicle_image_thumb.dart';
import 'vehicle_menu_row.dart';
import 'vehicle_overflow.dart';
import 'vehicle_stats_row.dart';

/// Compact list card with overflow menu.
class VehicleListCard extends StatelessWidget {
  const VehicleListCard({
    super.key,
    required this.vehicle,
    required this.onMenuAction,
  });

  final VehicleDto vehicle;
  final void Function(VehicleOverflowAction action) onMenuAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: MyVehiclesPalette.cardWhite,
        borderRadius: BorderRadius.circular(MyVehiclesPalette.radiusMd),
        boxShadow: MyVehiclesPalette.cardShadow(context, blur: 18, y: 6),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VehicleImageThumb(
                imageUrl: vehicle.imageUrl,
                width: 95,
                height: 75,
                borderRadius: 14,
                showDefaultBadge: vehicle.isDefault,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.licensePlate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: MyVehiclesPalette.navy,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (vehicle.vehicleName != null && vehicle.vehicleName!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              vehicle.vehicleName!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: MyVehiclesPalette.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (vehicle.fuelType != null && vehicle.fuelType!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
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
                        child: PopupMenuButton<VehicleOverflowAction>(
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
                            if (!vehicle.isDefault)
                              const PopupMenuItem(
                                value: VehicleOverflowAction.setDefault,
                                child: VehicleMenuRow(icon: Icons.star_outline_rounded, title: 'Đặt mặc định'),
                              ),
                            PopupMenuItem(
                              value: VehicleOverflowAction.delete,
                              child: VehicleMenuRow(icon: Icons.delete_outline_rounded, title: 'Xóa', danger: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          VehicleStatsRow(
            fuelLevel: vehicle.fuelLevel,
            totalKm: vehicle.totalKm,
            year: vehicle.year,
            compact: true,
          ),
        ],
      ),
    );
  }
}
