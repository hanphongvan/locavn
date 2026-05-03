import '../../stations/data/models/station_detail_dto.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../stations/data/models/station_spotlight_dto.dart';
import '../../stations/data/stations_api.dart';

/// Maps a spotlight row to a [StationMapItem], preferring the loaded map row when present.
Future<(StationMapItem item, bool needsEphemeralMarker)?> resolveSpotlightToMapItem(
  StationsApi api,
  StationSpotlightDto spot,
  List<StationMapItem> loadedItems,
) async {
  for (final e in loadedItems) {
    if (e.stationId == spot.stationId) {
      return (e, false);
    }
  }

  try {
    final detail = await api.getStationDetail(spot.stationId);
    final item = stationMapItemFromDetailAndSpotlight(detail, spot);
    return (item, true);
  } catch (_) {
    return null;
  }
}

StationMapItem stationMapItemFromDetailAndSpotlight(StationDetailDto d, StationSpotlightDto spot) {
  final lat = d.latitude;
  final lng = d.longitude;
  if (lat == null || lng == null) {
    throw const FormatException('Station detail missing coordinates');
  }
  final name = d.stationName.trim().isNotEmpty ? d.stationName : spot.name.trim();
  final svcCodes = d.storeServices
          ?.where((s) => s.isActive)
          .map((s) => s.serviceCode.toUpperCase())
          .toList() ??
      const <String>[];
  svcCodes.sort();
  return StationMapItem(
    stationId: d.stationId,
    stationName: name.isNotEmpty ? name : 'Cây xăng #${d.stationId}',
    latitude: lat,
    longitude: lng,
    shortAddress: d.addressLine ?? spot.address,
    priceRon95: spot.priceRon95 ?? d.priceRon95,
    priceDiesel: spot.priceDiesel ?? d.priceDiesel,
    isActive: d.isActive,
    openNow: d.openNow,
    openStatus: d.openStatus,
    openingTime: d.openingTime,
    closingTime: d.closingTime,
    activeServiceCodes: svcCodes,
  );
}
