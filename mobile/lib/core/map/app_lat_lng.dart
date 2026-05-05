import 'package:flutter/foundation.dart';

@immutable
class AppLatLng {
  final double latitude;
  final double longitude;

  const AppLatLng(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      other is AppLatLng &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'AppLatLng($latitude, $longitude)';
}
