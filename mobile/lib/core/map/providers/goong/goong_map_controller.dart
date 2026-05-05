import 'package:flutter/widgets.dart' show Offset;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../app_lat_lng.dart';
import '../../app_lat_lng_bounds.dart';
import '../../app_map_camera.dart';
import '../../app_map_controller.dart';
import 'goong_value_codec.dart';

class GoongAppMapController implements AppMapController {
  final ml.MapLibreMapController _delegate;

  /// Fallback khi `_delegate.cameraPosition` còn null — trường này chỉ populate
  /// sau camera event đầu tiên trên MapLibre, không sẵn ngay sau onMapCreated /
  /// onStyleLoadedCallback (khác Google: cameraPosition luôn có giá trị).
  /// Caller (MapStationMapBody, …) sẽ thấy `getZoomLevel()` không-null và build
  /// được marker ngay từ frame đầu thay vì phải đợi pan/zoom.
  final AppMapCameraPosition _initialCameraPosition;

  GoongAppMapController(this._delegate, this._initialCameraPosition);

  ml.MapLibreMapController get rawController => _delegate;

  @override
  Future<void> animateCamera(AppMapCameraUpdate update) async {
    await _delegate.animateCamera(GoongValueCodec.toCameraUpdate(update));
  }

  @override
  Future<void> moveCamera(AppMapCameraUpdate update) async {
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
