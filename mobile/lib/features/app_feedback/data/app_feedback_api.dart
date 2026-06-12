import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';

/// Phân loại góp ý — index PHẢI khớp enum backend `AppFeedbackCategory`
/// (0=Bug, 1=Suggestion, 2=Other). Không đổi thứ tự.
enum AppFeedbackCategory {
  bug,
  suggestion,
  other;

  String get label => switch (this) {
        AppFeedbackCategory.bug => 'Báo lỗi',
        AppFeedbackCategory.suggestion => 'Đề xuất',
        AppFeedbackCategory.other => 'Khác',
      };
}

final appFeedbackApiProvider = Provider<AppFeedbackApi>((ref) {
  return AppFeedbackApi(ref.watch(dioProvider));
});

/// POST `/api/app-feedback` (góp ý ứng dụng; gửi được ẩn danh).
class AppFeedbackApi {
  AppFeedbackApi(this._dio);

  final Dio _dio;

  /// Server limit — phải khớp `AppFeedbackImageUploadService.MaxBytes`.
  static const int maxUploadImageBytes = 5 * 1024 * 1024;

  /// Tối đa ảnh đính kèm — khớp `AppFeedbackRequestValidator.MaxImageUrls`.
  static const int maxImages = 6;

  /// Multipart `file` → `{ "url": "https://..." }`. Cho phép ẩn danh.
  Future<String> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > maxUploadImageBytes) {
      throw FormatException('Ảnh vượt quá ${maxUploadImageBytes ~/ (1024 * 1024)} MB.');
    }
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.appFeedbackUploadImage,
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
    required AppFeedbackCategory category,
    required String content,
    String? contactEmail,
    String? contactPhone,
    List<String>? imageUrls,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('content is required');
    }
    try {
      final body = <String, dynamic>{
        'category': category.index,
        'content': trimmed,
        'platform': _platformTag(),
      };
      final email = contactEmail?.trim();
      if (email != null && email.isNotEmpty) body['contactEmail'] = email;
      final phone = contactPhone?.trim();
      if (phone != null && phone.isNotEmpty) body['contactPhone'] = phone;

      final urls = imageUrls
              ?.map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      if (urls.isNotEmpty) {
        body['imageUrls'] = urls;
      }

      final response = await _dio.post<dynamic>(ApiEndpoints.appFeedback, data: body);
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for app-feedback response');
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

  static String _platformTag() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => defaultTargetPlatform.name,
    };
  }
}
