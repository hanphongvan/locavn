import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app_info/package_info_provider.dart';

/// Key trong secure storage cho UUID định danh thiết bị.
///
/// UUID v4 sinh ngẫu nhiên lần đầu mở app, KHÔNG đổi qua các phiên bản update — chỉ
/// reset khi user gỡ + cài lại. Dùng làm khoá đếm unique-client cho admin analytics
/// (`/api/admin/analytics/client-versions`).
const _kClientIdStorageKey = 'httm_xangdau_client_id';

final _secureStorageProvider = Provider<FlutterSecureStorage>((_) {
  return const FlutterSecureStorage();
});

/// Lấy hoặc sinh UUID v4 client-id. Riverpod cache để không hit storage lần nữa
/// trong cùng phiên app.
final clientIdProvider = FutureProvider<String>((ref) async {
  final storage = ref.read(_secureStorageProvider);
  try {
    final existing = await storage.read(key: _kClientIdStorageKey);
    if (existing != null && existing.isNotEmpty) return existing;
  } catch (e, st) {
    debugPrint('[telemetry] read clientId failed: $e\n$st');
  }
  final fresh = _generateUuidV4();
  try {
    await storage.write(key: _kClientIdStorageKey, value: fresh);
  } catch (e, st) {
    debugPrint('[telemetry] write clientId failed: $e\n$st');
  }
  return fresh;
});

/// 4 header gửi kèm mọi request mobile → backend dùng cho version tracking
/// (middleware `ClientVersionLogMiddleware`).
///
/// - `X-App-Version`: PackageInfo.version (vd "2.6.0")
/// - `X-App-Build`:   PackageInfo.buildNumber (vd "123")
/// - `X-App-Platform`: "android" | "ios" | "other"
/// - `X-Client-Id`:    UUID v4 từ secure storage
final clientTelemetryHeadersProvider = FutureProvider<Map<String, String>>((ref) async {
  final pkg = await ref.watch(packageInfoProvider.future);
  final clientId = await ref.watch(clientIdProvider.future);

  String platform = 'other';
  if (Platform.isAndroid) {
    platform = 'android';
  } else if (Platform.isIOS) {
    platform = 'ios';
  }

  return {
    'X-App-Version': pkg.version,
    'X-App-Build': pkg.buildNumber,
    'X-App-Platform': platform,
    'X-Client-Id': clientId,
  };
});

String _generateUuidV4() {
  final r = Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}
