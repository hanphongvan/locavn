import '../../../../core/network/json_utils.dart';

/// Backend: `StationSpotlightDto` (nearest / cheapest / top-rated spotlights).
class StationSpotlightDto {
  const StationSpotlightDto({
    required this.stationId,
    required this.name,
    this.address,
    this.priceRon95,
    this.priceDiesel,
    this.averageRating,
    this.reviewCount,
    this.distanceKm,
  });

  final int stationId;
  final String name;
  final String? address;
  final double? priceRon95;
  final double? priceDiesel;
  final double? averageRating;
  final int? reviewCount;

  /// Great-circle distance in km (nearest API only).
  final double? distanceKm;

  factory StationSpotlightDto.fromJson(Map<String, dynamic> json) {
    return StationSpotlightDto(
      stationId: JsonUtils.readIntRequired(json['stationId'], field: 'stationId'),
      name: JsonUtils.readString(json['name']) ?? '',
      address: JsonUtils.readString(json['address']),
      priceRon95: JsonUtils.readDouble(json['priceRon95']),
      priceDiesel: JsonUtils.readDouble(json['priceDiesel']),
      averageRating: JsonUtils.readDouble(json['averageRating']),
      reviewCount: JsonUtils.readInt(json['reviewCount']),
      distanceKm: JsonUtils.readDouble(json['distanceKm']),
    );
  }
}
