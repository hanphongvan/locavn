import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/map/providers/google/google_marker_bridge.dart';
import '../../map/data/map_user_location.dart';
import '../../map/presentation/map_providers.dart';
import '../../map/presentation/map_screen_palette.dart';
import '../../map/presentation/map_station_marker_composer.dart';
import '../../map/presentation/map_station_marker_factory.dart';
import '../../reports/presentation/dashboard/loca_dashboard_tokens.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../stations/station_open_status.dart';
import '../data/leader_map_api.dart';
import '../data/leader_map_providers.dart';
import '../map/leader_demo_distributors.dart';
import '../map/leader_executive_distributor.dart';
import '../map/leader_distributor_map_marker.dart';
import '../map/leader_map_constants.dart';
import '../map/leader_map_grid_cluster.dart';
import '../map/leader_map_viewport.dart';
import '../map/leader_station_synthetic_stock.dart';
import '../data/leader_map_ui_state.dart';
import 'leader_map_detail_sheets.dart';
import 'leader_map_filter_sheet.dart';
import 'leader_map_ui_provider.dart';
import 'leader_theme.dart';

/// Tooltip Google Map: chỉ địa chỉ (tên ở [InfoWindow.title]).
String _leaderRetailMarkerInfoSnippet(StationMapItem s) {
  final raw = s.shortAddress?.trim();
  if (raw == null || raw.isEmpty) return '';
  return raw.length > 80 ? '${raw.substring(0, 77)}…' : raw;
}

List<LeaderFilteredStation> _filterStations(List<StationMapItem> items, LeaderMapUiState ui) {
  if (!ui.showRetailStores) return const [];
  final out = <LeaderFilteredStation>[];
  for (final s in items) {
    if (!leaderStationHasFuelPriceForFilter(s, ui.fuel)) continue;
    final stock = leaderSyntheticStockForStation(s);
    final days = leaderSelectedDays(stock, ui.fuel);
    if (!leaderPassesCoverageBand(days, ui.coverage)) continue;
    out.add((item: s, stock: stock));
  }
  return out;
}

List<LeaderDemoDistributor> _filterDemoDistributors(LeaderMapUiState ui) {
  if (!ui.showWholesale) return const [];
  return [
    for (final d in kLeaderDemoDistributors)
      if (leaderPassesCoverageBand(
        ui.fuel == LeaderMapFuelFilter.xang ? d.daysXang : d.daysDau,
        ui.coverage,
      ))
        d,
  ];
}

List<LeaderExecutiveDistributor> _resolveExecutiveDistributors(WidgetRef ref, LeaderMapUiState ui) {
  final api = ref.read(leaderMapDistributorsProvider);
  if (api.hasValue) {
    return [
      for (final r in api.value!.items)
        if (leaderPassesCoverageBand(
          ui.fuel == LeaderMapFuelFilter.xang ? r.daysXang?.toDouble() : r.daysDau?.toDouble(),
          ui.coverage,
        ))
          LeaderExecutiveDistributor.fromApi(r),
    ];
  }
  return [for (final d in _filterDemoDistributors(ui)) LeaderExecutiveDistributor.fromDemo(d)];
}

/// Bản đồ tồn kho xăng/dầu toàn quốc cho vai trò Lãnh đạo.
class LeaderMapInventoryPage extends ConsumerStatefulWidget {
  const LeaderMapInventoryPage({super.key});

  @override
  ConsumerState<LeaderMapInventoryPage> createState() => _LeaderMapInventoryPageState();
}

class _LeaderMapInventoryPageState extends ConsumerState<LeaderMapInventoryPage> {
  GoogleMapController? _controller;
  Timer? _idleDebounce;
  int _applySerial = 0;
  Set<Marker> _markers = {};
  bool _busy = false;

  /// GPS chờ [GoogleMap] tạo controller (bật cửa hàng rất sớm).
  LatLng? _pendingRetailZoomCenter;

