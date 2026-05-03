import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/network/api_response.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../../core/network/json_utils.dart';
import 'account_activity_models.dart';

final accountActivityApiProvider = Provider<AccountActivityApi>((ref) {
  return AccountActivityApi(ref.watch(dioProvider));
});

class AccountActivityApi {
  AccountActivityApi(this._dio);

  final Dio _dio;

  Future<AccountActivitySummary> getSummary() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.accountActivitySummary);
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for activity summary');
        }
        return AccountActivitySummary.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
