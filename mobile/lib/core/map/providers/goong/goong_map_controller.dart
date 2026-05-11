import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' show Offset;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../app_lat_lng.dart';
import '../../app_lat_lng_bounds.dart';
import '../../app_map_camera.dart';
import '../../app_map_controller.dart';
import 'goong_value_codec.dart';

class GoongAppMapController implements AppMapController {
  final ml.MapLibreMapController _delegate;

  /// Hoàn thành sau [GoongMapWidget] `onStyleLoaded` + vài frame (MapLibre iOS
  /// crash `std::domain_error` nếu `camera#move` chạy khi style/chưa layout).
  final Future<void>? _primedForCameraOps;

  /// Fallback khi `_delegate.cameraPosition` còn null — trường này chỉ populate
  /// sau camera event đầu tiên trên MapLibre, không sẵn ngay sau onMapCreated /
  /// onStyleLoadedCallback (khác Google: cameraPosition luôn có giá trị).
  /// Caller (MapStationMapBody, …) sẽ thấy `getZoomLevel()` không-null và build
  /// được marker ngay từ frame đầu thay vì phải đợi pan/zoom.
  final AppMapCameraPosition _initialCameraPosition;

  GoongAppMapController(
    this._delegate,
    this._initialCameraPosition, {
    Future<void>? primedForCameraOps,
  }) : _primedForCameraOps = primedForCameraOps;

  ml.MapLibreMapController get rawController => _delegate;

  static bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// MapLibre iOS: `camera#move` → `MLNAltitudeForZoomLevel(..., mapView.frame.size)`.
  /// Race style/layout → `std::domain_error` (C++, không bắt Dart). Chờ [primed]
  /// (style + layout từ [GoongMapWidget]) rồi thêm tối thiểu một frame.
  Future<void> _waitForMapSurfaceLayout() async {
    final primed = _primedForCameraOps;
    var styleReady = false;
    if (primed != null) {
      try {
        await primed.timeout(const Duration(seconds: 18));
        styleReady = true;
      } catch (_) {
        // timeout: vẫn thử move; thêm chờ dài hơn bên dưới
      }
    }
    if (styleReady) {
      await SchedulerBinding.instance.endOfFrame;
      await SchedulerBinding.instance.endOfFrame;
      if (_isIos) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      return;
    }
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;
    if (_isIos) {
      await Future<void>.delayed(const Duration(milliseconds: 24));
    }
  }

  @override
  Future<void> animateCamera(AppMapCameraUpdate update) async {
    // BUG MapLibre 6.25.1 + iOS 19 / iPhone 17: cả `fly(to:withDuration:)` và
    // `setCamera(_, animated: true)` đều throw std::domain_error (C++ exception,
    // Dart try/catch không bắt được). Fallback: gọi `moveCamera` (instant snap,
    // không animation) — `setCamera(_, animated: false)` ở native, không crash.
    await _waitForMapSurfaceLayout();
    await _delegate.moveCamera(GoongValueCodec.toCameraUpdate(update));
  }

  @override
  Future<void> moveCamera(AppMapCameraUpdate update) async {
    await _waitForMapSurfaceLayout();
    await _delegate.moveCamera(GoongValueCodec.toCameraUpdate(update));
  }

  @override
  Future<AppMapCameraPosition?> getCameraPosition() async {
    final cp = _delegate.cameraPosition;
    return cp == null
        ? _initialCameraPosition
        : GoongValueCodec.fromCameraPosition(cp);
  }

  @override
  Future<AppLatLngBounds?> getVisibleRegion() async {
    final b = await _delegate.getVisibleRegion();
    return GoongValueCodec.fromBounds(b);
  }

  @override
  Future<double?> getZoomLevel() async =>
      _delegate.cameraPosition?.zoom ?? _initialCameraPosition.zoom;

  @override
  Future<Offset?> getScreenCoordinate(AppLatLng latLng) async {
    try {
      final p = await _delegate.toScreenLocation(GoongValueCodec.toLatLng(latLng));
      return Offset(p.x.toDouble(), p.y.toDouble());
    } catch (_) {
      return null;
    }
  }
}
