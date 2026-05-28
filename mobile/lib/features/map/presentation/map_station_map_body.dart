import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/map/app_lat_lng.dart';
import '../../../core/map/app_lat_lng_bounds.dart';
import '../../../core/map/app_map.dart';
import '../../../core/map/app_map_camera.dart';
import '../../../core/map/app_map_controller.dart';
import '../../../core/map/app_map_marker.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../stations/station_open_status.dart';
import 'map_providers.dart';
import 'map_station_marker_composer.dart';
import 'map_station_marker_factory.dart';
import 'station_map_preview_sheet.dart';

/// Mặc định khi chưa có GPS / bị từ chối quyền.
const AppLatLng kVietnamMapCenter = AppLatLng(15.9266657, 107.9650855);

/// Bán kính (m) quanh GPS cho khung camera mặc định (~500 m quanh vị trí người dùng).
const double kDefaultMapUserRadiusMeters = 500;

/// Viền quanh vùng `AppMapCameraUpdate.newLatLngBounds` (logical px).
const double kDefaultMapFitPadding = 56;

/// Bản đồ cây xăng: ưu tiên zoom quanh vị trí người dùng; chỉ vẽ marker trong khung nhìn + giới hạn theo zoom (giảm tải Maps SDK / Flogger).
///
/// **Shell người dân (`/map`):** khi có GPS, camera mặc định fit khoảng [kDefaultMapUserRadiusMeters] (~500 m) quanh vị trí.
/// [skipEmptyViewportRecovery] mặc định `true` để **không** tự bay tới "mẫu trạm" toàn quốc khi trong 500 m không có cây xăng — giữ đúng khung quanh người dùng.
class MapStationMapBody extends StatefulWidget {
  const MapStationMapBody({
    super.key,
    required this.allItems,
    this.overlayStation,
    this.cheapSpotlightStationId,
    this.topOverlay,
    this.onMapControllerReady,
    this.externalHighlightStationId,
    this.onDismissExternalHighlight,
    this.mapBottomPadding = 0,
    this.mapTopPadding = 0,
    this.fuelPriceMode = MapMarkerFuelPriceMode.ron95,
    this.skipEmptyViewportRecovery = true,
    this.onCameraViewportChanged,
  });

  final List<StationMapItem> allItems;

  /// Extra marker (e.g. global nearest outside [allItems]) until parent clears it.
  final StationMapItem? overlayStation;

  /// Station id from "giá rẻ nhất" spotlight — [MapStationMarkerFactory] maps to cheap asset when open.
  final int? cheapSpotlightStationId;

  /// Chip cảnh báo (từ khóa / truncate) — đặt phía trên bản đồ.
  final Widget? topOverlay;

  /// Để [MapShellPage] animate camera (tìm cây xăng / điều hướng).
  final void Function(AppMapController controller)? onMapControllerReady;

  /// Highlight from search / discovery (parent-owned).
  final int? externalHighlightStationId;

  /// Clear parent highlight when user taps empty map.
  final VoidCallback? onDismissExternalHighlight;

  /// Tránh nút nổi / bottom sheet che khuất mép bản đồ.
  final double mapBottomPadding;

  /// Vùng UI phủ phía trên (header + tìm kiếm + chip) — đẩy UI bản đồ / controls xuống.
  final double mapTopPadding;

  /// Giá hiển thị trên marker (RON95 / Diesel).
  final MapMarkerFuelPriceMode fuelPriceMode;

  /// Khi `false`, nếu viewport không có marker nhưng [allItems] không rỗng, tự fit camera tới vùng có trạm (hữu ích cho bản đồ "toàn quốc").
  /// Mặc định `true` cho UX người dân: giữ khung ~500 m quanh GPS.
  final bool skipEmptyViewportRecovery;

  /// Phase 2.B-viewport: bắn (zoom, bounds) sau mỗi lần camera idle (đã debounce 400ms).
  /// Shell cập nhật `mapViewportProvider` để fetch viewport-aware.
  final void Function(double zoom, AppLatLngBounds bounds)? onCameraViewportChanged;

  @override
  State<MapStationMapBody> createState() => _MapStationMapBodyState();
}

class _MapStationMapBodyState extends State<MapStationMapBody> {
  AppMapController? _controller;
  Timer? _idleDebounce;
  bool _locationGranted = false;

  Set<AppMapMarker> _markers = {};
  /// Ban đầu false: tránh overlay xoay vĩnh viễn nếu lần apply đầu bị hủy / treo trước khi tắt busy.
  bool _markersBusy = false;
  int _applySerial = 0;

