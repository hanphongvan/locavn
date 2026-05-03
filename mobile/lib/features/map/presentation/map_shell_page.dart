// Map-first shell: filters, markers, preview sheet. Upgrade phases & module boundaries:
// `mobile/docs/flutter-map-upgrade-phases.md`
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shared/widgets/async_value_body.dart';
import '../../stations/data/models/station_map_markers_load_result.dart';
import 'map_active_filters_strip.dart';
import 'map_filter_chip_bar.dart';
import 'map_floating_controls.dart';
import 'map_providers.dart';
import 'map_screen_palette.dart';
import 'map_search_bar.dart';
import 'map_station_map_body.dart';
import 'station_map_bottom_sheet.dart';

class MapShellPage extends ConsumerStatefulWidget {
  const MapShellPage({super.key});

  @override
  ConsumerState<MapShellPage> createState() => _MapShellPageState();
}

class _MapShellPageState extends ConsumerState<MapShellPage> {
  GoogleMapController? _mapController;
  final GlobalKey _chromeKey = GlobalKey();
  double _mapTopInsetPx = 120;
  bool _chromeMeasureScheduled = false;

  void _scheduleChromeMeasure() {
    if (_chromeMeasureScheduled) return;
    _chromeMeasureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chromeMeasureScheduled = false;
      if (!mounted) return;
      final ro = _chromeKey.currentContext?.findRenderObject();
      if (ro is RenderBox && ro.hasSize) {
        final h = ro.size.height;
        if ((h - _mapTopInsetPx).abs() > 0.5) {
          setState(() => _mapTopInsetPx = h);
        }
      }
    });
  }

  @override
  void dispose() {
    // Tránh stale reference trong `mapGoogleMapControllerProvider` sau khi page pop —
    // controller được giữ trong StateProvider không-autoDispose. Defer qua microtask để
    // không ghi vào provider trong giai đoạn dispose của widget tree (Riverpod cấm).
    final container = ProviderScope.containerOf(context, listen: false);
    Future.microtask(() {
      container.read(mapGoogleMapControllerProvider.notifier).state = null;
    });
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleChromeMeasure();

    ref.listen<LatLng?>(mapCameraTargetProvider, (previous, next) {
      final target = next;
      final ctrl = _mapController;
      if (target == null || ctrl == null) return;
      ctrl.animateCamera(CameraUpdate.newLatLngZoom(target, 13)).then((_) {
        if (!context.mounted) return;
        ref.read(mapCameraTargetProvider.notifier).state = null;
      });
    });

    final asyncMarkers = ref.watch(stationMapMarkersProvider);
    final filters = ref.watch(mapFiltersProvider);
    // 4 provider sau (highlight / ephemeral / cheap spotlight / fuel mode) chỉ truyền xuống
    // `MapStationMapBody`. Watch trong Consumer bên trong builder để chrome (search bar /
    // filter chips / active strip) không rebuild khi tap marker.
    final sheetPad = MediaQuery.sizeOf(context).height * 0.2;

    return Scaffold(
      backgroundColor: MapScreenPalette.screenBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AsyncValueBody<StationMapMarkersLoadResult>(
              value: asyncMarkers,
              errorLogLabel: 'Bản đồ cây xăng (stationMapMarkersProvider)',
              loadingLabel: 'Đang tải dữ liệu bản đồ cây xăng',
              emptyMessage: 'Không có cây xăng nào có tọa độ hợp lệ.',
              isEmpty: (r) => r.items.isEmpty && !r.keywordApplied && r.mapTotalCount == 0,
              onRetry: () => ref.invalidate(stationMapMarkersFetchProvider),
              dataBuilder: (result) {
                if (result.items.isEmpty) {
                  String message;
                  if (result.keywordApplied) {
                    message =
                        'Không có cây xăng nào trên bản đồ đã tải khớp từ khóa (hoặc không có tọa độ).';
                  } else if (result.isEmptyDueToClientFilters) {
                    message =
                        'Không có cây xăng nào thỏa bộ lọc đang bật (loại nhiên liệu, giá, dịch vụ, …). Hãy nới lỏng hoặc mở Bộ lọc bản đồ và nhấn Đặt lại.';
                  } else if (result.mapTotalCount > 0) {
                    message =
                        'Có ${result.mapTotalCount} cây xăng nhưng không có dữ liệu tọa độ trong phạm vi đã tải.';
                  } else {
                    message = 'Không có cây xăng để hiển thị.';
                  }
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 24, 24, 24),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: MapScreenPalette.textSecondary,
                            ),
                      ),
                    ),
                  );
                }
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final highlightId = ref.watch(mapHighlightStationIdProvider);
                        final ephemeralStation = ref.watch(mapEphemeralStationProvider);
                        final cheapSpotlightId = ref.watch(mapCheapSpotlightStationIdProvider);
                        final fuelMode = ref.watch(mapMarkerFuelPriceModeProvider);
                        // Shell chỉ Loai=5 (Citizen): camera mặc định ~500 m quanh GPS — xem MapStationMapBody.
                        return MapStationMapBody(
                      allItems: result.items,
                      overlayStation: ephemeralStation,
                      cheapSpotlightStationId: cheapSpotlightId,
                      externalHighlightStationId: highlightId,
                      fuelPriceMode: fuelMode,
                      mapBottomPadding: sheetPad,
                      mapTopPadding: _mapTopInsetPx,
                      onDismissExternalHighlight: () {
                        ref.read(mapHighlightStationIdProvider.notifier).state = null;
                        ref.read(mapEphemeralStationProvider.notifier).state = null;
                        mapClearCheapSpotlightMarker(ref);
                      },
                      onMapControllerReady: (c) {
                        _mapController = c;
                        ref.read(mapGoogleMapControllerProvider.notifier).state = c;
                      },
                      topOverlay: (result.truncated || result.keywordListTruncated)
                          ? Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, _mapTopInsetPx + 8, 16, 0),
                                child: Material(
                                  elevation: 1,
                                  borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm),
                                  color: MapScreenPalette.cardWhite.withValues(alpha: 0.96),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (result.keywordListTruncated)
                                          Text(
                                            'Danh sách từ khóa có thể chưa đủ (giới hạn trang API).',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: MapScreenPalette.textSecondary,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        if (result.truncated)
                                          Text(
                                            'Bản đồ: hiển thị ${result.items.length}/${result.mapTotalCount} cây xăng có tọa độ (giới hạn tải).',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: MapScreenPalette.textSecondary,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : null,
                        );
                      },
                    ),
                    Positioned(
                      right: 12,
                      bottom: sheetPad + 12,
                      child: const MapFloatingControls(),
                    ),
                    const Positioned.fill(
                      child: StationMapBottomSheet(),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  key: _chromeKey,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MapSearchBar(),
                    const SizedBox(height: 10),
                    const MapFilterChipBar(),
                    if (filters.hasActiveStrip) ...[
                      const SizedBox(height: 8),
                      MapActiveFiltersStrip(filters: filters),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
