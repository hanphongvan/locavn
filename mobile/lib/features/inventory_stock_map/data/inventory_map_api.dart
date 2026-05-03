import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/network/admin_api_credentials.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import '../../../core/network/portal_data_api_base.dart';
import 'inventory_map_group_code.dart';
import 'models/inventory_map_response.dart';

final inventoryMapApiProvider = Provider<InventoryMapApi>((ref) {
  return InventoryMapApi(
    ref.watch(dioProvider),
    () => ref.read(portalSessionScopeProvider),
  );
});

/// Backend: `GET /api/admin/inventory-map?groupCode=…` ([InventoryMapGroupCode]).
///
/// Optional `donViId` is merged from [PortalSessionScope] for store/trader list semantics
/// when the API accepts it; server-side Bearer scope remains authoritative.
class InventoryMapApi extends PortalDataApiBase {
  InventoryMapApi(super.dio, super.readPortalScope);

  Future<InventoryMapResponse> loadXangMap() => loadByGroupCode(InventoryMapGroupCode.xang);

  Future<InventoryMapResponse> loadDauMap() => loadByGroupCode(InventoryMapGroupCode.dau);

  Future<InventoryMapResponse> loadByGroupCode(String groupCode) async {
    try {
      // Biến cấu hình rõ ràng cho từng lần gọi (cùng nguồn với interceptor admin).
      final String adminApiKey = ApiConfig.adminApiKey;
      final String adminBearerToken = ApiConfig.adminBearerToken;
      final Map<String, String> adminAuthHeaders =
          AdminApiCredentials.headersFromKeyAndToken(adminApiKey, adminBearerToken);

      final response = await dio.get<dynamic>(
        ApiEndpoints.adminInventoryMap,
        queryParameters: queryWithOptionalDonViId(<String, dynamic>{'groupCode': groupCode}),
        options: adminAuthHeaders.isNotEmpty ? Options(headers: adminAuthHeaders) : null,
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for StoreAdminInventoryMapResponseDto');
        }
        return InventoryMapResponse.fromJson(m);
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException(
          'Chưa xác thực (401). Cần cùng giá trị với `Admin:ApiKey` trên API '
          '(ví dụ Development: `local-dev-admin-key` trong appsettings.Development.json). '
          'Truyền vào app: `--dart-define=ADMIN_API_KEY=…` hoặc (debug native) '
          'biến môi trường `HTTPM_ADMIN_API_KEY`; hoặc JWT: `--dart-define=ADMIN_BEARER_TOKEN=…`.',
          statusCode: 401,
          cause: e,
        );
      }
      throw ApiException.fromDio(e);
    }
  }
}
