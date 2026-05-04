import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/map/app_lat_lng.dart';
import '../../../core/map/app_lat_lng_bounds.dart';
import '../../../core/map/app_map.dart';
import '../../../core/map/app_map_camera.dart';
import '../../../core/map/app_map_controller.dart';
import '../../../core/map/app_map_marker.dart';
import '../../map/presentation/map_station_marker_factory.dart';
import '../domain/stock_map_stock_status.dart';
import 'inventory_stock_map_config.dart';
import 'stock_map_station_pin.dart';

StationMapMarkerAssetKind _markerKindForStock(StockMapStockStatus status) => switch (status) {
      StockMapStockStatus.out => StationMapMarkerAssetKind.closed,
      StockMapStockStatus.low => StationMapMarkerAssetKind.cheap,
      StockMapStockStatus.normal => StationMapMarkerAssetKind.open,
    };

/// Map + API-driven markers (provider-agnostic — render qua `AppMap`,
/// dùng cùng PNG assets như [MapStationMarkerFactory]).
///
/// [markerLayerKey] should change when the fuel group changes so markers and camera
/// refit behave like a fresh layer.
class InventoryStockMapGoogleView extends StatefulWidget {
  const InventoryStockMapGoogleView({
    super.key,
    this.pins = const [],
    this.markerLayerKey,
    this.onMarkerTap,
  });

  final List<StockMapStationPin> pins;
  final Key? markerLayerKey;
  final ValueChanged<StockMapStationPin>? onMarkerTap;

  @override
  State<InventoryStockMapGoogleView> createState() => _InventoryStockMapGoogleViewState();
}

class _InventoryStockMapGoogleViewState extends State<InventoryStockMapGoogleView> {
  AppMapController? _controller;
  Set<AppMapMarker> _markers = {};
  bool _markersBusy = false;
  Timer? _cameraIdleDebounce;
  Offset? _hoangSaScreen;
  Offset? _truongSaScreen;

  /// GPS hợp lệ — bật chấm "vị trí của tôi" và ưu tiên zoom 1 km quanh đây.
  bool _locationGranted = false;

  /// Tâm GPS sau khi lấy được (dùng khi `AppMapCameraUpdate.newLatLngBounds` lỗi).
  AppLatLng? _userLocation;

  /// GPS xong trước khi map tạo controller.
  AppLatLngBounds? _pendingUserFitBounds;

