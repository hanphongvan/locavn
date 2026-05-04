import 'package:flutter/foundation.dart';

import '../../../core/map/app_lat_lng.dart';
import '../data/leader_home_portal_models.dart';

/// Điểm đầu mối minh họa (chưa có API toạ độ + tồn thật) — thay khi backend cung cấp.
@immutable
class LeaderDemoDistributor {
  const LeaderDemoDistributor({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    required this.xangTon,
    required this.dauTon,
    required this.daysXang,
    required this.daysDau,
    required this.trangThaiXang,
    required this.trangThaiDau,
    required this.trendLabel,
    required this.xuHuongXang,
    required this.xuHuongDau,
    required this.nhapM3TuongDuong,
    required this.xuatM3TuongDuong,
    required this.canDoiM3TuongDuong,
  });

  final String id;
  final String name;
  final String address;
  final AppLatLng position;
  /// Tổng tồn xăng (minh họa), đơn vị hiển thị **m³**.
  final double xangTon;
  /// Tổng tồn dầu (minh họa), đơn vị hiển thị **tấn**.
  final double dauTon;
  final double daysXang;
  final double daysDau;
  /// Cố định minh họa — cùng ý mã máy chủ `0`/`1`/`2`.
  final int trangThaiXang;
  final int trangThaiDau;
  /// Gộp cho cảnh báo điều hành / marker; chi tiết sheet dùng [xuHuongXang], [xuHuongDau].
  final String trendLabel;
  final String xuHuongXang;
  final String xuHuongDau;
  /// Kỳ gần nhất — nhập / xuất / cân đối (m³ tương đương, minh họa).
  final double nhapM3TuongDuong;
  final double xuatM3TuongDuong;
  final double canDoiM3TuongDuong;

  /// Điểm từ SP `A_TienIch_BanDo_TonKho_DauMoi` (backend mới).
  factory LeaderDemoDistributor.fromPortalRow(LeaderHomeDistributorMapRow r, int index) {
    final d = r.days.toDouble().clamp(1.0, 99.0);
    return LeaderDemoDistributor(
      id: 'sp-$index-${r.name.hashCode}',
      name: r.name,
      address: 'Đầu mối (nguồn: báo cáo hệ thống)',
      position: AppLatLng(r.lat, r.lng),
      xangTon: r.xang.toDouble(),
      dauTon: r.dau.toDouble(),
      daysXang: d,
      daysDau: d,
      trangThaiXang: 1,
      trangThaiDau: 1,
      trendLabel: 'Dữ liệu máy chủ — ${r.days} ngày dự trữ (marker).',
      xuHuongXang: 'Tồn xăng ${r.xang} m³.',
      xuHuongDau: 'Tồn dầu ${r.dau} tấn.',
      nhapM3TuongDuong: (r.xang * 0.12).toDouble(),
      xuatM3TuongDuong: (r.xang * 0.10).toDouble(),
      canDoiM3TuongDuong: (r.xang * 0.02).toDouble(),
    );
  }
}

/// Danh sách cố định, phân bổ vài vùng — chỉ để demo UI lãnh đạo.
const List<LeaderDemoDistributor> kLeaderDemoDistributors = [
  LeaderDemoDistributor(
    id: 'dm-hn',
    name: 'Tổng kho xăng dầu miền Bắc (minh họa)',
    address: 'Khu công nghiệp Phố Nối A, Hưng Yên',
    position: AppLatLng(20.931234, 106.051234),
    xangTon: 12400,
    dauTon: 8200,
    daysXang: 14.2,
    daysDau: 6.5,
    trangThaiXang: 0,
    trangThaiDau: 1,
    trendLabel: 'Tồn xăng ổn định; dầu sát ngưỡng cảnh báo.',
    xuHuongXang: 'Tồn ổn định, đủ nguồn nhập theo kế hoạch.',
    xuHuongDau: 'Sát ngưỡng cảnh báo (5–10 ngày), theo dõi xuất bán.',
    nhapM3TuongDuong: 2850,
    xuatM3TuongDuong: 2420,
    canDoiM3TuongDuong: 430,
  ),
  LeaderDemoDistributor(
    id: 'dm-dn',
    name: 'Kho đầu mối Nam Trung Bộ (minh họa)',
    address: 'Cảng Liên Chiểu, Đà Nẵng',
    position: AppLatLng(16.061234, 108.181234),
    xangTon: 6800,
    dauTon: 11200,
    daysXang: 4.1,
    daysDau: 11.0,
    trangThaiXang: 2,
    trangThaiDau: 0,
    trendLabel: 'Xăng ngắn ngày; cần ưu tiên bổ sung nhập.',
    xuHuongXang: 'Dưới ngưỡng an toàn; cần ưu tiên bổ sung nhập.',
    xuHuongDau: 'Trong ngưỡng cảnh báo, cân đối xuất theo vùng.',
    nhapM3TuongDuong: 1920,
    xuatM3TuongDuong: 2180,
    canDoiM3TuongDuong: -260,
  ),
  LeaderDemoDistributor(
    id: 'dm-hcm',
    name: 'Trung tâm phân phối TP.HCM (minh họa)',
    address: 'Cát Lái, Thủ Đức, TP.HCM',
    position: AppLatLng(10.771234, 106.791234),
    xangTon: 18200,
    dauTon: 15300,
    daysXang: 18.0,
    daysDau: 9.2,
    trangThaiXang: 0,
    trangThaiDau: 1,
    trendLabel: 'Dự trữ sâu; duy trì nhịp xuất theo kế hoạch.',
    xuHuongXang: 'Dự trữ sâu, xu hướng tích cực.',
    xuHuongDau: 'Trung bình, duy trì nhịp xuất theo kế hoạch.',
    nhapM3TuongDuong: 4100,
    xuatM3TuongDuong: 3850,
    canDoiM3TuongDuong: 250,
  ),
  LeaderDemoDistributor(
    id: 'dm-ct',
    name: 'Đầu mối ĐBSCL (minh họa)',
    address: 'Cần Thơ',
    position: AppLatLng(10.031234, 105.781234),
    xangTon: 5100,
    dauTon: 4300,
    daysXang: 7.4,
    daysDau: 3.8,
    trangThaiXang: 1,
    trangThaiDau: 2,
    trendLabel: 'Dầu dưới ngưỡng an toàn; xăng trung bình.',
    xuHuongXang: 'Trung bình, theo dõi biến động nhập.',
    xuHuongDau: 'Dưới ngưỡng an toàn; ưu tiên cân đối nguồn.',
    nhapM3TuongDuong: 980,
    xuatM3TuongDuong: 1240,
    canDoiM3TuongDuong: -260,
  ),
];