  /// Highlighted pin (larger + ring) while the preview sheet is open or until map background tap.
  int? _selectedStationId;

  /// Tránh lặp vô hạn: mỗi [allItems] fingerprint chỉ tự fit camera một lần khi viewport trống.
  int _viewportRecoveryFingerprint = 0;

  AppMapCameraPosition _initialCamera = const AppMapCameraPosition(
    target: kVietnamMapCenter,
    zoom: 5.6,
  );

  /// GPS xong trước khi map tạo controller — fit bounds khi `onMapCreated`.
  AppLatLngBounds? _pendingFitBounds;

  /// [getLastKnownPosition] + [getCurrentPosition] có thể gọi [_applyUserLocation] liên tiếp;
  /// chỉ lần cuối mới animate camera (tránh hai `camera#move` dồn khi máy nhanh).
  int _locationApplyGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareUserLocation());
  }

  @override
  void dispose() {
    _idleDebounce?.cancel();
    super.dispose();
  }

  Future<void> _prepareUserLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return;
      }
      setState(() => _locationGranted = true);

      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        _applyUserLocation(AppLatLng(last.latitude, last.longitude));
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      _applyUserLocation(AppLatLng(pos.latitude, pos.longitude));
    } catch (_) {
      // Không bắt buộc GPS — giữ khung mặc định.
    }
  }

  /// Khung [kDefaultMapUserRadiusMeters] m mỗi hướng từ tâm (bán kính nhìn quanh GPS).
  void _applyUserLocation(AppLatLng here) {
    if (!mounted) return;
    final gen = ++_locationApplyGeneration;
    final w = MediaQuery.sizeOf(context).width;
    final spanMeters = 2 * kDefaultMapUserRadiusMeters;
    final zoom = _zoomForSpanMetersAtLat(here.latitude, w, spanMeters);
    final fit = _boundsWithRadiusMeters(here, kDefaultMapUserRadiusMeters);
    setState(() {
      _initialCamera = AppMapCameraPosition(target: here, zoom: zoom);
    });
    final ctrl = _controller;
    if (ctrl != null) {
      unawaited(() async {
        if (gen != _locationApplyGeneration) return;
        try {
          await ctrl.animateCamera(AppMapCameraUpdate.newLatLngBounds(
            bounds: fit,
            padding: kDefaultMapFitPadding,
          ));
        } catch (_) {
          try {
            if (gen != _locationApplyGeneration) return;
            await ctrl.animateCamera(AppMapCameraUpdate.newLatLngZoom(here, zoom));
          } catch (_) {}
        }
        if (mounted && gen == _locationApplyGeneration) {
          _kickApplyMarkersSoon();
        }
      }());
    } else {
      _pendingFitBounds = fit;
    }
  }

  /// Zoom Web Mercator: bề ngang [spanMeters] khớp với [mapWidthLogicalPx].
  static double _zoomForSpanMetersAtLat(double latitude, double mapWidthLogicalPx, double spanMeters) {
    if (mapWidthLogicalPx < 80 || spanMeters < 50) {
      return 15;
    }
    final phi = latitude * math.pi / 180.0;
    final cosPhi = math.cos(phi).abs().clamp(0.02, 1.0);
    const scale = 156543.03392;
    final ratio = (scale * cosPhi * mapWidthLogicalPx) / spanMeters;
    if (ratio <= 1) {
      return 4;
    }
    final z = math.log(ratio) / math.ln2;
    return z.clamp(4.0, 20.5);
  }

  /// Hộp lat/lng có cạnh ~2×[radiusMeters] (tâm ± radius), gần đúng "trong vòng radius mét".
  static AppLatLngBounds _boundsWithRadiusMeters(AppLatLng center, double radiusMeters) {
    final latRad = center.latitude * math.pi / 180;
    final cosLat = math.cos(latRad).clamp(0.02, 1.0);
    const mPerDegLat = 111320.0;
    final mPerDegLng = 111320.0 * cosLat;
    final dLat = radiusMeters / mPerDegLat;
    final dLng = radiusMeters / mPerDegLng;
    return AppLatLngBounds(
      southwest: AppLatLng(center.latitude - dLat, center.longitude - dLng),
      northeast: AppLatLng(center.latitude + dLat, center.longitude + dLng),
    );
  }

  /// Tính cap marker từ ĐỘ RỘNG BBOX (degree) thay vì tin số zoom — Goong/MapLibre
  /// adapter trên một số thiết bị báo zoom stale (vd luôn trả 15.78 dù user zoom
  /// ra toàn quốc). Bbox luôn đúng vì map provider tự cập nhật.
  ///
  /// Tham chiếu: vĩ độ Việt Nam ~16°, 1° ≈ 110 km.
  static int _capForBounds(AppLatLngBounds bounds) {
    final latSpan = (bounds.northeast.latitude - bounds.southwest.latitude).abs();
    final lngSpan = (bounds.northeast.longitude - bounds.southwest.longitude).abs();
    final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;

    if (maxSpan > 4.0) return 0;     // > 440 km — toàn quốc / liên vùng → ẩn
    if (maxSpan > 1.5) return 420;   // 165-440 km — liên tỉnh
    if (maxSpan > 0.6) return 650;   // 66-165 km — 1-2 tỉnh
    if (maxSpan > 0.25) return 900;  // 27-66 km — thành phố / liên thành phố
    if (maxSpan > 0.08) return 360;  // 9-27 km — quận / huyện
    if (maxSpan > 0.03) return 220;  // 3-9 km — phường / xã
    return 160;                       // < 3 km — street view
  }

  static double _dist2(StationMapItem a, AppLatLng c) {
    final dx = a.latitude - c.latitude;
    final dy = a.longitude - c.longitude;
    return dx * dx + dy * dy;
  }

  static List<StationMapItem> _itemsInView(
    List<StationMapItem> all,
    AppLatLngBounds bounds,
    double zoom,
  ) {
    final inside = <StationMapItem>[];
    for (final e in all) {
      final p = AppLatLng(e.latitude, e.longitude);
      if (bounds.contains(p)) {
        inside.add(e);
      }
    }
    final cap = math.min(_capForBounds(bounds), 2000);
    if (inside.length <= cap) {
      return inside;
    }
    final sw = bounds.southwest;
    final ne = bounds.northeast;
    final c = AppLatLng((sw.latitude + ne.latitude) / 2, (sw.longitude + ne.longitude) / 2);
    inside.sort((a, b) => _dist2(a, c).compareTo(_dist2(b, c)));
    return inside.take(cap).toList(growable: false);
  }

  static int _fingerprint(List<StationMapItem> items) {
    var h = items.length;
    for (final e in items) {
      h = Object.hash(
        h,
        e.stationId,
        e.latitude,
        e.longitude,
        e.openNow,
        e.openStatus,
        e.openingTime,
        e.closingTime,
      );
    }
    return h;
  }

  static int _fingerprintAll(List<StationMapItem> all) => _fingerprint(all);

  /// Debounce chỉ dùng cho [onCameraIdle] (kéo map liên tục). Không dùng cho lần "đá" đầu tiên,
  /// vì mỗi lần [_scheduleCameraIdle] đều **hủy** timer cũ — nếu idle/camera bắn liên tục (GPS
  /// [animateCamera]) thì timer có thể **không bao giờ** chạy → không vẽ marker.
  void _scheduleCameraIdle() {
    _idleDebounce?.cancel();
    _idleDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_applyVisibleMarkers(showBusy: true));
    });
  }

  /// Một lần sau frame + **một** lần dự phòng trễ (trước đây hai post-frame gọi apply liên tiếp
  /// làm [_applySerial] hủy lần trước → build marker lặp / chậm dù API đã xong).
  void _kickApplyMarkersSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_applyVisibleMarkers(showBusy: true));
    });
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (mounted) unawaited(_applyVisibleMarkers(showBusy: true));
    });
  }

  /// [showBusy]: when false, skips full-screen marker loading overlay (selection-only refresh).
  Future<void> _applyVisibleMarkers({bool showBusy = true}) async {
    final c = _controller;
    if (!mounted) return;
    if (c == null) {
      if (showBusy) setState(() => _markersBusy = false);
      return;
    }
    final serial = ++_applySerial;
    try {
      var bounds = await c.getVisibleRegion();
      var zoom = await c.getZoomLevel();
      if (!mounted || serial != _applySerial) return;
      if (bounds == null || zoom == null) {
        if (showBusy) setState(() => _markersBusy = false);
        return;
      }
      // Phase 2.B-viewport: thông báo (zoom, bounds) cho shell — kích hoạt fetch
      // mới (markers in bounds / province clusters) tùy zoom.
      widget.onCameraViewportChanged?.call(zoom, bounds);
      var visible = _withOverlayStation(_itemsInView(widget.allItems, bounds, zoom));
      if (kDebugMode) {
        final b = bounds;
        final inBoundsCount =
            widget.allItems.where((m) => b.contains(AppLatLng(m.latitude, m.longitude))).length;
        final latSpan = (b.northeast.latitude - b.southwest.latitude).abs();
        final lngSpan = (b.northeast.longitude - b.southwest.longitude).abs();
        final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;
        debugPrint(
          '[map] idle zoom=${zoom.toStringAsFixed(2)} '
          'span=${maxSpan.toStringAsFixed(3)}° '
          'allItems=${widget.allItems.length} '
          'inBounds=$inBoundsCount '
          'visibleAfterCap=${visible.length} '
          'cap=${_capForBounds(b)}',
        );
      }
      if (!widget.skipEmptyViewportRecovery &&
          visible.isEmpty &&
          widget.allItems.isNotEmpty &&
          _viewportRecoveryFingerprint != _fingerprintAll(widget.allItems)) {
        final fitted = await _fitCameraToStationSample(c, widget.allItems)
            .timeout(const Duration(seconds: 14), onTimeout: () => false);
        if (!mounted || serial != _applySerial) return;
        _viewportRecoveryFingerprint = _fingerprintAll(widget.allItems);
        if (fitted) {
          try {
            final b2 = await c.getVisibleRegion();
            final z2 = await c.getZoomLevel();
            if (b2 != null && z2 != null) {
              bounds = b2;
              zoom = z2;
              visible = _withOverlayStation(_itemsInView(widget.allItems, bounds, zoom));
            }
          } catch (_) {}
        }
      }
      if (showBusy) {
        setState(() => _markersBusy = true);
      }
      final built = await _buildMarkers(visible, _effectiveHighlightId());
      if (!mounted || serial != _applySerial) return;
      setState(() {
        _markers = built;
        if (showBusy) {
          _markersBusy = false;
        }
      });
    } catch (_) {
      if (!mounted || serial != _applySerial) return;
      // Giữ marker cũ (nếu có); thử lại sau khi Surface/Maps ổn định.
      if (showBusy) {
        setState(() => _markersBusy = false);
      }
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (!mounted || serial != _applySerial) return;
        _scheduleCameraIdle();
      });
    }
  }

  Future<void> _onStationMarkerTap(StationMapItem e) async {
    if (!context.mounted) return;
    setState(() => _selectedStationId = e.stationId);
    unawaited(_applyVisibleMarkers(showBusy: false));
    await showStationMapPreviewSheet(context: context, station: e);
    if (!mounted) return;
    setState(() => _selectedStationId = null);
    unawaited(_applyVisibleMarkers(showBusy: false));
  }

  int? _effectiveHighlightId() =>
      widget.externalHighlightStationId ?? _selectedStationId;

  List<StationMapItem> _withOverlayStation(List<StationMapItem> visible) {
    final o = widget.overlayStation;
    if (o == null) return visible;
    if (visible.any((e) => e.stationId == o.stationId)) return visible;
    return [...visible, o];
  }

  /// Khi GPS/độ zoom đặt khung nhìn nơi không có cây xăng, kéo camera tới vùng có dữ liệu (một lần / tập cây xăng đã tải).
  Future<bool> _fitCameraToStationSample(
    AppMapController controller,
    List<StationMapItem> all,
  ) async {
    if (all.isEmpty) return false;
    final n = math.min(all.length, 120);
    var minLat = all[0].latitude;
    var maxLat = all[0].latitude;
    var minLng = all[0].longitude;
    var maxLng = all[0].longitude;
    for (var i = 1; i < n; i++) {
      final e = all[i];
      minLat = math.min(minLat, e.latitude);
      maxLat = math.max(maxLat, e.latitude);
      minLng = math.min(minLng, e.longitude);
      maxLng = math.max(maxLng, e.longitude);
    }
    const padDeg = 0.03;
    if ((maxLat - minLat) < 0.008) {
      minLat -= 0.06;
      maxLat += 0.06;
    }
    if ((maxLng - minLng) < 0.008) {
      minLng -= 0.06;
      maxLng += 0.06;
    }
    final fit = AppLatLngBounds(
      southwest: AppLatLng(minLat - padDeg, minLng - padDeg),
      northeast: AppLatLng(maxLat + padDeg, maxLng + padDeg),
    );
    try {
      await controller
          .animateCamera(AppMapCameraUpdate.newLatLngBounds(
            bounds: fit,
            padding: kDefaultMapFitPadding,
          ))
          .timeout(const Duration(seconds: 12));
      return true;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Set<AppMapMarker>> _buildMarkers(
    List<StationMapItem> items,
    int? selectedStationId,
  ) async {
    if (!mounted) return {};
    final dpr = MediaQuery.devicePixelRatioOf(context);
    try {
      await MapStationMarkerFactory.preloadAll(dpr).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      MapStationMarkerFactory.invalidateCache();
    } catch (_) {
      MapStationMarkerFactory.invalidateCache();
    }

    const batch = 80;
    final markers = <AppMapMarker>{};
    for (var i = 0; i < items.length; i += batch) {
      final end = i + batch > items.length ? items.length : i + batch;
      final slice = items.sublist(i, end);
      if (!mounted) return markers;
      for (final e in slice) {
        final selected = e.stationId == selectedStationId;
        final tone = StationOpenStatus.forMapItem(e).tone;
        final kind = MapStationMarkerFactory.kindFor(
          tone: tone,
          stationId: e.stationId,
          cheapSpotlightStationId: widget.cheapSpotlightStationId,
        );
        final icon = await MapStationMarkerComposer.buildIcon(
          item: e,
          kind: kind,
          selected: selected,
          devicePixelRatio: dpr,
          fuelMode: widget.fuelPriceMode,
        );
        if (!mounted) return markers;
        markers.add(
          AppMapMarker(
            id: AppMapMarkerId('station_${e.stationId}'),
            position: AppLatLng(e.latitude, e.longitude),
            icon: icon,
            anchor: MapStationMarkerComposer.anchor,
            zIndex: selected ? 1000 : 0,
            consumeTapEvents: true,
            infoWindow: AppMapInfoWindow(
              title: e.stationName,
              snippet: MapStationMarkerFactory.infoSnippet(e),
            ),
            onTap: () => unawaited(_onStationMarkerTap(e)),
          ),
        );
      }
    }
    return markers;
  }

  @override
  void didUpdateWidget(MapStationMapBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final itemsChanged = _fingerprintAll(oldWidget.allItems) != _fingerprintAll(widget.allItems);
    final highlightChanged =
        oldWidget.externalHighlightStationId != widget.externalHighlightStationId;
    final overlayChanged = oldWidget.overlayStation?.stationId != widget.overlayStation?.stationId;
    final cheapChanged = oldWidget.cheapSpotlightStationId != widget.cheapSpotlightStationId;
    final fuelChanged = oldWidget.fuelPriceMode != widget.fuelPriceMode;
    final recoveryChanged = oldWidget.skipEmptyViewportRecovery != widget.skipEmptyViewportRecovery;
    final padChanged = oldWidget.mapBottomPadding != widget.mapBottomPadding;
    final topPadChanged = oldWidget.mapTopPadding != widget.mapTopPadding;
    if (itemsChanged) {
      _viewportRecoveryFingerprint = 0;
    }
    if (itemsChanged ||
        highlightChanged ||
        overlayChanged ||
        cheapChanged ||
        fuelChanged ||
        recoveryChanged) {
      _kickApplyMarkersSoon();
    } else if (padChanged || topPadChanged) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AppMap(
          initialCameraPosition: _initialCamera,
          markers: _markers,
          padding: EdgeInsets.only(
            bottom: widget.mapBottomPadding,
            top: widget.mapTopPadding + 8,
          ),
          zoomControlsEnabled: false,
          compassEnabled: true,
          myLocationEnabled: _locationGranted,
          myLocationButtonEnabled: false,
          onTap: (_) {
            widget.onDismissExternalHighlight?.call();
            if (_selectedStationId == null &&
                widget.externalHighlightStationId == null) {
              return;
            }
            setState(() => _selectedStationId = null);
            unawaited(_applyVisibleMarkers(showBusy: false));
          },
          onMapCreated: (c) {
            _controller = c;
            widget.onMapControllerReady?.call(c);
            _kickApplyMarkersSoon();
            final pending = _pendingFitBounds;
            if (pending != null) {
              _pendingFitBounds = null;
              unawaited((() async {
                try {
                  await c.animateCamera(AppMapCameraUpdate.newLatLngBounds(
                    bounds: pending,
                    padding: kDefaultMapFitPadding,
                  ));
                } catch (_) {
                  // Fallback khi fit bounds fail — và bản thân fallback cũng có thể fail
                  // (vd MapLibre Android channel chưa attach ngay sau onMapCreated trong
                  // chu kỳ hot-reload). Nuốt lỗi để không crash; _kickApplyMarkersSoon sẽ
                  // vẫn chạy + camera idle tiếp theo sẽ tự refresh.
                  try {
                    final t = _initialCamera.target;
                    await c.animateCamera(AppMapCameraUpdate.newLatLngZoom(t, _initialCamera.zoom));
                  } catch (_) {/* swallow plugin race */}
                }
                if (mounted) _kickApplyMarkersSoon();
              })());
            }
          },
          onCameraIdle: _scheduleCameraIdle,
        ),
        if (_markersBusy)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (widget.topOverlay != null) widget.topOverlay!,
      ],
    );
  }
}
