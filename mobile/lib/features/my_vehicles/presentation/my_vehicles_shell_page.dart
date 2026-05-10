import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_console_log.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../fuel/presentation/fuel_tracking_providers.dart';
import '../data/models/vehicle_dto.dart';
import '../data/my_vehicles_api.dart';
import 'add_edit_vehicle_sheet.dart';
import 'my_vehicles_palette.dart';
import 'my_vehicles_providers.dart';
import 'vehicle_detail_sheet.dart';
import 'widgets/benefit_banner.dart';
import 'widgets/default_vehicle_card.dart';
import 'widgets/vehicle_header.dart';
import 'widgets/vehicle_list_card.dart';
import 'widgets/vehicle_overflow.dart';
import 'widgets/vehicle_section_title.dart';

/// Tab **Xe của tôi** — REST `/api/my-vehicles`.
class MyVehiclesShellPage extends ConsumerWidget {
  const MyVehiclesShellPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(myVehiclesListProvider);
    // Trang "Nhiên liệu" (fuelDashboardProvider) là consumer độc lập trong cùng shell tab —
    // không tự pickup invalidate qua dependency chain khi cả 2 tab đều alive. Invalidate
    // tường minh để CRUD vehicle (delete / setDefault / detail edit) propagate sang tab Fuel.
    ref.invalidate(fuelDashboardProvider);
    await ref.read(myVehiclesListProvider.future);
  }

  VehicleDto? _firstDefault(List<VehicleDto> items) {
    for (final e in items) {
      if (e.isDefault) return e;
    }
    return null;
  }

  List<VehicleDto> _otherVehicles(List<VehicleDto> items) {
    final def = _firstDefault(items);
    if (def == null) return items;
    return items.where((e) => e.id != def.id).toList();
  }

  Future<void> _onAdd(BuildContext context, WidgetRef ref) async {
    final ok = await showAddEditVehicleSheet(context);
    if (ok == true) {
      await _refresh(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm xe.')));
      }
    }
  }

  Future<void> _handleOverflow(
    BuildContext context,
    WidgetRef ref,
    VehicleDto vehicle,
    VehicleOverflowAction action,
    Future<void> Function() refresh,
  ) async {
    switch (action) {
      case VehicleOverflowAction.detail:
        await showVehicleDetailSheet(
          context,
          vehicle: vehicle,
          onChanged: refresh,
        );
        break;
      case VehicleOverflowAction.edit:
        final ok = await showAddEditVehicleSheet(context, existing: vehicle);
        if (ok == true) {
          await refresh();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật xe.')));
          }
        }
        break;
      case VehicleOverflowAction.setDefault:
        try {
          await ref.read(myVehiclesApiProvider).setDefaultVehicle(vehicle.id);
          await refresh();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đặt xe mặc định.')));
          }
        } catch (e) {
          final msg = e is ApiException ? e.message : e.toString();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        }
        break;
      case VehicleOverflowAction.delete:
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Xóa xe?'),
            content: Text('Bạn có chắc muốn xóa xe ${vehicle.licensePlate}?'),
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
        if (ok != true || !context.mounted) return;
        try {
          await ref.read(myVehiclesApiProvider).deleteVehicle(vehicle.id);
          await refresh();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa xe.')));
          }
        } catch (e) {
          final msg = e is ApiException ? e.message : e.toString();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myVehiclesListProvider);

    return Scaffold(
      backgroundColor: MyVehiclesPalette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VehicleHeader(onAdd: () => _onAdd(context, ref)),
            Expanded(
              child: async.when(
                loading: () => Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: MyVehiclesPalette.cardShadow(context),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: MyVehiclesPalette.primary),
                        SizedBox(height: 16),
                        Text(
                          'Đang tải danh sách xe…',
                          style: TextStyle(color: MyVehiclesPalette.muted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                error: (e, st) {
                  logAppError('Xe của tôi (myVehiclesListProvider)', e, st);
                  final message = e is ApiException ? e.message : e.toString();
                  return AppErrorState(
                    message: message,
                    onRetry: () => ref.invalidate(myVehiclesListProvider),
                  );
                },
                data: (data) {
                  Future<void> refresh() => _refresh(ref);
                  if (data.items.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 32),
                          _PremiumEmptyState(onAdd: () => _onAdd(context, ref)),
                          const SizedBox(height: 32),
                          const BenefitBanner(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  }

                  final def = _firstDefault(data.items);
                  final others = _otherVehicles(data.items);

                  return RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        if (def != null) ...[
                          const VehicleSectionTitle(text: 'Xe đang sử dụng'),
                          DefaultVehicleCard(
                            vehicle: def,
                            onMenuAction: (a) => _handleOverflow(context, ref, def, a, refresh),
                          ),
                        ],
                        if (others.isNotEmpty) ...[
                          const VehicleSectionTitle(text: 'Danh sách xe của bạn'),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                for (final v in others)
                                  VehicleListCard(
                                    vehicle: v,
                                    onMenuAction: (a) => _handleOverflow(context, ref, v, a, refresh),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const BenefitBanner(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumEmptyState extends StatelessWidget {
  const _PremiumEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MyVehiclesPalette.borderSoft.withValues(alpha: 0.7)),
        boxShadow: MyVehiclesPalette.cardShadow(context),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: MyVehiclesPalette.accentBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_car_rounded, size: 44, color: MyVehiclesPalette.accentBlue),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bạn chưa có xe nào',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: MyVehiclesPalette.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm xe để quản lý biển số, nhiên liệu và thông tin đi kèm.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: MyVehiclesPalette.muted.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: MyVehiclesPalette.addButtonGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: MyVehiclesPalette.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(18),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Thêm xe đầu tiên',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
