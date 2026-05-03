import '../../../../../core/network/json_utils.dart';

/// One row from `GET /api/my-bad-reports`.
class MyBadReportListItem {
  const MyBadReportListItem({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.content,
    required this.createdAt,
    required this.status,
    required this.imageCount,
  });

  final int id;
  final int? stationId;
  final String? stationName;
  final String content;
  final DateTime createdAt;
  final int status;
  final int imageCount;

  factory MyBadReportListItem.fromJson(Map<String, dynamic> json) {
    return MyBadReportListItem(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      stationId: JsonUtils.readInt(json['stationId']),
      stationName: JsonUtils.readString(json['stationName']),
      content: JsonUtils.readStringRequired(json['content'], field: 'content'),
      createdAt: JsonUtils.readDateTime(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: JsonUtils.readInt(json['status']) ?? 0,
      imageCount: JsonUtils.readInt(json['imageCount']) ?? 0,
    );
  }
}

class MyBadReportPage {
  const MyBadReportPage({
    required this.items,
    required this.totalCount,
    required this.skip,
    required this.take,
  });

  final List<MyBadReportListItem> items;
  final int totalCount;
  final int skip;
  final int take;

  factory MyBadReportPage.fromJson(Map<String, dynamic> json) {
    final raw = JsonUtils.readList(json['items']);
    final items = <MyBadReportListItem>[];
    if (raw != null) {
      for (final e in raw) {
        final m = JsonUtils.readMap(e);
        if (m != null) items.add(MyBadReportListItem.fromJson(m));
      }
    }
    return MyBadReportPage(
      items: items,
      totalCount: JsonUtils.readInt(json['totalCount']) ?? 0,
      skip: JsonUtils.readInt(json['skip']) ?? 0,
      take: JsonUtils.readInt(json['take']) ?? 0,
    );
  }
}
