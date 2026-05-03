import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';

final badReportsApiProvider = Provider<BadReportsApi>((ref) {
  return BadReportsApi(ref.watch(dioProvider));
});

/// POST `/api/bad-reports` (private report; no public list in app).
class BadReportsApi {
  BadReportsApi(this._dio);

  final Dio _dio;

  /// Server limit — must match `BadReportImageUploadService.MaxBytes`.
  static const int maxUploadImageBytes = 5 * 1024 * 1024;

  /// Multipart `file` → `{ "url": "https://..." }`. Requires Bearer JWT.
  Future<String> uploadBadReportImage(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > maxUploadImageBytes) {
      throw FormatException('Ảnh vượt quá ${maxUploadImageBytes ~/ (1024 * 1024)} MB.');
    }
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.badReportsUploadImage,
        data: formData,
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for upload-image response');
        }
        return JsonUtils.readStringRequired(m['url'], field: 'url');
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<({int id, DateTime createdAt})> submit({
    int? stationId,
    required String content,
    List<String>? imageUrls,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('content is required');
    }
    try {
      final body = <String, dynamic>{
        'content': trimmed,
      };
      final urls = imageUrls
              ?.map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      if (urls.isNotEmpty) {
        body['imageUrls'] = urls;
      }
      if (stationId != null) {
        body['stationId'] = stationId;
      }
      final response = await _dio.post<dynamic>(ApiEndpoints.badReports, data: body);
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for bad-report response');
        }
        final id = JsonUtils.readInt(m['id']);
        final created = JsonUtils.readDateTime(m['createdAt']);
        if (id == null || created == null) {
          throw const FormatException('Missing id or createdAt');
        }
        return (id: id, createdAt: created);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
