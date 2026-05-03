import 'package:dio/dio.dart';

bool _responseBodyLooksLikeHtml(String s) {
  final t = s.trim().toLowerCase();
  return t.startsWith('<!doctype') || t.startsWith('<html');
}

/// Thông điệp tiếng Việt khi server/proxy không trả JSON hữu ích (vd nginx 502/503).
String? userFacingMessageForHttpStatus(int? statusCode) {
  switch (statusCode) {
    case 502:
      return 'Cổng API tạm thời không kết nối được tới máy chủ (502). Vui lòng thử lại sau.';
    case 503:
      return 'Dịch vụ tạm thời không sẵn sàng (503). Máy chủ có thể đang bảo trì hoặc quá tải — vui lòng thử lại sau.';
    case 504:
      return 'Máy chủ phản hồi quá lâu (504). Vui lòng thử lại.';
    case 408:
      return 'Hết thời gian chờ. Vui lòng thử lại.';
    case 429:
      return 'Quá nhiều yêu cầu trong thời gian ngắn. Vui lòng thử lại sau.';
    default:
      return null;
  }
}

/// Thông điệp ngắn cho UI — tránh nguyên văn cảnh báo [validateStatus] của Dio.
String messageForDioException(DioException e) {
  final data = e.response?.data;
  final code = e.response?.statusCode;

  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final desc = map['error_description'] as String?;
    final err = map['error'] as String?;
    if (desc != null && desc.trim().isNotEmpty) return desc.trim();
    if (err != null && err.trim().isNotEmpty) return err.trim();
    final detail = map['detail'] as String?;
    final title = map['title'] as String?;
    if (detail != null && detail.trim().isNotEmpty) return detail.trim();
    if (title != null && title.trim().isNotEmpty) return title.trim();
  } else if (data is String && data.isNotEmpty && !_responseBodyLooksLikeHtml(data)) {
    final t = data.trim();
    if (t.length <= 400) return t;
  }

  final byStatus = userFacingMessageForHttpStatus(code);
  if (byStatus != null) return byStatus;

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Hết thời gian chờ mạng. Kiểm tra kết nối và thử lại.';
    case DioExceptionType.connectionError:
      return 'Không kết nối được tới máy chủ. Kiểm tra Internet hoặc địa chỉ API.';
    default:
      break;
  }

  final raw = e.message?.trim();
  if (raw != null &&
      raw.isNotEmpty &&
      raw.length < 180 &&
      !raw.contains('validateStatus') &&
      !raw.contains('RequestOptions')) {
    return raw;
  }
  if (code != null) {
    return 'Lỗi mạng (mã $code). Vui lòng thử lại.';
  }
  return 'Lỗi kết nối. Vui lòng thử lại.';
}
