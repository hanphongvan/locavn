import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import '../../../core/network/portal_data_api_base.dart';
import 'models/reports_overview_dto.dart';

final reportsApiProvider = Provider<ReportsApi>((ref) {
  return ReportsApi(
    ref.watch(dioProvider),
    () => ref.read(portalSessionScopeProvider),
  );
});

/// Backend: `/api/reports`
class ReportsApi extends PortalDataApiBase {
  ReportsApi(super.dio, super.readPortalScope);

  Future<ReportsOverviewDto> getOverview() async {
    try {
      final response = await dio.get<dynamic>(
        ApiEndpoints.reportsOverview,
        queryParameters: queryWithOptionalDonViId(<String, dynamic>{}),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for ReportsOverviewDto');
        }
        return ReportsOverviewDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
