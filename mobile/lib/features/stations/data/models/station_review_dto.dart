import '../../../../core/network/json_utils.dart';

/// Backend: `StationReviewImageDto`
class StationReviewImageDto {
  const StationReviewImageDto({required this.id, required this.imageUrl});

  final int id;
  final String imageUrl;

  static StationReviewImageDto? tryParse(dynamic raw) {
    final m = JsonUtils.readMap(raw);
    if (m == null) return null;
    final id = JsonUtils.readInt(m['id']);
    final url = JsonUtils.readString(m['imageUrl']);
    if (id == null || url == null || url.isEmpty) return null;
    return StationReviewImageDto(id: id, imageUrl: url);
  }
}

/// Backend: `StationReviewDto`
class StationReviewDto {
  const StationReviewDto({
    required this.id,
    required this.stationId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.images,
  });

  final int id;
  final int stationId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final List<StationReviewImageDto> images;

  factory StationReviewDto.fromJson(Map<String, dynamic> json) {
    final imgs = <StationReviewImageDto>[];
    final raw = json['images'];
    if (raw is List<dynamic>) {
      for (final e in raw) {
        final dto = StationReviewImageDto.tryParse(e);
        if (dto != null) imgs.add(dto);
      }
    }
    final created = JsonUtils.readDateTime(json['createdAt']);
    if (created == null) {
      throw const FormatException('Missing createdAt on StationReviewDto');
    }
    return StationReviewDto(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      stationId: JsonUtils.readIntRequired(json['stationId'], field: 'stationId'),
      rating: JsonUtils.readIntRequired(json['rating'], field: 'rating'),
      comment: JsonUtils.readString(json['comment']),
      createdAt: created,
      images: imgs,
    );
  }
}

/// Backend: `StationReviewsPageDto`
class StationReviewsPageDto {
  const StationReviewsPageDto({
    required this.items,
    required this.totalCount,
    required this.skip,
    required this.take,
  });

  final List<StationReviewDto> items;
  final int totalCount;
  final int skip;
  final int take;

  factory StationReviewsPageDto.fromJson(Map<String, dynamic> json) {
    final items = <StationReviewDto>[];
    final raw = json['items'];
    if (raw is List<dynamic>) {
      for (final e in raw) {
        final m = JsonUtils.readMap(e);
        if (m != null) items.add(StationReviewDto.fromJson(m));
      }
    }
    return StationReviewsPageDto(
      items: items,
      totalCount: JsonUtils.readIntRequired(json['totalCount'], field: 'totalCount'),
      skip: JsonUtils.readIntRequired(json['skip'], field: 'skip'),
      take: JsonUtils.readIntRequired(json['take'], field: 'take'),
    );
  }
}
