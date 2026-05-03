import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../my_vehicles/data/models/my_vehicles_list_response.dart';
import '../../my_vehicles/data/models/vehicle_dto.dart';
import '../../my_vehicles/presentation/my_vehicles_providers.dart';
import '../data/fuel_api.dart';
import '../data/models/fuel_api_dtos.dart';
import '../data/models/fuel_tracking_models.dart';

/// Tháng/năm báo cáo trên màn Nhiên liệu (mặc định tháng hiện tại).
@immutable
class FuelReportPeriod {
  const FuelReportPeriod({required this.month, required this.year});

  final int month;
  final int year;

  factory FuelReportPeriod.now() {
    final n = DateTime.now();
    return FuelReportPeriod(month: n.month, year: n.year);
  }
}

final fuelReportPeriodProvider = StateProvider<FuelReportPeriod>((ref) {
  return FuelReportPeriod.now();
});

/// Xe đang xem (null = dùng xe “hiện tại” từ API).
final fuelSelectedVehicleIdProvider = StateProvider<int?>((ref) => null);

@immutable
class FuelDashboardVm {
  const FuelDashboardVm({
    required this.hasVehicle,
    required this.activeVehicleId,
    required this.vehicleName,
    required this.licensePlate,
    this.imageUrl,
    required this.summary,
    required this.insight,
    required this.transactions,
    required this.transactionsTotalCount,
  });

  final bool hasVehicle;
  final int activeVehicleId;
  final String vehicleName;
  final String licensePlate;
  final String? imageUrl;
  final FuelSummaryUi summary;
  final FuelInsightUi insight;
  final List<FuelTransactionUi> transactions;
  final int transactionsTotalCount;

  static FuelDashboardVm emptyNoVehicle() {
    return FuelDashboardVm(
      hasVehicle: false,
      activeVehicleId: 0,
      vehicleName: '—',
      licensePlate: '—',
      imageUrl: null,
      summary: const FuelSummaryUi(
        totalCostDong: 0,
        totalLiters: 0,
        costPerKmDong: 0,
        costChangePercent: 0,
        literChangePercent: 0,
        costPerKmChangePercent: 0,
      ),
      insight: const FuelInsightUi(mainComment: '', secondaryInsight: ''),
      transactions: const [],
      transactionsTotalCount: 0,
    );
  }
}

FuelSummaryUi _mapSummary(FuelSummaryApiDto d) {
  return FuelSummaryUi(
    totalCostDong: d.totalCost.round(),
    totalLiters: d.totalLiters,
    costPerKmDong: d.costPerKm.round(),
    costChangePercent: d.costChangePercent,
    literChangePercent: d.literChangePercent,
    costPerKmChangePercent: d.costPerKmChangePercent,
  );
}

FuelInsightUi _mapInsight(FuelInsightApiDto d) {
  return FuelInsightUi(
    mainComment: d.mainText.isEmpty ? 'Chưa có nhận xét.' : d.mainText,
    secondaryInsight: d.savingText.isEmpty ? '' : d.savingText,
  );
}

/// Map DTO lịch sử đổ xăng → model UI (dùng chung dashboard + màn xem tất cả).
List<FuelTransactionUi> fuelTransactionsToUi(List<FuelTransactionApiDto> items) {
  return items
      .map(
        (e) => FuelTransactionUi(
          id: e.id.toString(),
          amountDong: e.amount.round(),
          liters: e.liters,
          odometerKm: e.odometer,
          note: (e.note == null || e.note!.trim().isEmpty) ? null : e.note!.trim(),
          transactionDate: e.transactionDate,
        ),
      )
      .toList();
}

(String name, String plate, String? imageUrl) _displayForVehicle(
  CurrentVehicleApiDto cv,
  int activeId,
  MyVehiclesListResponse? myVehicles,
) {
  final list = myVehicles?.items ?? const <VehicleDto>[];
  for (final v in list) {
    if (v.id == activeId) {
      final name = (v.vehicleName?.trim().isNotEmpty ?? false) ? v.vehicleName!.trim() : (cv.vehicleName?.trim() ?? 'Xe');
      return (name, v.licensePlate, v.imageUrl);
    }
  }
  final name = (cv.vehicleName?.trim().isNotEmpty ?? false) ? cv.vehicleName!.trim() : 'Xe';
  return (name, cv.licensePlate, cv.imageUrl);
}

/// Tải song song: xe hiện tại, danh sách xe (đồng bộ UI chọn), tóm tắt, nhận xét, lịch sử.
final fuelDashboardProvider = FutureProvider.autoDispose<FuelDashboardVm>((ref) async {
  final api = ref.watch(fuelApiProvider);
  final period = ref.watch(fuelReportPeriodProvider);
  final overrideId = ref.watch(fuelSelectedVehicleIdProvider);

  final myList = await ref.watch(myVehiclesListProvider.future);

  late final CurrentVehicleApiDto cv;
  try {
    cv = await api.getCurrentVehicle();
  } on ApiException catch (e) {
    if (e.statusCode == 404) {
      if (myList.items.isEmpty) {
        return FuelDashboardVm.emptyNoVehicle();
      }
      final v0 = myList.items.firstWhere((e) => e.isDefault, orElse: () => myList.items.first);
      cv = CurrentVehicleApiDto(
        vehicleId: v0.id,
        vehicleName: v0.vehicleName,
        licensePlate: v0.licensePlate,
        fuelType: v0.fuelType,
        imageUrl: v0.imageUrl,
      );
    } else {
      rethrow;
    }
  }

  final activeId = overrideId ?? cv.vehicleId;
  final display = _displayForVehicle(cv, activeId, myList);

  final summaryF = api.getFuelMonthlySummary(activeId, period.month, period.year);
  final insightF = api.getFuelInsights(activeId, period.month, period.year);
  final txF = api.getFuelTransactions(activeId, pageIndex: 1, pageSize: 20);

  final bundle = await Future.wait<Object>([summaryF, insightF, txF]);
  final summary = _mapSummary(bundle[0] as FuelSummaryApiDto);
  final insight = _mapInsight(bundle[1] as FuelInsightApiDto);
  final page = bundle[2] as FuelTransactionsPageApiDto;

  return FuelDashboardVm(
    hasVehicle: true,
    activeVehicleId: activeId,
    vehicleName: display.$1,
    licensePlate: display.$2,
    imageUrl: display.$3,
    summary: summary,
    insight: insight,
    transactions: fuelTransactionsToUi(page.items),
    transactionsTotalCount: page.totalCount,
  );
});
