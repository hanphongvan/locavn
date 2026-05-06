import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/environment_config.dart';
import 'core/map/map_provider_bootstrap.dart';
import 'core/map/map_providers.dart';
import 'core/network/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
