import 'api_exception.dart';

/// 404 từ spotlight (`/api/stations/cheapest`, `nearest`, `top-rated`): ưu tiên
/// [ApiException.message] từ `detail` (nếu máy chủ gửi); nếu chỉ còn "Not Found"
/// thì dùng [whenGenericTitle].
String userMessageForSpotlightNotFound(
  ApiException e, {
  required String whenGenericTitle,
}) {
  if (e.statusCode != 404) {
    return e.message;
  }
  final t = e.message.trim();
  if (t.isEmpty || t.toLowerCase() == 'not found') {
    return whenGenericTitle;
  }
  return t;
}
