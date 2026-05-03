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
import 'models/store_don_vi_tinh_lookup.dart';
import 'models/store_fuel_product_lookup.dart';
import 'models/store_sale_price_batch_models.dart';
import 'models/store_sale_price_detail.dart';
import 'models/store_sale_price_list_item.dart';
import 'models/store_sale_price_latest_submission_row.dart';
import 'models/store_sale_price_upsert_request.dart';

final storeSalePricesApiProvider = Provider<StoreSalePricesApi>((ref) {
  return StoreSalePricesApi(
    ref.watch(dioProvider),
    () => ref.read(portalSessionScopeProvider),
  );
});

/// Low-level REST client for Angular-parity store price endpoints (`StorePricesApiService`).
class StoreSalePricesApi extends PortalDataApiBase {
  StoreSalePricesApi(super.dio, super.readPortalScope);

  Options _adminOptions() {
    final headers = AdminApiCredentials.headersFromKeyAndToken(
      ApiConfig.adminApiKey,
      ApiConfig.adminBearerToken,
    );
    return Options(headers: headers.isNotEmpty ? headers : null);
  }

  Future<List<StoreSalePriceListItem>> getCurrentByStore(int donViId) async {
    try {
      final response = await dioGetWithConnectionRetry<dynamic>(
        dio,
        ApiEndpoints.adminStorePricesCurrentByStore(donViId),
        options: _adminOptions(),
        debugLabel: 'store-prices current-by-store',
      );
      return ApiResponseHandler.decode(response, (data) {
        final list = JsonUtils.readList(data);
        if (list == null) {
          throw const FormatException('Expected JSON array for current prices');
        }
        return list
            .map((e) => StoreSalePriceListItem.fromJson(JsonUtils.readMap(e) ?? {}))
            .toList();
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<StoreSalePriceListItem>> getByStore(int donViId, {int? productId}) async {
    try {
      final qp = <String, dynamic>{};
      if (productId != null) qp['productId'] = productId;
      final response = await dioGetWithConnectionRetry<dynamic>(
        dio,
        ApiEndpoints.adminStorePricesByStore(donViId),
        queryParameters: qp.isEmpty ? null : qp,
        options: _adminOptions(),
        debugLabel: 'store-prices by-store',
      );
      return ApiResponseHandler.decode(response, (data) {
        final list = JsonUtils.readList(data);
        if (list == null) {
          throw const FormatException('Expected JSON array for by-store prices');
        }
        return list
            .map((e) => StoreSalePriceListItem.fromJson(JsonUtils.readMap(e) ?? {}))
            .toList();
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<StoreFuelProductLookup>> getProducts({
    String? search,
    int take = 200,
    bool defaultsOnly = false,
  }) async {
    try {
      final qp = <String, dynamic>{
        'take': take,
        'defaultsOnly': defaultsOnly,
      };
      if (search != null && search.trim().isNotEmpty) {
        qp['search'] = search.trim();
      }
      final response = await dioGetWithConnectionRetry<dynamic>(
        dio,
        ApiEndpoints.adminStorePricesProducts,
        queryParameters: qp,
        options: _adminOptions(),
        debugLabel: 'store-prices products',
      );
      return ApiResponseHandler.decode(response, (data) {
        final list = JsonUtils.readList(data);
        if (list == null) {
          throw const FormatException('Expected JSON array for products');
        }
        return list
            .map((e) => StoreFuelProductLookup.fromJson(JsonUtils.readMap(e) ?? {}))
            .toList();
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<StoreDonViTinhLookup>> getDonViTinh() async {
    try {
      final response = await dioGetWithConnectionRetry<dynamic>(
        dio,
        ApiEndpoints.adminStorePricesDonViTinh,
        options: _adminOptions(),
        debugLabel: 'store-prices don-vi-tinh',
      );
      return ApiResponseHandler.decode(response, (data) {
        final list = JsonUtils.readList(data);
        if (list == null) {
          throw const FormatException('Expected JSON array for don-vi-tinh');
        }
        return list
            .map((e) => StoreDonViTinhLookup.fromJson(JsonUtils.readMap(e) ?? {}))
            .toList();
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<StoreSalePriceLatestSubmissionRow>> getLatestSubmission(int donViId) async {
    try {
      final response = await dioGetWithConnectionRetry<dynamic>(
        dio,
        ApiEndpoints.adminStorePricesLatestSubmission,
        queryParameters: <String, dynamic>{'donViId': donViId},
        options: _adminOptions(),
        debugLabel: 'store-prices latest-submission',
      );
      return ApiResponseHandler.decode(response, (data) {
        final list = JsonUtils.readList(data);
        if (list == null) {
          throw const FormatException('Expected JSON array for latest-submission');
        }
        return list
            .map((e) =>
                StoreSalePriceLatestSubmissionRow.fromJson(JsonUtils.readMap(e) ?? {}))
            .toList();
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<StoreSalePriceBatchCreateResponse> postBatch(StoreSalePriceBatchCreateRequest body) async {
    try {
      final response = await dio.post<dynamic>(
        ApiEndpoints.adminStorePricesBatch,
        data: body.toJson(),
        options: _adminOptions(),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for batch create response');
        }
        return StoreSalePriceBatchCreateResponse.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<StoreSalePriceDetail> getById(int id) async {
    try {
      final response = await dioGetWithConnectionRetry<dynamic>(
        dio,
        ApiEndpoints.adminStorePricesById(id),
        options: _adminOptions(),
        debugLabel: 'store-prices by-id',
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for price detail');
        }
        return StoreSalePriceDetail.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<StoreSalePriceDetail> postCreate(StoreSalePriceUpsertRequest body) async {
    try {
      final response = await dio.post<dynamic>(
        ApiEndpoints.adminStorePrices,
        data: body.toJson(),
        options: _adminOptions(),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for created price');
        }
        return StoreSalePriceDetail.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<StoreSalePriceDetail> putUpdate(int id, StoreSalePriceUpsertRequest body) async {
    try {
      final response = await dio.put<dynamic>(
        ApiEndpoints.adminStorePricesById(id),
        data: body.toJson(),
        options: _adminOptions(),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for updated price');
        }
        return StoreSalePriceDetail.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
