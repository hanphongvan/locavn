import 'package:flutter/widgets.dart' show Offset;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;

import '../../app_lat_lng.dart';
import '../../app_lat_lng_bounds.dart';
import '../../app_map_camera.dart';
import '../../app_map_controller.dart';
import 'google_value_codec.dart';

class GoogleAppMapController implements AppMapController {
  final gmf.GoogleMapController _delegate;

  GoogleAppMapController(this._delegate);

  gmf.GoogleMapController get rawController => _delegate;

  @override
  Future<void> animateCamera(AppMapCameraUpdate update) =>
      _delegate.animateCamera(GoogleValueCodec.toCameraUpdate(update));

  @override
  Future<void> moveCamera(AppMapCameraUpdate update) =>
      _delegate.moveCamera(GoogleValueCodec.toCameraUpdate(update));

  /// Google Maps SDK không expose vị trí camera hiện tại đồng bộ —
  /// chỉ phát qua `onCameraMove`. Caller theo dõi callback đó nếu cần.
  @override
  Future<AppMapCameraPosition?> getCameraPosition() async => null;

  @override
  Future<AppLatLngBounds?> getVisibleRegion() async {
    final b = await _delegate.getVisibleRegion();
    return GoogleValueCodec.fromBounds(b);
  }

  @override
  Future<double?> getZoomLevel() => _delegate.getZoomLevel();

  @override
  Future<Offset?> getScreenCoordinate(AppLatLng latLng) async {
    try {
      final s = await _delegate.getScreenCoordinate(GoogleValueCodec.toLatLng(latLng));
      return Offset(s.x.toDouble(), s.y.toDouble());
    } catch (_) {
      return null;
    }
  }
}
