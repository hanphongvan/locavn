import '../../../../core/network/json_utils.dart';

/// Backend: `StationRatingSummaryDto` from `GET /api/stations/{id}/rating-summary`.
class StationRatingSummaryDto {
  const StationRatingSummaryDto({
    required this.reviewCount,
    this.averageRating,
    required this.ratingDistribution,
  });

  final int reviewCount;
  final double? averageRating;
  final List<RatingStarBucketDto> ratingDistribution;

  factory StationRatingSummaryDto.fromJson(Map<String, dynamic> json) {
    final distRaw = json['ratingDistribution'];
    final buckets = <RatingStarBucketDto>[];
    if (distRaw is List<dynamic>) {
      for (final e in distRaw) {
        final m = JsonUtils.readMap(e);
        if (m == null) continue;
        final stars = JsonUtils.readInt(m['stars']);
        final count = JsonUtils.readInt(m['count']);
        if (stars != null && count != null) {
          buckets.add(RatingStarBucketDto(stars: stars, count: count));
        }
      }
    }
    return StationRatingSummaryDto(
      reviewCount: JsonUtils.readIntRequired(json['reviewCount'], field: 'reviewCount'),
      averageRating: JsonUtils.readDouble(json['averageRating']),
      ratingDistribution: buckets,
    );
  }
}

class RatingStarBucketDto {
  const RatingStarBucketDto({required this.stars, required this.count});

  final int stars;
  final int count;
}
