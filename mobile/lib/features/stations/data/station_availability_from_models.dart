import '../domain/station_availability.dart';
import 'models/station_detail_dto.dart';
import 'models/station_list_item.dart';
import 'models/station_map_item.dart';

/// Builds [StationAvailabilityInput] from API models (optional `openingTime` / `closingTime`, `openNow`, `openStatus`).
StationAvailabilityInput stationAvailabilityInputFromMap(StationMapItem map) {
  return StationAvailabilityInput(
    opening: LocalClockTime.tryParse(map.openingTime),
    closing: LocalClockTime.tryParse(map.closingTime),
    serverOpenNow: map.openNow,
    serverOpenStatus: map.openStatus,
  );
}

StationAvailabilityInput stationAvailabilityInputFromDetail(StationDetailDto detail) {
  return StationAvailabilityInput(
    opening: LocalClockTime.tryParse(detail.openingTime),
    closing: LocalClockTime.tryParse(detail.closingTime),
    serverOpenNow: detail.openNow,
    serverOpenStatus: detail.openStatus,
  );
}

StationAvailabilityInput stationAvailabilityInputFromList(StationListItem item) {
  return StationAvailabilityInput(
    opening: LocalClockTime.tryParse(item.openingTime),
    closing: LocalClockTime.tryParse(item.closingTime),
    serverOpenNow: item.openNow,
    serverOpenStatus: item.openStatus,
  );
}

/// Detail overrides map when present; map fills gaps while detail loads.
StationAvailabilityInput stationAvailabilityInputMerged(
  StationMapItem map,
  StationDetailDto? detail,
) {
  if (detail == null) {
    return stationAvailabilityInputFromMap(map);
  }
  return StationAvailabilityInput(
    opening: LocalClockTime.tryParse(detail.openingTime ?? map.openingTime),
    closing: LocalClockTime.tryParse(detail.closingTime ?? map.closingTime),
    serverOpenNow: detail.openNow ?? map.openNow,
    serverOpenStatus: detail.openStatus ?? map.openStatus,
  );
}
