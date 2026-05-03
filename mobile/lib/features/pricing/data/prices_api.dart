import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import '../../../core/network/portal_data_api_base.dart';
import 'models/latest_fuel_prices_response.dart';

final pricesApiProvider = Provider<PricesApi>((ref) {
  return PricesApi(
    ref.watch(dioProvider),
    () => ref.read(portalSessionScopeProvider),
  );
});

/// Backend: `/api/prices`
class PricesApi extends PortalDataApiBase {
  PricesApi(super.dio, super.readPortalScope);

  Future<LatestFuelPricesResponse> getLatestPrices({int? kieuKyBaoCao}) async {
    try {
      final response = await dio.get<dynamic>(
        ApiEndpoints.pricesLatest,
        queryParameters: queryWithOptionalDonViId(<String, dynamic>{
          ...? kieuKyBaoCao != null ? {'kieuKyBaoCao': kieuKyBaoCao} : null,
        }),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for LatestFuelPricesResponseDto');
        }
        return LatestFuelPricesResponse.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
