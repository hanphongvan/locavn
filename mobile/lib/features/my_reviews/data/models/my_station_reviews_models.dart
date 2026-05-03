import '../../../../core/network/json_utils.dart';

class MyStationReviewListItem {
  const MyStationReviewListItem({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.imageCount,
  });

  final int id;
  final int stationId;
  final String stationName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final int imageCount;

  factory MyStationReviewListItem.fromJson(Map<String, dynamic> json) {
    return MyStationReviewListItem(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      stationId: JsonUtils.readIntRequired(json['stationId'], field: 'stationId'),
      stationName: JsonUtils.readStringRequired(json['stationName'], field: 'stationName'),
      rating: JsonUtils.readInt(json['rating']) ?? 0,
      comment: JsonUtils.readString(json['comment']),
      createdAt: JsonUtils.readDateTime(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      imageCount: JsonUtils.readInt(json['imageCount']) ?? 0,
    );
  }
}

class MyStationReviewsPage {
  const MyStationReviewsPage({
    required this.items,
    required this.totalCount,
    required this.skip,
    required this.take,
  });

  final List<MyStationReviewListItem> items;
  final int totalCount;
  final int skip;
  final int take;

  factory MyStationReviewsPage.fromJson(Map<String, dynamic> json) {
    final raw = JsonUtils.readList(json['items']);
    final items = <MyStationReviewListItem>[];
    if (raw != null) {
      for (final e in raw) {
        final m = JsonUtils.readMap(e);
        if (m != null) items.add(MyStationReviewListItem.fromJson(m));
      }
    }
    return MyStationReviewsPage(
      items: items,
      totalCount: JsonUtils.readInt(json['totalCount']) ?? 0,
      skip: JsonUtils.readInt(json['skip']) ?? 0,
      take: JsonUtils.readInt(json['take']) ?? 0,
    );
  }
}
