import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/network/admin_api_credentials.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_get_with_retry.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import '../../../core/network/portal_data_api_base.dart';
import 'models/store_service_catalog_item.dart';
import 'models/store_service_create_request.dart';
import 'models/store_service_row.dart';

final storeServicesApiProvider = Provider<StoreServicesApi>((ref) {
  return StoreServicesApi(
    ref.watch(dioProvider),
    () => ref.read(portalSessionScopeProvider),
  );
});

/// REST client for `AdminStoreServicesController`.
class StoreServicesApi extends PortalDataApiBase {
  StoreServicesApi(super.dio, super.readPortalScope);

  Options _adminOptions() {
    final headers = AdminApiCredentials.headersFromKeyAndToken(
      ApiConfig.adminApiKey,
      ApiConfig.adminBearerToken,
    );
    return Options(headers: headers.isNotEmpty ? headers : null);
  }

  Future<List<StoreServiceCatalogItem>> getCatalog() async {
    try {
      final response = await dioGetWithConnectionRetry<dynamic>(
        dio,
        ApiEndpoints.adminStoreServicesCatalog,
        options: _adminOptions(),
        debugLabel: 'store-services catalog',
      );
      return ApiResponseHandler.decode(response, (data) {
        final list = JsonUtils.readList(data);
        if (list == null) {
          throw const FormatException('Expected JSON array for store-services catalog');
        }
        return list
            .map((e) => StoreServiceCatalogItem.fromJson(JsonUtils.readMap(e) ?? {}))
            .toList();
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<StoreServiceRow>> listByStore(int donViId) async {
    try {
      final response = await dioGetWithConnectionRetry<dynamic>(
        dio,
        ApiEndpoints.adminStoreServicesByStore(donViId),
        options: _adminOptions(),
        debugLabel: 'store-services by-store',
      );
      return ApiResponseHandler.decode(response, (data) {
        final list = JsonUtils.readList(data);
        if (list == null) {
          throw const FormatException('Expected JSON array for store-services by-store');
        }
        return list
            .map((e) => StoreServiceRow.fromJson(JsonUtils.readMap(e) ?? {}))
            .toList();
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<StoreServiceRow> create(StoreServiceCreateRequest body) async {
    try {
      final response = await dio.post<dynamic>(
        ApiEndpoints.adminStoreServices,
        data: body.toJson(),
        options: _adminOptions(),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for created store service');
        }
        return StoreServiceRow.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<StoreServiceRow> update(int id, Map<String, dynamic> body) async {
    try {
      final response = await dio.put<dynamic>(
        ApiEndpoints.adminStoreServiceById(id),
        data: body,
        options: _adminOptions(),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for updated store service');
        }
        return StoreServiceRow.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await dio.delete<void>(
        ApiEndpoints.adminStoreServiceById(id),
        options: _adminOptions(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
