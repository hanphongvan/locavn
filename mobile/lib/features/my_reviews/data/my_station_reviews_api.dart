import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import 'models/my_station_reviews_models.dart';

final myStationReviewsApiProvider = Provider<MyStationReviewsApi>((ref) {
  return MyStationReviewsApi(ref.watch(dioProvider));
});

/// `GET /api/my-reviews` — JWT portal.
class MyStationReviewsApi {
  MyStationReviewsApi(this._dio);

  final Dio _dio;

  Future<MyStationReviewsPage> list({int skip = 0, int take = 50}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.myReviews,
        queryParameters: <String, dynamic>{
          'skip': skip,
          'take': take,
        },
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for my-reviews');
        }
        return MyStationReviewsPage.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
