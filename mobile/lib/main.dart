import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/map/map_provider_bootstrap.dart';
import 'core/map/map_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi');

  final mapRegistry = buildMapProviderRegistry(
    goongMapTilesKey: const String.fromEnvironment('GOONG_MAPTILES_KEY'),
    goongRestApiKey: const String.fromEnvironment('GOONG_API_KEY'),
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
