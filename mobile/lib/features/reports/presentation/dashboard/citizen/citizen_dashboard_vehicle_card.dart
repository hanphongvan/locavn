import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../my_vehicles/data/models/vehicle_dto.dart';
import '../../../../my_vehicles/presentation/my_vehicles_providers.dart';
import '../loca_dashboard_tokens.dart';

/// Citizen-styled vehicle card — same [myVehiclesListProvider] / selection rules as [DashboardVehicleCard].
class CitizenDashboardVehicleCard extends ConsumerWidget {
  const CitizenDashboardVehicleCard({super.key});

  static VehicleDto? _pickVehicle(List<VehicleDto> items) {
    if (items.isEmpty) return null;
    for (final v in items) {
      if (v.isDefault) return v;
    }
    return items.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myVehiclesListProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: async.when(
        loading: () => _CitizenCardShell(
          child: SizedBox(
            height: 132,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ),
        error: (_, _) => _CitizenCardShell(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Không tải được danh sách xe.',
                  style: TextStyle(
                    fontSize: 14,
                    color: LocaDashboardTokens.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(myVehiclesListProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (res) {
          final v = _pickVehicle(res.items);
          if (v == null) {
            return _CitizenCardShell(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xe đang dùng',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: LocaDashboardTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thêm hoặc chọn xe mặc định trong mục Xe của tôi.',
                          style: TextStyle(
                            fontSize: 13,
                            color: LocaDashboardTokens.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => context.go(AppRoute.myVehicles.path),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LocaDashboardTokens.primaryBlue,
                      side: const BorderSide(color: LocaDashboardTokens.primaryBlue, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Đổi xe'),
                  ),
                ],
              ),
            );
          }

          final model = (v.vehicleName?.trim().isNotEmpty ?? false) ? v.vehicleName!.trim() : '—';
          final fuel = (v.fuelType?.trim().isNotEmpty ?? false) ? v.fuelType!.trim() : null;
          final level = v.fuelLevel;

          return _CitizenCardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CitizenCarThumb(vehicle: v),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.licensePlate,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: 0.4,
                              color: LocaDashboardTokens.textPrimary,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            model,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: LocaDashboardTokens.textSecondary,
                            ),
                          ),
                          if (fuel != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: LocaDashboardTokens.accentGreen.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: LocaDashboardTokens.accentGreen.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                fuel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: LocaDashboardTokens.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => context.go(AppRoute.myVehicles.path),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LocaDashboardTokens.primaryBlue,
                        side: const BorderSide(color: LocaDashboardTokens.primaryBlue, width: 1.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      child: const Text('Đổi xe'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      size: 22,
                      color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        level != null ? 'Bình xăng: $level%' : 'Bình xăng: —',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: LocaDashboardTokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CitizenCardShell extends StatelessWidget {
  const _CitizenCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LocaDashboardTokens.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: LocaDashboardTokens.cardShadow(context),
        border: Border.all(color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _CitizenCarThumb extends StatelessWidget {
  const _CitizenCarThumb({required this.vehicle});

  final VehicleDto vehicle;

  @override
  Widget build(BuildContext context) {
    final url = vehicle.imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          width: 88,
          height: 88,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.directions_car_rounded,
        size: 40,
        color: LocaDashboardTokens.primaryBlue,
      ),
    );
  }
}
