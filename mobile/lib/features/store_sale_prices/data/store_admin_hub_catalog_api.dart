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
import 'models/store_admin_fuel_product_list_item.dart';
import 'models/store_admin_store_row.dart';
import 'store_price_list_constants.dart';

final storeAdminHubCatalogApiProvider = Provider<StoreAdminHubCatalogApi>((ref) {
  return StoreAdminHubCatalogApi(
    ref.watch(dioProvider),
    () => ref.read(portalSessionScopeProvider),
  );
});

/// Angular hub catalog: `FuelProductsApiService` + `StoresApiService` (not `store-prices/products`).
class StoreAdminHubCatalogApi extends PortalDataApiBase {
  StoreAdminHubCatalogApi(super.dio, super.readPortalScope);

  Options _adminOptions() {
    final headers = AdminApiCredentials.headersFromKeyAndToken(
      ApiConfig.adminApiKey,
      ApiConfig.adminBearerToken,
    );
    return Options(headers: headers.isNotEmpty ? headers : null);
  }

  Future<List<StoreAdminFuelProductListItem>> listFuelProducts({
    int skip = 0,
    int take = StorePriceListConstants.hubFuelProductsTake,
    bool? isActive,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        ApiEndpoints.adminFuelProducts,
        queryParameters: <String, dynamic>{
          'skip': skip,
          'take': take,
          'isActive': ?isActive,
        },
        options: _adminOptions(),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for fuel products page');
        }
        final list = JsonUtils.readList(m['items']);
        if (list == null) {
          throw const FormatException('Expected items array');
        }
        return list
            .map((e) => StoreAdminFuelProductListItem.fromJson(JsonUtils.readMap(e) ?? {}))
            .toList();
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<StoreAdminStoreRow>> listStores({
    int skip = 0,
    int take = StorePriceListConstants.hubStoresTake,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        ApiEndpoints.adminStores,
        queryParameters: <String, dynamic>{'skip': skip, 'take': take},
        options: _adminOptions(),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for stores page');
        }
        final list = JsonUtils.readList(m['items']);
        if (list == null) {
          throw const FormatException('Expected items array');
        }
        return list
            .map((e) => StoreAdminStoreRow.fromJson(JsonUtils.readMap(e) ?? {}))
            .toList();
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