  static const CameraPosition _initial = CameraPosition(
    target: kLeaderMapCenterVietnam,
    zoom: 5.8,
  );

  @override
  void dispose() {
    _idleDebounce?.cancel();
    super.dispose();
  }

  void _scheduleApply() {
    _idleDebounce?.cancel();
    _idleDebounce = Timer(const Duration(milliseconds: 420), () {
      unawaited(_applyLayers());
    });
  }

  Future<void> _animateRetailViewportTo(LatLng center) async {
    final ctrl = _controller;
    if (ctrl == null) return;
    final bounds = leaderLatLngBoundsWithRadiusMeters(center, kLeaderRetailStoresViewportRadiusMeters);
    try {
      await ctrl.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, kLeaderRetailStoresFitBoundsPadding),
      );
    } catch (_) {
      await ctrl.animateCamera(CameraUpdate.newLatLngZoom(center, 16.5));
    }
  }

  /// Khi bật lớp cửa hàng: zoom ~500 m quanh vị trí người dùng để giới hạn tải API theo khung nhìn.
  Future<void> _fitRetailLayerToUserLocation() async {
    if (!mounted) return;
    final outcome = await requestMapUserLocation();
    if (!mounted) return;
    switch (outcome) {
      case MapUserLocationOk(:final position):
        // Bridge AppLatLng → google_maps_flutter LatLng (page này vẫn dùng GoogleMap trực tiếp).
        final ll = LatLng(position.latitude, position.longitude);
        final ctrl = _controller;
        if (ctrl == null) {
          setState(() => _pendingRetailZoomCenter = ll);
          return;
        }
        await _animateRetailViewportTo(ll);
        _scheduleApply();
      case MapUserLocationDenied():
      case MapUserLocationDeniedForever():
      case MapUserLocationServiceDisabled():
        if (mounted) {
          showMapUserLocationOutcomeSnackbar(
            context,
            outcome,
            featureLabel: 'tự zoom 500 m quanh bạn (giảm dữ liệu cửa hàng)',
          );
        }
        _scheduleApply();
    }
  }

  Future<void> _applyLayers() async {
    final ctrl = _controller;
    if (!mounted || ctrl == null) return;
    final serial = ++_applySerial;
    setState(() => _busy = true);
    try {
      final bounds = await ctrl.getVisibleRegion();
      final zoom = await ctrl.getZoomLevel();
      if (!mounted || serial != _applySerial) return;

      final ui = ref.read(leaderMapUiProvider);
      final ne = bounds.northeast;
      final sw = bounds.southwest;
      final north = math.max(ne.latitude, sw.latitude);
      final south = math.min(ne.latitude, sw.latitude);
      final east = math.max(ne.longitude, sw.longitude);
      final west = math.min(ne.longitude, sw.longitude);

      List<StationMapItem> mapItems = const [];
      if (ui.showRetailStores) {
        try {
          final page = await ref.read(leaderMapApiProvider).getStationsInViewport(
                north: north,
                south: south,
                east: east,
                west: west,
                skip: 0,
                take: 100,
              );
          if (!mounted || serial != _applySerial) return;
          mapItems = page.items;
        } catch (_) {
          mapItems = const [];
        }
      }

      final visible = leaderStationsInViewport(mapItems, bounds, zoom);
      final filtered = _filterStations(visible, ui);
      final executives = _resolveExecutiveDistributors(ref, ui);
      final dpr = MediaQuery.devicePixelRatioOf(context);

      await MapStationMarkerFactory.preloadAll(dpr).timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      );
      if (!mounted || serial != _applySerial) return;

      final markers = <Marker>{};

      for (final d in executives) {
        final icon = await LeaderDistributorMapMarker.buildDescriptor(
          displayStatus: d.displayStatusFor(ui.fuel),
          coverageDays: d.coverageDaysFor(ui.fuel),
          devicePixelRatio: dpr,
        );
        if (!mounted || serial != _applySerial) return;
        markers.add(
          Marker(
            markerId: MarkerId('dist_${d.mapKey}'),
            position: d.position,
            icon: icon,
            anchor: LeaderDistributorMapMarker.anchor,
            zIndexInt: 3,
            onTap: () {
              final fuel = ref.read(leaderMapUiProvider).fuel;
              showLeaderDistributorSheet(context, ref, d, fuel: fuel);
            },
          ),
        );
      }

      for (final data in filtered) {
        final s = data.item;
        final av = StationOpenStatus.forMapItem(s);
        final kind = MapStationMarkerFactory.kindFor(
          tone: av.tone,
          stationId: s.stationId,
          cheapSpotlightStationId: null,
        );
        final pin = await MapStationMarkerComposer.buildIcon(
          item: s,
          kind: kind,
          selected: false,
          devicePixelRatio: dpr,
          fuelMode: ui.fuel == LeaderMapFuelFilter.xang ? MapMarkerFuelPriceMode.ron95 : MapMarkerFuelPriceMode.diesel,
          displayBothFuelPrices: false,
        );
        if (!mounted || serial != _applySerial) return;
        markers.add(
          Marker(
            markerId: MarkerId('st_${s.stationId}'),
            position: LatLng(s.latitude, s.longitude),
            icon: googleBitmapFromAppIcon(pin),
            anchor: googleAnchorFromApp(MapStationMarkerComposer.anchor),
            zIndexInt: 2,
            infoWindow: InfoWindow(title: s.stationName, snippet: _leaderRetailMarkerInfoSnippet(s)),
            onTap: () => showLeaderStationSheet(context, ref, s),
          ),
        );
      }

      if (!mounted || serial != _applySerial) return;
      setState(() {
        _markers = markers;
        _busy = false;
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final distAsync = ref.watch(leaderMapDistributorsProvider);
    final ui = ref.watch(leaderMapUiProvider);
    ref.listen(leaderMapDistributorsProvider, (_, _) => _scheduleApply());
    ref.listen(leaderMapUiProvider, (prev, next) {
      if (prev != null && prev.showRetailStores && !next.showRetailStores) {
        if (mounted) setState(() => _pendingRetailZoomCenter = null);
        _scheduleApply();
        return;
      }
      if (prev != null && !prev.showRetailStores && next.showRetailStores) {
        unawaited(_fitRetailLayerToUserLocation());
        return;
      }
      _scheduleApply();
    });

    final topInset = MediaQuery.paddingOf(context).top;
    const toolbarChromeHeight = 52.0;

    return ColoredBox(
      color: MapScreenPalette.screenBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(MapScreenPalette.radiusLg)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GoogleMap(
                          key: const ValueKey('leaderInventoryMap'),
                          initialCameraPosition: _initial,
                          markers: _markers,
                          mapToolbarEnabled: false,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          compassEnabled: true,
                          onMapCreated: (c) {
                            _controller = c;
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              if (!mounted) return;
                              final pending = _pendingRetailZoomCenter;
                              if (pending != null && ref.read(leaderMapUiProvider).showRetailStores) {
                                setState(() => _pendingRetailZoomCenter = null);
                                await _animateRetailViewportTo(pending);
                              }
                              _scheduleApply();
                            });
                          },
                          onCameraIdle: _scheduleApply,
                        ),
                        if (distAsync.isLoading)
                          Container(
                            color: MapScreenPalette.screenBackground.withValues(alpha: 0.85),
                            alignment: Alignment.center,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: LocaDashboardTokens.primaryBlue),
                                SizedBox(height: 12),
                                Text('Đang tải đầu mối…'),
                              ],
                            ),
                          ),
                        if (distAsync.hasError)
                          Positioned(
                            left: 8,
                            right: 8,
                            top: 8,
                            child: Material(
                              color: Colors.orange.shade50.withValues(alpha: 0.92),
                              elevation: 2,
                              borderRadius: BorderRadius.circular(8),
                              child: ListTile(
                                dense: true,
                                title: const Text('Không tải được đầu mối — đang dùng dữ liệu dự phòng.'),
                                trailing: TextButton(
                                  onPressed: () => ref.invalidate(leaderMapDistributorsProvider),
                                  child: const Text('Thử lại'),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_busy)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: LocaDashboardTokens.primaryBlue),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 12,
                    top: topInset + toolbarChromeHeight + 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LeaderRoundMapButton(
                          icon: Icons.add_rounded,
                          onPressed: () async {
                            final c = _controller;
                            if (c == null) return;
                            final z = await c.getZoomLevel();
                            await c.animateCamera(CameraUpdate.zoomTo(z + 1));
                          },
                        ),
                        const SizedBox(height: 10),
                        _LeaderRoundMapButton(
                          icon: Icons.remove_rounded,
                          onPressed: () async {
                            final c = _controller;
                            if (c == null) return;
                            final z = await c.getZoomLevel();
                            await c.animateCamera(CameraUpdate.zoomTo((z - 1).clamp(3, 21)));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: MapScreenPalette.cardWhite.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        _LeaderFuelModeChip(
                          fuel: ui.fuel,
                          onOpenFilters: () => showLeaderMapFilterSheet(context, ref),
                        ),
                        const Spacer(),
                        _LeaderMapToolbarIcon(
                          tooltip: 'Doanh nghiệp đầu mối',
                          icon: Icons.apartment_rounded,
                          selected: ui.showWholesale,
                          onPressed: () {
                            ref.read(leaderMapUiProvider.notifier).state = ui.copyWith(showWholesale: !ui.showWholesale);
                          },
                        ),
                        _LeaderMapToolbarIcon(
                          tooltip: 'Cửa hàng xăng dầu (theo khung nhìn)',
                          icon: Icons.local_gas_station_outlined,
                          selected: ui.showRetailStores,
                          onPressed: () {
                            ref.read(leaderMapUiProvider.notifier).state = ui.copyWith(showRetailStores: !ui.showRetailStores);
                          },
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Bộ lọc nhiên liệu & tồn',
                          onPressed: () => showLeaderMapFilterSheet(context, ref),
                          icon: const Icon(Icons.filter_list_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.65),
                            foregroundColor: LocaDashboardTokens.primaryBlue,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/// Nhãn nhiên liệu đang áp dụng; chạm để mở bộ lọc (đổi Xăng / Dầu).
class _LeaderFuelModeChip extends StatelessWidget {
  const _LeaderFuelModeChip({
    required this.fuel,
    required this.onOpenFilters,
  });

  final LeaderMapFuelFilter fuel;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final isXang = fuel == LeaderMapFuelFilter.xang;
    final color = isXang ? LeaderTheme.xang : LeaderTheme.dau;
    final label = isXang ? 'Xăng' : 'Dầu';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpenFilters,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_gas_station_rounded, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                'Đang xem: ',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: MapScreenPalette.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút bật/tắt lớp trên thanh công cụ (không che bản đồ).
class _LeaderMapToolbarIcon extends StatelessWidget {
  const _LeaderMapToolbarIcon({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: selected
            ? LocaDashboardTokens.primaryBlue.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.65),
        foregroundColor: selected ? LocaDashboardTokens.primaryBlue : MapScreenPalette.textSecondary,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
        // a11y: bump 40 → 48dp Material guideline minimum.
        minimumSize: const Size(48, 48),
      ),
    );
  }
}

class _LeaderRoundMapButton extends StatelessWidget {
  const _LeaderRoundMapButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MapScreenPalette.cardWhite.withValues(alpha: 0.88),
      elevation: 2,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: MapScreenPalette.textPrimary, size: 22),
        ),
      ),
    );
  }
}
