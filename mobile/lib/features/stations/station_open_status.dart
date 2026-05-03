import 'data/models/station_detail_dto.dart';
import 'data/models/station_list_item.dart';
import 'data/models/station_map_item.dart';
import 'data/station_availability_from_models.dart';
import 'domain/station_availability.dart';

/// Single entry point for open/closed resolution from API models (map, detail, merged).
///
/// Logic stays in [StationAvailability.resolve]; this class wires DTOs and keeps UI isolated.
abstract final class StationOpenStatus {
  static StationAvailability forMapItem(StationMapItem item, {DateTime? clock}) {
    return StationAvailability.resolve(
      stationAvailabilityInputFromMap(item),
      clock: clock,
    );
  }

  static StationAvailability forDetail(StationDetailDto detail, {DateTime? clock}) {
    return StationAvailability.resolve(
      stationAvailabilityInputFromDetail(detail),
      clock: clock,
    );
  }

  static StationAvailability forListItem(StationListItem item, {DateTime? clock}) {
    return StationAvailability.resolve(
      stationAvailabilityInputFromList(item),
      clock: clock,
    );
  }

  /// Detail overrides map when fields are present; use while the sheet loads detail.
  static StationAvailability merged(StationMapItem map, StationDetailDto? detail, {DateTime? clock}) {
    return StationAvailability.resolve(
      stationAvailabilityInputMerged(map, detail),
      clock: clock,
    );
  }
}
