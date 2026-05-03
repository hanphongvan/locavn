import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import 'models/my_bad_reports_models.dart';

final myBadReportsApiProvider = Provider<MyBadReportsApi>((ref) {
  return MyBadReportsApi(ref.watch(dioProvider));
});

/// `GET /api/my-bad-reports` — JWT portal.
class MyBadReportsApi {
  MyBadReportsApi(this._dio);

  final Dio _dio;

  Future<MyBadReportPage> list({int skip = 0, int take = 30}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.myBadReports,
        queryParameters: <String, dynamic>{
          'skip': skip,
          'take': take,
        },
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for my-bad-reports');
        }
        return MyBadReportPage.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
