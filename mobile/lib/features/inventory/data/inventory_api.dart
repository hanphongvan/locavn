import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import '../../../core/network/portal_data_api_base.dart';
import 'models/inventory_summary_response.dart';
import 'models/station_map_stock_by_ids_response.dart';

final inventoryApiProvider = Provider<InventoryApi>((ref) {
  return InventoryApi(
    ref.watch(dioProvider),
    () => ref.read(portalSessionScopeProvider),
  );
});

/// Backend: `/api/inventory` (report-based stock demo).
class InventoryApi extends PortalDataApiBase {
  InventoryApi(super.dio, super.readPortalScope);

  /// Từ `sp_Api_Inventory_StationTotalStockByDonViIds` — trạm có tổng tồn &gt; 0.
  Future<StationMapStockByIdsResponse> getMapStockByDonViIds(List<int> donViIds) async {
    if (donViIds.isEmpty) {
      return StationMapStockByIdsResponse(items: const []);
    }
    final take = donViIds.length > 500 ? donViIds.take(500).toList(growable: false) : donViIds;
    try {
      final response = await dio.get<dynamic>(
        ApiEndpoints.inventoryMapStockByIds,
        queryParameters: queryWithOptionalDonViId(<String, dynamic>{
          'donViIds': take.join(','),
        }),
      );
      return ApiResponseHandler.decode(response, StationMapStockByIdsResponse.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<InventorySummaryResponse> getSummary({int? kieuKyBaoCao}) async {
    try {
      final response = await dio.get<dynamic>(
        ApiEndpoints.inventorySummary,
        queryParameters: queryWithOptionalDonViId(<String, dynamic>{
          ...? kieuKyBaoCao != null ? {'kieuKyBaoCao': kieuKyBaoCao} : null,
        }),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for InventorySummaryResponseDto');
        }
        return InventorySummaryResponse.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
