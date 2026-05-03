import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/models/vehicle_dto.dart';
import '../data/my_vehicles_api.dart';
import 'my_vehicles_palette.dart';
import 'add_edit_vehicle_sheet.dart';
import 'widgets/vehicle_image_thumb.dart';

Future<void> showVehicleDetailSheet(
  BuildContext context, {
  required VehicleDto vehicle,
  required Future<void> Function() onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => VehicleDetailSheet(
      vehicle: vehicle,
      onChanged: onChanged,
    ),
  );
}

class VehicleDetailSheet extends ConsumerStatefulWidget {
  const VehicleDetailSheet({
    super.key,
    required this.vehicle,
    required this.onChanged,
  });

  final VehicleDto vehicle;
  final Future<void> Function() onChanged;

  @override
  ConsumerState<VehicleDetailSheet> createState() => _VehicleDetailSheetState();
}

class _VehicleDetailSheetState extends ConsumerState<VehicleDetailSheet> {
  bool _busy = false;

  Future<void> _setDefault() async {
    setState(() => _busy = true);
    try {
      await ref.read(myVehiclesApiProvider).setDefaultVehicle(widget.vehicle.id);
      if (mounted) Navigator.of(context).pop();
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đặt xe mặc định.')),
        );
      }
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa xe?'),
        content: Text('Xóa xe ${widget.vehicle.licensePlate}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(myVehiclesApiProvider).deleteVehicle(widget.vehicle.id);
      if (mounted) Navigator.of(context).pop();
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa xe.')),
        );
      }
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    Navigator.of(context).pop();
    final changed = await showAddEditVehicleSheet(context, existing: widget.vehicle);
    if (changed == true) {
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật xe.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: MyVehiclesPalette.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(MyVehiclesPalette.radiusLg)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Chi tiết xe',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: MyVehiclesPalette.primary,
                    ),
              ),
              const SizedBox(height: 14),
              Center(
                child: VehicleImageThumb(
                  imageUrl: v.imageUrl,
                  width: 200,
                  height: 120,
                  borderRadius: 16,
                  showDefaultBadge: v.isDefault,
                ),
              ),
              const SizedBox(height: 16),
              _detailRow(Icons.confirmation_number_outlined, 'Biển số', v.licensePlate),
              _detailRow(Icons.directions_car_outlined, 'Tên xe', v.vehicleName ?? '—'),
              _detailRow(Icons.local_gas_station_outlined, 'Nhiên liệu', v.fuelType ?? '—'),
              _detailRow(Icons.opacity_outlined, 'Mức xăng', v.fuelLevel != null ? '${v.fuelLevel}%' : '—'),
              _detailRow(Icons.speed_outlined, 'Tổng km', v.totalKm?.toString() ?? '—'),
              _detailRow(Icons.calendar_today_outlined, 'Năm SX', v.year?.toString() ?? '—'),
              const SizedBox(height: 20),
              if (_busy)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              else ...[
                OutlinedButton.icon(
                  onPressed: _edit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Chỉnh sửa'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: v.isDefault ? null : _setDefault,
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Đặt làm mặc định'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: MyVehiclesPalette.primary.withValues(alpha: 0.85)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
