import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../data/models/fuel_tracking_models.dart';
import '../../my_vehicles/presentation/my_vehicles_providers.dart';
import '../voice/fuel_voice_button.dart';
import 'fuel_palette.dart';
import 'fuel_screen.dart';
import 'fuel_tracking_providers.dart';
import 'widgets/add_fuel_button.dart';
import 'widgets/fuel_monthly_consumption_sheet.dart';
import 'widgets/fuel_screen_header.dart';
import 'widgets/fuel_screen_skeleton.dart';

/// Tab **Nhiên liệu** — dữ liệu từ `/api/fuel/*` (stored procedures).
class FuelShellPage extends ConsumerStatefulWidget {
  const FuelShellPage({super.key});

  @override
  ConsumerState<FuelShellPage> createState() => _FuelShellPageState();
}

class _FuelShellPageState extends ConsumerState<FuelShellPage> {
  void _snack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fuelDashboardProvider, (prev, next) {
      if (prev?.hasError != true && next.hasError) {
        _snack('Không tải được dữ liệu nhiên liệu. Vui lòng thử lại.');
      }
    });

    final dash = ref.watch(fuelDashboardProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              FuelPalette.background,
              Color(0xFFE8F2FC),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FuelScreenHeader(),
              Expanded(
                child: RefreshIndicator(
                  color: FuelPalette.primaryBlue,
                  onRefresh: () async {
                    ref.invalidate(myVehiclesListProvider);
                    ref.invalidate(fuelDashboardProvider);
                    await ref.read(fuelDashboardProvider.future);
                  },
                  child: dash.when(
                    data: (vm) => FuelScreen(
                      summary: vm.summary,
                      insight: vm.insight,
                      transactions: vm.transactions,
                      bottomInset: bottomInset,
                      onSeeInsightDetail: () {
                        final vm = ref.read(fuelDashboardProvider).valueOrNull;
                        if (vm == null || !vm.hasVehicle) {
                          _snack('Vui lòng thêm xe để xem biểu đồ tiêu thụ.');
                          return;
                        }
                        final label =
                            '${vm.vehicleName.trim().isEmpty ? 'Xe' : vm.vehicleName.trim()} · ${vm.licensePlate}';
                        showFuelMonthlyConsumptionSheet(
                          context: context,
                          ref: ref,
                          vehicleId: vm.activeVehicleId,
                          vehicleLabel: label,
                        );
                      },
                      onSeeAllHistory: () async {
                        final vm = ref.read(fuelDashboardProvider).valueOrNull;
                        if (vm == null || !vm.hasVehicle) {
                          _snack('Vui lòng thêm xe trước khi xem lịch sử.');
                          return;
                        }
                        final changed = await context.push<bool>(
                          '${AppRoute.fuelTransactionsHistory.path}?vehicleId=${vm.activeVehicleId}',
                        );
                        if (changed == true && mounted) {
                          ref.invalidate(fuelDashboardProvider);
                        }
                      },
                      onTransactionTap: (tx) async {
                        final vm = ref.read(fuelDashboardProvider).valueOrNull;
                        if (vm == null || !vm.hasVehicle) {
                          _snack('Vui lòng thêm xe trước khi sửa giao dịch.');
                          return;
                        }
                        final id = int.tryParse(tx.id) ?? 0;
                        if (id < 1) {
                          _snack('Không xác định được giao dịch.');
                          return;
                        }
                        final prefill = FuelTransactionEditPrefill(
                          transactionId: id,
                          amountDong: tx.amountDong,
                          odometerKm: tx.odometerKm,
                          note: tx.note,
                          transactionDate: tx.transactionDate,
                        );
                        final ok = await context.push<bool>(
                          '${AppRoute.addFuelTransaction.path}?vehicleId=${vm.activeVehicleId}&editId=$id',
                          extra: prefill,
                        );
                        if (ok == true && mounted) {
                          ref.invalidate(fuelDashboardProvider);
                        }
                      },
                    ),
                    loading: () => FuelScreenSkeleton(bottomInset: bottomInset),
                    error: (_, _) => FuelScreenSkeleton(bottomInset: bottomInset),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomInset),
                child: Row(
                  children: [
                    Expanded(
                      child: AddFuelButton(
                        onPressed: () async {
                          final vm = ref.read(fuelDashboardProvider).valueOrNull;
                          if (vm == null || !vm.hasVehicle) {
                            _snack('Vui lòng thêm xe trước khi ghi lần đổ xăng.');
                            return;
                          }
                          final ok = await context.push<bool>(
                            '${AppRoute.addFuelTransaction.path}?vehicleId=${vm.activeVehicleId}',
                          );
                          if (ok == true && mounted) {
                            ref.invalidate(fuelDashboardProvider);
                          }
                        },
                      ),
                    ),
                    Consumer(builder: (context, ref, _) {
                      final vm = ref.watch(fuelDashboardProvider).valueOrNull;
                      return FuelVoiceButton(vehicleId: vm?.activeVehicleId);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
