import 'package:flutter/material.dart';

/// Stable ids for aggregation / future API fields; labels are user-facing Vietnamese.
class ViolationTypeOption {
  const ViolationTypeOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;

  static ViolationTypeOption? byId(String id) {
    for (final o in kViolationTypeOptions) {
      if (o.id == id) return o;
    }
    return null;
  }
}

const List<ViolationTypeOption> kViolationTypeOptions = [
  ViolationTypeOption(
    id: 'closed_hoarding',
    label: 'Đóng cửa găm hàng',
    icon: Icons.storefront_outlined,
  ),
  ViolationTypeOption(
    id: 'meter_fraud',
    label: 'Gian lận đo lường (ăn bớt xăng)',
    icon: Icons.speed_outlined,
  ),
  ViolationTypeOption(
    id: 'quality_fraud',
    label: 'Gian lận chất lượng xăng dầu',
    icon: Icons.oil_barrel_outlined,
  ),
  ViolationTypeOption(
    id: 'no_invoice',
    label: 'Không xuất hóa đơn',
    icon: Icons.receipt_long_outlined,
  ),
  ViolationTypeOption(
    id: 'no_price_display',
    label: 'Không niêm yết giá',
    icon: Icons.sell_outlined,
  ),
  ViolationTypeOption(
    id: 'other',
    label: 'Khác',
    icon: Icons.more_horiz_rounded,
  ),
];

/// Selected [violationIds] in stable catalog order (for readable admin text).
List<ViolationTypeOption> violationOptionsInCatalogOrder(Set<String> violationIds) {
  return kViolationTypeOptions.where((o) => violationIds.contains(o.id)).toList(growable: false);
}

/// Maps UI state to a single `content` string for `POST /api/bad-reports`.
String buildBadReportApiContent({
  required Set<String> violationIds,
  String? extraDescription,
}) {
  if (violationIds.isEmpty) {
    throw ArgumentError('violationIds must not be empty');
  }
  final ordered = violationOptionsInCatalogOrder(violationIds);
  final knownIds = ordered.map((e) => e.id).toSet();
  final unknownIds = violationIds.where((id) => !knownIds.contains(id)).toList()..sort();

  final buf = StringBuffer();
  if (ordered.length == 1 && unknownIds.isEmpty) {
    final o = ordered.single;
    buf.writeln('Loại vi phạm: ${o.label}');
    buf.writeln('(mã: ${o.id})');
  } else {
    buf.writeln('Các nội dung vi phạm đã chọn:');
    for (final o in ordered) {
      buf.writeln('- ${o.label} (mã: ${o.id})');
    }
    for (final id in unknownIds) {
      buf.writeln('- $id (mã: $id)');
    }
    final allIds = [...ordered.map((e) => e.id), ...unknownIds];
    buf.writeln('(mã gộp: ${allIds.join(', ')})');
  }
  final d = extraDescription?.trim();
  if (d != null && d.isNotEmpty) {
    buf.writeln();
    buf.writeln('Mô tả thêm:');
    buf.write(d);
  }
  return buf.toString();
}
