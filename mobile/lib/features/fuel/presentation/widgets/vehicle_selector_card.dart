import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../my_vehicles/data/models/vehicle_dto.dart';
import '../../../my_vehicles/presentation/my_vehicles_providers.dart';
import '../../../my_vehicles/presentation/widgets/vehicle_image_thumb.dart';
import '../fuel_palette.dart';
import '../fuel_tracking_providers.dart';

/// Chọn xe — hiển thị theo [fuelDashboardProvider]; chạm để đổi xe (nếu có hơn 1 xe).
class VehicleSelectorCard extends ConsumerWidget {
  const VehicleSelectorCard({super.key});

  static const _fallbackName = 'Toyota Vios';
  static const _fallbackPlate = '30A-123.45';

  void _openPicker(BuildContext context, WidgetRef ref, List<VehicleDto> items, int activeId) {
    if (items.length <= 1) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final v in items)
                ListTile(
                  leading: VehicleImageThumb(imageUrl: v.imageUrl, width: 44, height: 44, borderRadius: 10),
                  title: Text(
                    (v.vehicleName?.trim().isNotEmpty ?? false) ? v.vehicleName!.trim() : v.licensePlate,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(v.licensePlate),
                  trailing: v.id == activeId ? const Icon(Icons.check_rounded, color: FuelPalette.primaryBlue) : null,
                  onTap: () {
                    ref.read(fuelSelectedVehicleIdProvider.notifier).state = v.id;
                    ref.invalidate(fuelDashboardProvider);
                    Navigator.of(ctx).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _content(
    BuildContext context, {
    required String name,
    required String plate,
    String? imageUrl,
    bool loading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FuelPalette.cardWhite,
        borderRadius: BorderRadius.circular(FuelPalette.radiusLg),
        border: Border.all(color: FuelPalette.border),
        boxShadow: FuelPalette.cardShadow(context),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: loading
                ? Container(
                    width: 64,
                    height: 64,
                    color: FuelPalette.border.withValues(alpha: 0.5),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: FuelPalette.primaryBlue),
                      ),
                    ),
                  )
                : VehicleImageThumb(imageUrl: imageUrl, width: 64, height: 64, borderRadius: 14),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: FuelPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: FuelPalette.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FuelPalette.primaryBlue.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    plate,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: FuelPalette.primaryBlue,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: FuelPalette.textSecondary, size: 28),
        ],
      ),
    );
  }

  VehicleDto? _pickVehicle(List<VehicleDto> items) {
    if (items.isEmpty) {
      return null;
    }
    for (final e in items) {
      if (e.isDefault) {
        return e;
      }
    }
    return items.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(fuelDashboardProvider);
    final vehiclesAsync = ref.watch(myVehiclesListProvider);

    return dash.when(
      data: (vm) {
        if (!vm.hasVehicle) {
          return _content(context, name: 'Chưa có xe', plate: 'Thêm xe tại tab Xe của tôi', imageUrl: null);
        }
        final list = vehiclesAsync.valueOrNull?.items;
        final VoidCallback? onTap = (list != null && list.length > 1)
            ? () => _openPicker(context, ref, list, vm.activeVehicleId)
            : null;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(FuelPalette.radiusLg),
            onTap: onTap,
            child: _content(context, name: vm.vehicleName, plate: vm.licensePlate, imageUrl: vm.imageUrl),
          ),
        );
      },
      loading: () => _content(context, name: _fallbackName, plate: _fallbackPlate, imageUrl: null, loading: true),
      error: (_, _) => vehiclesAsync.when(
        data: (d) {
          final v = _pickVehicle(d.items);
          if (v == null) {
            return _content(context, name: _fallbackName, plate: _fallbackPlate, imageUrl: null);
          }
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(FuelPalette.radiusLg),
              onTap: d.items.length > 1 ? () => _openPicker(context, ref, d.items, v.id) : null,
              child: _content(
                context,
                name: (v.vehicleName?.trim().isNotEmpty ?? false) ? v.vehicleName!.trim() : _fallbackName,
                plate: v.licensePlate,
                imageUrl: v.imageUrl,
              ),
            ),
          );
        },
        loading: () => _content(context, name: _fallbackName, plate: _fallbackPlate, imageUrl: null, loading: true),
        error: (_, _) => _content(context, name: _fallbackName, plate: _fallbackPlate, imageUrl: null),
      ),
    );
  }
}
