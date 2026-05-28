import '../../../core/network/json_utils.dart';

/// Response từ `GET /api/app/version-policy?platform=android|ios`.
class AppVersionPolicy {
  const AppVersionPolicy({
    required this.platform,
    required this.minSupported,
    required this.latestVersion,
    this.messageVi,
    this.storeUrl,
  });

  final String platform;
  final String minSupported;
  final String latestVersion;
  final String? messageVi;
  final String? storeUrl;

  factory AppVersionPolicy.fromJson(Map<String, dynamic> json) {
    return AppVersionPolicy(
      platform: JsonUtils.readString(json['platform']) ??
          JsonUtils.readString(json['Platform']) ??
          '',
      minSupported: JsonUtils.readString(json['minSupported']) ??
          JsonUtils.readString(json['MinSupported']) ??
          '0.0.0',
      latestVersion: JsonUtils.readString(json['latestVersion']) ??
          JsonUtils.readString(json['LatestVersion']) ??
          '0.0.0',
      messageVi: JsonUtils.readString(json['messageVi']) ??
          JsonUtils.readString(json['MessageVi']),
      storeUrl: JsonUtils.readString(json['storeUrl']) ??
          JsonUtils.readString(json['StoreUrl']),
    );
  }
}

/// Trạng thái sau khi so sánh phiên bản hiện tại với policy.
enum AppVersionUpdateStatus {
  /// Bằng hoặc cao hơn `latestVersion` — không cần update.
  upToDate,

  /// Cao hơn hoặc bằng `minSupported` nhưng thấp hơn `latestVersion` — gợi ý cập nhật, có thể skip.
  softUpdate,

  /// Thấp hơn `minSupported` — bắt buộc cập nhật, không dismiss được.
  forceUpdate,

  /// Backend trả lỗi / không reachable. Fail-safe: cho phép vào app, không hiện dialog.
  unknown,
}
