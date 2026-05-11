import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/config/environment_config.dart';
import 'core/map/map_provider_bootstrap.dart';
import 'core/map/map_providers.dart';
import 'core/network/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MapLibre native 6.25.1 + iOS 19 / iPhone 17 crash std::domain_error khi đọc lại
  // ambient cache từ lần chạy trước. Xoá cache trước khi map khởi tạo để mỗi launch
  // start clean. Trade-off: tile lại tải qua mạng mỗi lần (vẫn nhanh, vài MB).
  if (Platform.isIOS) {
    await _clearMapLibreCache();
  }

  // Fail-fast: throw nếu MAP_PROVIDER + keys không nhất quán (vd Goong thiếu key).
  // Gọi TRƯỚC runApp để dev/CI thấy error ngay khi build/launch sai config.
  EnvironmentConfig.validateOrThrow();

  if (kDebugMode) {
    debugPrint('[httm_xangdau] REST API root (ApiConfig.baseUrl): ${ApiConfig.baseUrl}');
  }

  await initializeDateFormatting('vi');

  final mapRegistry = buildMapProviderRegistry(
    goongMapTilesKey: EnvironmentConfig.goongMapTilesKey,
    goongRestApiKey: EnvironmentConfig.goongApiKey,
  );

  runApp(
    ProviderScope(
      overrides: [
        mapProviderRegistryProvider.overrideWith((ref) => mapRegistry),
      ],
      child: const HttmXangdauApp(),
    ),
  );
}

/// Xoá ambient cache của MapLibre iOS — `Library/Application Support/.mapbox/`
/// (path legacy mà MapLibre 6.x vẫn dùng) và `Library/Caches/.mbgl/`.
/// Best-effort: try/catch toàn bộ vì IO có thể fail trên nhiều device states.
Future<void> _clearMapLibreCache() async {
  try {
    final support = await getApplicationSupportDirectory();
    for (final name in ['.mapbox', '.maplibre']) {
      final dir = Directory('${support.path}/$name');
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    }
  } catch (_) {/* best-effort */}
  try {
    final caches = await getApplicationCacheDirectory();
    for (final name in ['.mbgl', '.maplibre', 'com.mapbox.maps']) {
      final dir = Directory('${caches.path}/$name');
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    }
  } catch (_) {/* best-effort */}
}
