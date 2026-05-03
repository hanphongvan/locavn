import '../../../core/network/json_utils.dart';

/// `GET /api/leader/map/distributors`
class LeaderMapDistributorsResponse {
  const LeaderMapDistributorsResponse({required this.items});

  final List<LeaderMapDistributorItem> items;

  factory LeaderMapDistributorsResponse.fromJson(Map<String, dynamic> json) {
    final raw = JsonUtils.readList(json['items']) ?? JsonUtils.readList(json['Items']);
    final list = <LeaderMapDistributorItem>[];
    if (raw != null) {
      for (final e in raw) {
        final m = JsonUtils.readMap(e);
        if (m != null) {
          list.add(LeaderMapDistributorItem.fromJson(m));
        }
      }
    }
    return LeaderMapDistributorsResponse(items: list);
  }
}

class LeaderMapDistributorItem {
  const LeaderMapDistributorItem({
    required this.id,
    required this.tenDonVi,
    this.diaChi,
    required this.lat,
    required this.lng,
    this.logoUrl,
    required this.tonXang,
    required this.tonDau,
    this.daysXang,
    this.daysDau,
    required this.trangThaiXang,
    required this.trangThaiDau,
  });

  final int id;
  final String tenDonVi;
  final String? diaChi;
  final double lat;
  final double lng;
  final String? logoUrl;
  final double tonXang;
  final double tonDau;
  final int? daysXang;
  final int? daysDau;

  /// Máy chủ: `0` an toàn, `1` cảnh báo, `2` nguy cơ (marker PNG + pill).
  final int trangThaiXang;
  final int trangThaiDau;

  factory LeaderMapDistributorItem.fromJson(Map<String, dynamic> json) {
    return LeaderMapDistributorItem(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      tenDonVi: JsonUtils.readString(json['tenDonVi']) ?? '',
      diaChi: JsonUtils.readString(json['diaChi']),
      lat: JsonUtils.readDoubleRequired(json['lat'], field: 'lat'),
      lng: JsonUtils.readDoubleRequired(json['lng'], field: 'lng'),
      logoUrl: JsonUtils.readString(json['logoUrl']),
      tonXang: JsonUtils.readDouble(json['tonXang']) ?? 0,
      tonDau: JsonUtils.readDouble(json['tonDau']) ?? 0,
      daysXang: JsonUtils.readInt(json['daysXang']),
      daysDau: JsonUtils.readInt(json['daysDau']),
      trangThaiXang: JsonUtils.readInt(json['trangThaiXang']) ?? 1,
      trangThaiDau: JsonUtils.readInt(json['trangThaiDau']) ?? 1,
    );
  }
}

/// `GET /api/leader/map/distributors/{id}/inventory`
class LeaderMapDistributorInventoryDto {
  const LeaderMapDistributorInventoryDto({
    required this.id,
    required this.tenDonVi,
    this.diaChi,
    required this.tonXang,
    required this.tonDau,
    this.daysXang,
    this.daysDau,
    required this.trangThaiXang,
    required this.trangThaiDau,
  });

  final int id;
  final String tenDonVi;
  final String? diaChi;
  final double tonXang;
  final double tonDau;
  final int? daysXang;
  final int? daysDau;
  final int trangThaiXang;
  final int trangThaiDau;

  factory LeaderMapDistributorInventoryDto.fromJson(Map<String, dynamic> json) {
    return LeaderMapDistributorInventoryDto(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      tenDonVi: JsonUtils.readString(json['tenDonVi']) ?? '',
      diaChi: JsonUtils.readString(json['diaChi']),
      tonXang: JsonUtils.readDouble(json['tonXang']) ?? 0,
      tonDau: JsonUtils.readDouble(json['tonDau']) ?? 0,
      daysXang: JsonUtils.readInt(json['daysXang']),
      daysDau: JsonUtils.readInt(json['daysDau']),
      trangThaiXang: JsonUtils.readInt(json['trangThaiXang']) ?? 1,
      trangThaiDau: JsonUtils.readInt(json['trangThaiDau']) ?? 1,
    );
  }
}

/// `GET /api/leader/map/violations`
class LeaderMapViolationsResponse {
  const LeaderMapViolationsResponse({required this.stationId, required this.items});

  final int stationId;
  final List<LeaderMapBadReportItem> items;

  factory LeaderMapViolationsResponse.fromJson(Map<String, dynamic> json) {
    final raw = JsonUtils.readList(json['items']) ?? JsonUtils.readList(json['Items']);
    final list = <LeaderMapBadReportItem>[];
    if (raw != null) {
      for (final e in raw) {
        final m = JsonUtils.readMap(e);
        if (m != null) {
          list.add(LeaderMapBadReportItem.fromJson(m));
        }
      }
    }
    return LeaderMapViolationsResponse(
      stationId: JsonUtils.readInt(json['stationId']) ?? JsonUtils.readInt(json['StationId']) ?? 0,
      items: list,
    );
  }
}

class LeaderMapBadReportItem {
  const LeaderMapBadReportItem({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.status,
  });

  final int id;
  final String content;
  final DateTime createdAt;
  final String status;

  factory LeaderMapBadReportItem.fromJson(Map<String, dynamic> json) {
    final raw = json['createdAt'] ?? json['CreatedAt'];
    DateTime dt;
    if (raw is String) {
      dt = DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      dt = DateTime.fromMillisecondsSinceEpoch(0);
    }
    return LeaderMapBadReportItem(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      content: JsonUtils.readString(json['content']) ?? '',
      createdAt: dt,
      status: JsonUtils.readString(json['status']) ?? '',
    );
  }
}
