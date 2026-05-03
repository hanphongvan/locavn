import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/leader_map_models.dart';
import '../data/leader_map_ui_state.dart';
import 'leader_demo_distributors.dart';

/// Điểm đầu mối trên bản đồ điều hành (nguồn `GET /api/leader/map/distributors`).
///
/// `daysXang` / `daysDau` có thể null khi API không gửi số ngày dự trữ — marker hiển thị mức cảnh báo.
///
/// [serverDonViId] — `DM_DonVi.Id` khi từ API; **null** khi dữ liệu demo (không gọi
/// `GET .../distributors/{id}/inventory` vì [mapKey] lúc đó không phải id CSDL).
@immutable
class LeaderExecutiveDistributor {
  const LeaderExecutiveDistributor({
    required this.mapKey,
    this.serverDonViId,
    required this.name,
    required this.address,
    required this.position,
    this.logoUrl,
    required this.xangTon,
    required this.dauTon,
    this.daysXang,
    this.daysDau,
    required this.trangThaiXang,
    required this.trangThaiDau,
  });

  /// Khóa ổn định cho [MarkerId] trên Google Map.
  final int mapKey;

  /// Id đơn vị trên máy chủ; null ⇒ dữ liệu minh họa — không GET inventory.
  final int? serverDonViId;

  final String name;
  final String address;
  final LatLng position;
  final String? logoUrl;
  final double xangTon;
  final double dauTon;
  final double? daysXang;
  final double? daysDau;

  /// Máy chủ: `0` an toàn, `1` cảnh báo, `2` nguy cơ (marker PNG / pill / sheet).
  final int trangThaiXang;
  final int trangThaiDau;

  /// Trạng thái hiển thị marker theo nhiên liệu đang chọn.
  int displayStatusFor(LeaderMapFuelFilter fuel) {
    return fuel == LeaderMapFuelFilter.xang ? trangThaiXang : trangThaiDau;
  }

  /// Số ngày dự trữ theo nhiên liệu đang chọn trên bản đồ (Xăng / Dầu).
  double? coverageDaysFor(LeaderMapFuelFilter fuel) {
    return fuel == LeaderMapFuelFilter.xang ? daysXang : daysDau;
  }

  factory LeaderExecutiveDistributor.fromApi(LeaderMapDistributorItem r) {
    return LeaderExecutiveDistributor(
      mapKey: r.id,
      serverDonViId: r.id,
      name: r.tenDonVi,
      address: (r.diaChi == null || r.diaChi!.trim().isEmpty) ? '—' : r.diaChi!.trim(),
      position: LatLng(r.lat, r.lng),
      logoUrl: r.logoUrl,
      xangTon: r.tonXang,
      dauTon: r.tonDau,
      daysXang: r.daysXang?.toDouble(),
      daysDau: r.daysDau?.toDouble(),
      trangThaiXang: r.trangThaiXang,
      trangThaiDau: r.trangThaiDau,
    );
  }

  /// Dự phòng UI khi API chưa sẵn sàng — [serverDonViId] luôn null.
  factory LeaderExecutiveDistributor.fromDemo(LeaderDemoDistributor d) {
    return LeaderExecutiveDistributor(
      mapKey: Object.hash(0xD15EA5E, d.id, d.position.latitude, d.position.longitude),
      serverDonViId: null,
      name: d.name,
      address: d.address,
      position: d.position,
      logoUrl: null,
      xangTon: d.xangTon,
      dauTon: d.dauTon,
      daysXang: d.daysXang,
      daysDau: d.daysDau,
      trangThaiXang: d.trangThaiXang,
      trangThaiDau: d.trangThaiDau,
    );
  }
}
