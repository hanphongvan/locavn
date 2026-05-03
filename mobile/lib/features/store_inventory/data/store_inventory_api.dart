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
import 'models/inventory_current_line.dart';
import 'models/inventory_transaction_bundle.dart';
import 'models/inventory_transaction_header_list_item.dart';

final storeInventoryApiProvider = Provider<StoreInventoryApi>((ref) {
  return StoreInventoryApi(
    ref.watch(dioProvider),
    () => ref.read(portalSessionScopeProvider),
  );
});

/// Store-admin inventory REST (`AdminInventoryTransactionsController`, `AdminInventoriesController`).
class StoreInventoryApi extends PortalDataApiBase {
  StoreInventoryApi(super.dio, super.readPortalScope);

  Options _adminOptions() {
    final headers = AdminApiCredentials.headersFromKeyAndToken(
      ApiConfig.adminApiKey,
      ApiConfig.adminBearerToken,
    );
    return Options(headers: headers.isNotEmpty ? headers : null);
  }

  Future<List<InventoryTransactionHeaderListItem>> listTransactionsByStore(int donViId) async {
    try {
      final response = await dioGetWithConnectionRetry<dynamic>(
        dio,
        ApiEndpoints.adminInventoryTransactionsByStore(donViId),
        options: _adminOptions(),
        debugLabel: 'inventory-transactions by-store',
      );
      return ApiResponseHandler.decode(response, (data) {
        final list = JsonUtils.readList(data);
        if (list == null) {
          throw const FormatException('Expected array for inventory transactions');
        }
        return list
            .map((e) =>
                InventoryTransactionHeaderListItem.fromJson(JsonUtils.readMap(e) ?? {}))
            .toList();
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<InventoryTransactionBundle> getTransactionBundle(int id) async {
    try {
      final response = await dioGetWithConnectionRetry<dynamic>(
        dio,
        ApiEndpoints.adminInventoryTransactionById(id),
        options: _adminOptions(),
        debugLabel: 'inventory-transaction by-id',
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for inventory bundle');
        }
        return InventoryTransactionBundle.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await dio.delete<dynamic>(
        ApiEndpoints.adminInventoryTransactionById(id),
        options: _adminOptions(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<InventoryTransactionBundle> createTransaction(Map<String, dynamic> body) async {
    try {
      final response = await dio.post<dynamic>(
        ApiEndpoints.adminInventoryTransactions,
        data: body,
        options: _adminOptions(),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for created inventory');
        }
        return InventoryTransactionBundle.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<InventoryCurrentLine>> listCurrentByStore(int donViId) async {
    try {
      final response = await dioGetWithConnectionRetry<dynamic>(
        dio,
        ApiEndpoints.adminInventoriesCurrentByStore(donViId),
        options: _adminOptions(),
        debugLabel: 'inventories current by-store',
      );
      return ApiResponseHandler.decode(response, (data) {
        final list = JsonUtils.readList(data);
        if (list == null) {
          throw const FormatException('Expected array for current inventory');
        }
        return list
            .map((e) => InventoryCurrentLine.fromJson(JsonUtils.readMap(e) ?? {}))
            .toList();
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
