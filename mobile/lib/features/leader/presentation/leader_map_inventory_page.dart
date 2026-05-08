import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/map/app_lat_lng.dart';
import '../../../core/map/app_map.dart';
import '../../../core/map/app_map_camera.dart';
import '../../../core/map/app_map_controller.dart';
import '../../../core/map/app_map_marker.dart';
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
import 'leader_map_retail_shortcuts.dart';
import 'leader_map_ui_provider.dart';
import 'leader_theme.dart';

/// Tooltip map info window: chỉ địa chỉ (tên ở `AppMapInfoWindow.title`).
String _leaderRetailMarkerInfoSnippet(StationMapItem s) {
  final raw = s.shortAddress?.trim();
  if (raw == null || raw.isEmpty) return '';
  return raw.length > 80 ? '${raw.substring(0, 77)}…' : raw;
}

List<LeaderFilteredStation> _filterStations(
  List<StationMapItem> items,
  LeaderMapUiState ui,
) {
  if (!ui.showRetailStores) return const [];
  final out = <LeaderFilteredStation>[];
  for (final s in items) {
    if (!leaderStationHasFuelPriceForFilter(s, ui.fuel)) continue;
    if (ui.selectedServiceCodes.isNotEmpty) {
      final codes = s.activeServiceCodes.map((c) => c.toUpperCase()).toSet();
      if (!ui.selectedServiceCodes.every((sel) => codes.contains(sel.toUpperCase()))) {
        continue;
      }
    }
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
  AppMapController? _controller;
  Timer? _idleDebounce;
  int _applySerial = 0;
  Set<AppMapMarker> _markers = {};
  bool _busy = false;

  /// Bật lớp “vị trí của tôi” trên SDK bản đồ khi app đã có quyền (mặc định [AppMap] tắt).
  bool _myLocationEnabled = false;

  /// Danh sách cửa hàng sau lọc (dùng cho chip Gần nhất / Rẻ nhất).
  List<StationMapItem> _shortcutRetailItems = const [];

  /// GPS chờ map tạo controller (bật cửa hàng rất sớm).
  AppLatLng? _pendingRetailZoomCenter;

  static const AppMapCameraPosition _initial = AppMapCameraPosition(
    target: kLeaderMapCenterVietnam,
    zoom: 5.8,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_refreshMyLocationEnabledFromExistingPermission());
  }

  /// Chỉ [checkPermission] — không xin quyền ở đây (tránh popup khi mở màn hình).
  Future<void> _refreshMyLocationEnabledFromExistingPermission() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (!mounted) return;
      final granted = perm == LocationPermission.whileInUse || perm == LocationPermission.always;
      if (granted && !_myLocationEnabled) {
        setState(() => _myLocationEnabled = true);
      }
    } catch (_) {}
  }

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

  Future<void> _animateRetailViewportTo(AppLatLng center) async {
    final ctrl = _controller;
    if (ctrl == null) return;
    final bounds = leaderLatLngBoundsWithRadiusMeters(center, kLeaderRetailStoresViewportRadiusMeters);
    try {
      await ctrl.animateCamera(
        AppMapCameraUpdate.newLatLngBounds(
          bounds: bounds,
          padding: kLeaderRetailStoresFitBoundsPadding,
        ),
      );
    } catch (_) {
      await ctrl.animateCamera(AppMapCameraUpdate.newLatLngZoom(center, 16.5));
    }
  }

  /// Khi bật lớp cửa hàng: zoom ~500 m quanh vị trí người dùng để giới hạn tải API theo khung nhìn.
  Future<void> _fitRetailLayerToUserLocation() async {
    if (!mounted) return;
    final outcome = await requestMapUserLocation();
    if (!mounted) return;
    switch (outcome) {
      case MapUserLocationOk(:final position):
        if (!mounted) return;
        setState(() {
          _myLocationEnabled = true;
          if (_controller == null) {
            _pendingRetailZoomCenter = position;
          }
        });
        final ctrl = _controller;
        if (ctrl == null) {
          return;
        }
        await _animateRetailViewportTo(position);
        _scheduleApply();
      case MapUserLocationDenied():
      case MapUserLocationDeniedForever():
      case MapUserLocationServiceDisabled():
      case MapUserLocationGnssTimeout():
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
      if (bounds == null || zoom == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }

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

      final markers = <AppMapMarker>{};

      for (final d in executives) {
        final icon = await LeaderDistributorMapMarker.buildIcon(
          displayStatus: d.displayStatusFor(ui.fuel),
          coverageDays: d.coverageDaysFor(ui.fuel),
          devicePixelRatio: dpr,
        );
        if (!mounted || serial != _applySerial) return;
        markers.add(
          AppMapMarker(
            id: AppMapMarkerId('dist_${d.mapKey}'),
            position: d.position,
            icon: icon,
            anchor: LeaderDistributorMapMarker.anchor,
            zIndex: 3,
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
          AppMapMarker(
            id: AppMapMarkerId('st_${s.stationId}'),
            position: AppLatLng(s.latitude, s.longitude),
            icon: pin,
            anchor: MapStationMarkerComposer.anchor,
            zIndex: 2,
            infoWindow: AppMapInfoWindow(title: s.stationName, snippet: _leaderRetailMarkerInfoSnippet(s)),
            onTap: () => showLeaderStationSheet(context, ref, s),
          ),
        );
      }

      if (!mounted || serial != _applySerial) return;
      setState(() {
        _markers = markers;
        _busy = false;
        _shortcutRetailItems = [for (final e in filtered) e.item];
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _focusRetailStation(StationMapItem item, double? _) async {
    final c = _controller;
    if (c != null) {
      try {
        await c.animateCamera(
          AppMapCameraUpdate.newLatLngZoom(
            AppLatLng(item.latitude, item.longitude),
            16.2,
          ),
        );
      } catch (_) {}
    }
    if (!mounted) return;
    await showLeaderStationSheet(context, ref, item);
  }

  @override
  Widget build(BuildContext context) {
    final shellState = StatefulNavigationShell.maybeOf(context);
    final mapTabVisible =
        shellState == null || shellState.currentIndex == kLeaderMapShellBranchIndex;
    if (!mapTabVisible) {
      _controller = null;
      _busy = false;
      _idleDebounce?.cancel();
    }

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
    // Lớp dữ liệu (~52) + khoảng + hàng chip cửa hàng (~50) khi bật lớp cửa hàng.
    final toolbarChromeHeight = ui.showRetailStores ? 118.0 : 52.0;

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
                        if (mapTabVisible)
                          AppMap(
                            key: const ValueKey('leaderInventoryMap'),
                            initialCameraPosition: _initial,
                            markers: _markers,
                            myLocationEnabled: _myLocationEnabled,
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
                          )
                        else
                          const ColoredBox(color: MapScreenPalette.screenBackground),
                        if (mapTabVisible && distAsync.isLoading)
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
                        if (mapTabVisible && distAsync.hasError)
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
                  if (mapTabVisible && _busy)
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
                  if (mapTabVisible)
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
                              if (z == null) return;
                              await c.animateCamera(AppMapCameraUpdate.zoomTo(z + 1));
                            },
                          ),
                          const SizedBox(height: 10),
                          _LeaderRoundMapButton(
                            icon: Icons.remove_rounded,
                            onPressed: () async {
                              final c = _controller;
                              if (c == null) return;
                              final z = await c.getZoomLevel();
                              if (z == null) return;
                              await c.animateCamera(AppMapCameraUpdate.zoomTo((z - 1).clamp(3, 21)));
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
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
                    if (ui.showRetailStores) ...[
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: MapScreenPalette.cardWhite.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _LeaderRetailShortcutChip(
                                  label: 'Gần nhất',
                                  icon: Icons.near_me_outlined,
                                  onTap: () => leaderRetailPresentNearest(
                                    context: context,
                                    items: _shortcutRetailItems,
                                    onPick: _focusRetailStation,
                                  ),
                                ),
                                _LeaderRetailShortcutChip(
                                  label: 'Rẻ nhất',
                                  icon: Icons.payments_outlined,
                                  onTap: () => leaderRetailPresentCheapest(
                                    context: context,
                                    ref: ref,
                                    items: _shortcutRetailItems,
                                    fuel: ui.fuel,
                                    onPick: _focusRetailStation,
                                  ),
                                ),
                                _LeaderRetailShortcutChip(
                                  label: 'Dịch vụ',
                                  icon: Icons.room_service_outlined,
                                  onTap: () => showLeaderRetailServicesFilterSheet(context, ref),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

/// Chip lối tắt (Gần nhất / Rẻ nhất / Dịch vụ) trên bản đồ cửa hàng Lãnh đạo.
class _LeaderRetailShortcutChip extends StatelessWidget {
  const _LeaderRetailShortcutChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: LocaDashboardTokens.primaryBlue),
        label: Text(label),
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: MapScreenPalette.textPrimary,
            ),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        side: BorderSide(color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.35)),
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
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
