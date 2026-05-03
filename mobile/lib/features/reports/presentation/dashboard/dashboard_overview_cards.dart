import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/reports_overview_dto.dart';
import '../../data/models/reports_system_inventory_line_dto.dart';
import 'loca_dashboard_tokens.dart';

/// White card: tồn kho toàn hệ thống (cùng dữ liệu [ReportsOverviewDto.systemInventory]).
class DashboardSystemInventoryCard extends StatelessWidget {
  const DashboardSystemInventoryCard({super.key, required this.overview});

  final ReportsOverviewDto overview;

  static final NumberFormat _vnQty = NumberFormat('#,##0.###', 'vi');

  static String _formatQty(double q) {
    if (q.isNaN || q.isInfinite) return '—';
    return _vnQty.format(q);
  }

  static String _unitSuffix(ReportsSystemInventoryLineDto line) {
    final u = (line.unitTen ?? line.unitMa ?? '').trim();
    if (u.isEmpty) return '';
    return ' $u';
  }

  @override
  Widget build(BuildContext context) {
    final lines = overview.systemInventory;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: LocaDashboardTokens.cardWhite,
          borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
          boxShadow: LocaDashboardTokens.cardShadow(context),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 22, color: LocaDashboardTokens.primaryBlue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tồn kho (toàn hệ thống)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: LocaDashboardTokens.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lines.isEmpty)
              const Text(
                'Chưa có dòng tồn khác 0 từ sổ giao dịch kho.',
                style: TextStyle(
                  fontSize: 14,
                  color: LocaDashboardTokens.textSecondary,
                  height: 1.35,
                ),
              )
            else
              ...lines.map((line) {
                final label = line.productName.isNotEmpty
                    ? line.productName
                    : (line.productCode.isNotEmpty ? line.productCode : 'Mã ${line.productId}');
                final qty = '${_formatQty(line.currentQuantity)}${_unitSuffix(line)}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: LocaDashboardTokens.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        qty,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: LocaDashboardTokens.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// White card: số cây xăng theo tỉnh (cùng [stationsByProvince]).
class DashboardProvinceCard extends StatelessWidget {
  const DashboardProvinceCard({super.key, required this.overview});

  final ReportsOverviewDto overview;

  @override
  Widget build(BuildContext context) {
    final rows = overview.stationsByProvince;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: LocaDashboardTokens.cardWhite,
          borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
          boxShadow: LocaDashboardTokens.cardShadow(context),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map_outlined, size: 22, color: LocaDashboardTokens.primaryBlue),
                SizedBox(width: 10),
                Text(
                  'Số cây xăng theo tỉnh/TP',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: LocaDashboardTokens.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Text(
                'Không có phân bổ theo tỉnh trong phản hồi này.',
                style: TextStyle(
                  fontSize: 14,
                  color: LocaDashboardTokens.textSecondary,
                ),
              )
            else
              ...rows.map((r) {
                final label = r.provinceName ?? r.provinceCode ?? '(Chưa gắn tỉnh)';
                final code = r.provinceCode;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: LocaDashboardTokens.textPrimary,
                              ),
                            ),
                            if (code != null && code.isNotEmpty && r.provinceName != null)
                              Text(
                                'Mã: $code',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: LocaDashboardTokens.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        r.stationCount.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: LocaDashboardTokens.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Ghi chú từ máy chủ (cùng [notes]).
class DashboardInfoNoteCard extends StatelessWidget {
  const DashboardInfoNoteCard({super.key, required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        decoration: BoxDecoration(
          color: LocaDashboardTokens.cardWhite,
          borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusMd),
          border: Border.all(color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 22, color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.85)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ghi chú từ máy chủ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: LocaDashboardTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: LocaDashboardTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
