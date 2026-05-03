import '../../../../core/network/json_utils.dart';

/// Backend: `PagedStationsResponse<T>`
class PagedStationsResponse<T> {
  const PagedStationsResponse({
    required this.items,
    required this.totalCount,
    required this.skip,
    required this.take,
  });

  final List<T> items;
  final int totalCount;
  final int skip;
  final int take;

  factory PagedStationsResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> map) itemFromJson,
  ) {
    final list = <T>[];
    final raw = JsonUtils.readList(json['items']) ?? JsonUtils.readList(json['Items']);
    if (raw != null) {
      for (final e in raw) {
        final m = JsonUtils.readMap(e);
        if (m != null) {
          list.add(itemFromJson(m));
        }
      }
    }
    return PagedStationsResponse(
      items: list,
      totalCount:
          JsonUtils.readInt(json['totalCount']) ?? JsonUtils.readInt(json['TotalCount']) ?? 0,
      skip: JsonUtils.readInt(json['skip']) ?? JsonUtils.readInt(json['Skip']) ?? 0,
      take: JsonUtils.readInt(json['take']) ?? JsonUtils.readInt(json['Take']) ?? 0,
    );
  }
}
