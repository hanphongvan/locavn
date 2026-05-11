import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import 'parsed_fuel_transaction_dto.dart';

/// HTTP client cho `/api/fuel/voice/*` — citizen (Loai=5) bấm mic ở trang Nhiên liệu →
/// upload audio → BE forward Whisper → parser → trả prefill data.
class FuelVoiceRepository {
  FuelVoiceRepository(this._dio);

  final Dio _dio;

  /// `GET /feature-status` — toggle setting `loca.donhienlieu`. Trả `false` khi lỗi mạng.
  Future<bool> isFeatureEnabled() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.fuelVoiceFeatureStatus);
      final data = response.data;
      if (data is! Map) return false;
      final m = data.cast<String, dynamic>();
      return m['enabled'] == true;
    } on DioException catch (e) {
      debugPrint('[fuel-voice] feature-status DioException type=${e.type} status=${e.response?.statusCode}');
      return false;
    }
  }

  /// `POST /parse-fuel-tx` — multipart audio (m4a/mp3/wav). Throw [ApiException] khi mạng/auth fail;
  /// trả DTO với `amountVnd==null` khi Whisper nghe được nhưng parser không bắt được số tiền (UX fail dialog).
  Future<ParsedFuelTransactionDto> parseVoice({
    required String filePath,
    required String contentType,
  }) async {
    debugPrint('[fuel-voice] parseVoice → POST ${ApiEndpoints.fuelVoiceParseTransaction} ($contentType)');
    try {
      final form = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(
          filePath,
          contentType: DioMediaType.parse(contentType),
        ),
      });
      final response = await _dio.post<dynamic>(
        ApiEndpoints.fuelVoiceParseTransaction,
        data: form,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('parse-fuel-tx: data not a map');
        }
        return ParsedFuelTransactionDto.fromJson(m);
      });
    } on DioException catch (e) {
      debugPrint('[fuel-voice] parseVoice DioException type=${e.type} status=${e.response?.statusCode}');
      throw ApiException.fromDio(e);
    }
  }
}

final fuelVoiceRepositoryProvider = Provider<FuelVoiceRepository>((ref) {
  return FuelVoiceRepository(ref.watch(dioProvider));
});

/// Cache feature-status trong session (không refresh giữa các navigate). Reset khi logout.
final fuelVoiceFeatureEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(fuelVoiceRepositoryProvider).isFeatureEnabled();
});
