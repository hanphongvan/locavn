import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:httm_xangdau/app.dart';
import 'package:httm_xangdau/core/auth/auth_providers.dart';
import 'package:httm_xangdau/core/auth/local_persistent_session_store.dart';
import 'package:httm_xangdau/core/auth/portal_loai.dart';
import 'package:httm_xangdau/core/network/dio_provider.dart';

void main() {
  testWidgets('app shell builds with bottom navigation', (WidgetTester tester) async {
    final dio = Dio(
      BaseOptions(baseUrl: 'http://localhost'),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          Object? body;
          final path = options.path;
          if (path.endsWith('/api/stations/map')) {
            body = {
              'items': <dynamic>[],
              'totalCount': 0,
              'skip': 0,
              'take': 40,
            };
          } else if (path.endsWith('/api/reports/overview')) {
            body = {
              'totalStations': 0,
              'openStations': 0,
              'closedStations': 0,
              'stationsByProvince': <dynamic>[],
              'systemInventory': <dynamic>[],
              'notes': <String>[],
            };
          } else if (path.endsWith('/api/geography/provinces')) {
            body = <dynamic>[];
          } else {
            body = <String, dynamic>{};
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: body,
            ),
          );
        },
      ),
    );

    final mem = InMemoryLocalPersistentSessionStore();
    await mem.saveSession(
      accessToken: 'widget-test-token',
      username: 'tester',
      donViId: 1,
      loai: PortalLoai.admin,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(dio),
          localPersistentSessionStoreProvider.overrideWithValue(mem),
        ],
        child: const HttmXangdauApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bản đồ cây xăng'), findsWidgets); // tab label on admin landing (/reports)
  });
}