  AppMapCameraPosition _initialCamera = const AppMapCameraPosition(
    target: AppLatLng(
      InventoryStockMapConfig.initialLatitude,
      InventoryStockMapConfig.initialLongitude,
    ),
    zoom: InventoryStockMapConfig.initialZoom,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_prepareUserLocation());
  }

  /// Hộp lat/lng ~2×[radiusMeters] (tâm ± radius), cùng mô hình `MapStationMapBody`.
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
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      final here = AppLatLng(pos.latitude, pos.longitude);
      final fit = _boundsWithRadiusMeters(here, InventoryStockMapConfig.userLocationRadiusMeters);
      setState(() {
        _locationGranted = true;
        _userLocation = here;
        _initialCamera = AppMapCameraPosition(target: here, zoom: 15);
      });
      final ctrl = _controller;
      if (ctrl != null) {
        try {
          await ctrl.animateCamera(AppMapCameraUpdate.newLatLngBounds(
            bounds: fit,
            padding: InventoryStockMapConfig.fitBoundsPadding,
          ));
        } catch (_) {
          await ctrl.animateCamera(AppMapCameraUpdate.newLatLngZoom(here, 15));
        }
        if (mounted) await _syncMaritimeLabelScreens();
      } else {
        _pendingUserFitBounds = fit;
      }
    } catch (_) {
      // Không bắt buộc GPS — `onMapCreated` sẽ fit theo trạm nếu có.
    }
  }

  @override
  void dispose() {
    _cameraIdleDebounce?.cancel();
    super.dispose();
  }

  int _pinsFingerprint(List<StockMapStationPin> pins) {
    var h = pins.length;
    for (final p in pins) {
      h = Object.hash(
        h,
        p.stationId,
        p.point.latitude,
        p.point.longitude,
        p.status,
      );
    }
    return h;
  }

  @override
  void didUpdateWidget(InventoryStockMapGoogleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pinsChanged =
        _pinsFingerprint(oldWidget.pins) != _pinsFingerprint(widget.pins);
    final layerChanged = oldWidget.markerLayerKey != widget.markerLayerKey;
    if (pinsChanged || layerChanged) {
      unawaited(_rebuildMarkersAndFit());
    }
  }

  Future<void> _rebuildMarkersAndFit() async {
    final c = _controller;
    await _applyMarkers();
    if (c != null && mounted && widget.pins.isNotEmpty && _userLocation == null) {
      await _fitCameraToPins(c, widget.pins);
    }
    if (mounted) await _syncMaritimeLabelScreens();
  }

  Future<void> _applyMarkers() async {
    if (!mounted) return;
    setState(() => _markersBusy = true);
    try {
      final next = await _buildMarkers(widget.pins);
      if (!mounted) return;
      setState(() {
        _markers = next;
        _markersBusy = false;
      });
    } catch (_) {
      if (mounted) setState(() => _markersBusy = false);
    }
  }

  Future<Set<AppMapMarker>> _buildMarkers(List<StockMapStationPin> pins) async {
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
    for (var i = 0; i < pins.length; i += batch) {
      final end = i + batch > pins.length ? pins.length : i + batch;
      final slice = pins.sublist(i, end);
      if (!mounted) return markers;
      for (var j = 0; j < slice.length; j++) {
        final pin = slice[j];
        final globalIndex = i + j;
        final kind = _markerKindForStock(pin.status);
        AppMapMarkerIcon? icon = MapStationMarkerFactory.iconFromCache(
          kind: kind,
          devicePixelRatio: dpr,
        );
        icon ??= await MapStationMarkerFactory.iconFor(kind: kind, devicePixelRatio: dpr);
        if (!mounted) return markers;
        final markerKey = pin.stationId?.toString() ??
            '${pin.point.latitude}_${pin.point.longitude}_$globalIndex';
        markers.add(
          AppMapMarker(
            id: AppMapMarkerId('inv_stock_$markerKey'),
            position: pin.point,
            icon: icon,
            anchor: MapStationMarkerFactory.anchor,
            consumeTapEvents: true,
            infoWindow: AppMapInfoWindow(
              title: pin.stationName,
              snippet: pin.address?.trim().isNotEmpty == true ? pin.address!.trim() : '',
            ),
            onTap: widget.onMarkerTap == null ? null : () => widget.onMarkerTap!(pin),
          ),
        );
      }
    }
    return markers;
  }

  Future<void> _fitCameraToPins(AppMapController controller, List<StockMapStationPin> pins) async {
    if (pins.isEmpty) return;
    final n = math.min(pins.length, 200);
    var minLat = pins[0].point.latitude;
    var maxLat = pins[0].point.latitude;
    var minLng = pins[0].point.longitude;
    var maxLng = pins[0].point.longitude;
    for (var i = 1; i < n; i++) {
      final p = pins[i].point;
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
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
            padding: InventoryStockMapConfig.fitBoundsPadding,
          ))
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      // ignore
    } catch (_) {
      final t = pins.first.point;
      try {
        await controller.animateCamera(AppMapCameraUpdate.newLatLngZoom(t, 10));
      } catch (_) {}
    }
  }

  Future<void> _syncMaritimeLabelScreens() async {
    final c = _controller;
    if (c == null || !mounted) return;
    try {
      final h = await c.getScreenCoordinate(InventoryStockMapConfig.maritimeHoangSa);
      final t = await c.getScreenCoordinate(InventoryStockMapConfig.maritimeTruongSa);
      if (!mounted) return;
      setState(() {
        _hoangSaScreen = h;
        _truongSaScreen = t;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hoangSaScreen = null;
          _truongSaScreen = null;
        });
      }
    }
  }

  void _scheduleCameraIdle() {
    _cameraIdleDebounce?.cancel();
    _cameraIdleDebounce = Timer(const Duration(milliseconds: 120), () {
      unawaited(_syncMaritimeLabelScreens());
    });
  }

  Future<void> _nudgeZoom(double delta) async {
    final c = _controller;
    if (c == null) return;
    try {
      final z = await c.getZoomLevel();
      if (z == null) return;
      final double next = (z + delta).clamp(
        InventoryStockMapConfig.minZoom,
        InventoryStockMapConfig.maxZoom,
      );
      if ((next - z).abs() > 0.01) {
        await c.animateCamera(AppMapCameraUpdate.zoomTo(next));
      }
    } catch (_) {}
  }

  static const TextStyle _maritimeTextStyle = TextStyle(
    fontSize: 12.5,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: Color(0xE6FFFFFF),
    shadows: [
      Shadow(offset: Offset(0, 0.5), blurRadius: 2, color: Colors.black45),
    ],
  );

  Widget _maritimeChip(String text) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _maritimeTextStyle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: AppMap(
                  initialCameraPosition: _initialCamera,
                  markers: _markers,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                  myLocationEnabled: _locationGranted,
                  minZoom: InventoryStockMapConfig.minZoom,
                  maxZoom: InventoryStockMapConfig.maxZoom,
                  onMapCreated: (c) async {
                    _controller = c;
                    await _applyMarkers();
                    final pendingUser = _pendingUserFitBounds;
                    if (pendingUser != null) {
                      _pendingUserFitBounds = null;
                      try {
                        await c.animateCamera(
                          AppMapCameraUpdate.newLatLngBounds(
                            bounds: pendingUser,
                            padding: InventoryStockMapConfig.fitBoundsPadding,
                          ),
                        );
                      } catch (_) {
                        final u = _userLocation;
                        if (u != null) {
                          await c.animateCamera(AppMapCameraUpdate.newLatLngZoom(u, 15));
                        }
                      }
                    } else if (_userLocation == null && widget.pins.isNotEmpty) {
                      await _fitCameraToPins(c, widget.pins);
                    }
                    if (mounted) await _syncMaritimeLabelScreens();
                  },
                  onCameraIdle: _scheduleCameraIdle,
                ),
              ),
              IgnorePointer(
                ignoring: true,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_hoangSaScreen != null)
                      Positioned(
                        left: _hoangSaScreen!.dx - 100,
                        top: _hoangSaScreen!.dy - 22,
                        width: 200,
                        child: _maritimeChip('Quần đảo Hoàng Sa'),
                      ),
                    if (_truongSaScreen != null)
                      Positioned(
                        left: _truongSaScreen!.dx - 100,
                        top: _truongSaScreen!.dy - 22,
                        width: 200,
                        child: _maritimeChip('Quần đảo Trường Sa'),
                      ),
                  ],
                ),
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
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: constraints.maxWidth < 360 ? 6 : 10,
                    bottom: MediaQuery.paddingOf(context).bottom + 8,
                  ),
                  child: Material(
                    elevation: 2,
                    shadowColor: Colors.black26,
                    color: surface.withValues(alpha: 0.94),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * 0.35,
                      ),
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Phóng to',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.add_rounded),
                              onPressed: () => unawaited(_nudgeZoom(1)),
                            ),
                            Divider(
                              height: 1,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.4),
                            ),
                            IconButton(
                              tooltip: 'Thu nhỏ',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.remove_rounded),
                              onPressed: () => unawaited(_nudgeZoom(-1)),
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
      },
    );
  }
}
