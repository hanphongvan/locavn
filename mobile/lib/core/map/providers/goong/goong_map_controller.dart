import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../app_lat_lng_bounds.dart';
import '../../app_map_camera.dart';
import '../../app_map_controller.dart';
import 'goong_value_codec.dart';

class GoongAppMapController implements AppMapController {
  final ml.MapLibreMapController _delegate;

  GoongAppMapController(this._delegate);

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
    return cp == null ? null : GoongValueCodec.fromCameraPosition(cp);
  }

  @override
  Future<AppLatLngBounds?> getVisibleRegion() async {
    final b = await _delegate.getVisibleRegion();
    return GoongValueCodec.fromBounds(b);
  }

  @override
  Future<double?> getZoomLevel() async => _delegate.cameraPosition?.zoom;
}
