import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_info/package_info_provider.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import 'app_version_policy_models.dart';

const _versionPolicyEndpoint = '/api/app/version-policy';

class AppVersionPolicyApi {
  AppVersionPolicyApi(this._dio);
  final Dio _dio;

  /// Trả về [AppVersionPolicy] hoặc `null` nếu backend lỗi / 404 / timeout.
  /// Fail-safe: caller treat null = no policy, đừng block app.
  Future<AppVersionPolicy?> fetch(String platform) async {
    try {
      final resp = await _dio.get<dynamic>(
        _versionPolicyEndpoint,
        queryParameters: {'platform': platform},
        // Timeout ngắn — splash không được chờ network lâu.
        options: Options(
          receiveTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 4),
        ),
      );
      return ApiResponseHandler.decode<AppVersionPolicy?>(resp, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) return null;
        return AppVersionPolicy.fromJson(m);
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[version-policy] fetch failed: $e\n$st');
      }
      return null;
    }
  }
}

final appVersionPolicyApiProvider = Provider<AppVersionPolicyApi>((ref) {
  return AppVersionPolicyApi(ref.watch(dioProvider));
});

/// So sánh "MAJOR.MINOR.PATCH" — trả -1 / 0 / 1. Phần thiếu coi như 0. Phần
/// không phải số → coi như 0 (fail-safe). Không hỗ trợ pre-release/build metadata.
int compareSemverLite(String a, String b) {
  final ap = _semverParts(a);
  final bp = _semverParts(b);
  for (var i = 0; i < 3; i++) {
    final cmp = ap[i].compareTo(bp[i]);
    if (cmp != 0) return cmp;
  }
  return 0;
}

List<int> _semverParts(String v) {
  final parts = v.split('.');
  return [
    parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
    parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
  ];
}

/// Đánh giá phiên bản hiện tại (từ `package_info_plus`) so với policy backend.
/// Trả [AppVersionUpdateStatus] + policy đính kèm (cho dialog hiển thị message + storeUrl).
final appVersionUpdateCheckProvider = FutureProvider<AppVersionCheckResult>((ref) async {
  final pkg = await ref.watch(packageInfoProvider.future);
  final api = ref.watch(appVersionPolicyApiProvider);

  String platform = 'other';
  if (Platform.isAndroid) {
    platform = 'android';
  } else if (Platform.isIOS) {
    platform = 'ios';
  }

  if (platform == 'other') {
    return const AppVersionCheckResult(status: AppVersionUpdateStatus.unknown);
  }

  final policy = await api.fetch(platform);
  if (policy == null) {
    return const AppVersionCheckResult(status: AppVersionUpdateStatus.unknown);
  }

  final current = pkg.version;
  if (compareSemverLite(current, policy.minSupported) < 0) {
    return AppVersionCheckResult(status: AppVersionUpdateStatus.forceUpdate, policy: policy);
  }
  if (compareSemverLite(current, policy.latestVersion) < 0) {
    return AppVersionCheckResult(status: AppVersionUpdateStatus.softUpdate, policy: policy);
  }
  return AppVersionCheckResult(status: AppVersionUpdateStatus.upToDate, policy: policy);
});

class AppVersionCheckResult {
  const AppVersionCheckResult({required this.status, this.policy});
  final AppVersionUpdateStatus status;
  final AppVersionPolicy? policy;
}
