import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../station_detail/presentation/station_detail_strings.dart';
import '../../station_detail/presentation/widgets/station_rating_summary.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../stations/domain/station_availability.dart';
import '../../stations/station_open_status.dart';
import '../data/leader_map_api.dart';
import '../data/leader_map_models.dart';
import '../data/leader_map_ui_state.dart';
import '../map/leader_distributor_marker_assets.dart';
import '../map/leader_executive_distributor.dart';
import '../map/leader_map_grid_cluster.dart';
import 'leader_theme.dart';

Future<void> showLeaderDistributorSheet(
  BuildContext context,
  WidgetRef ref,
  LeaderExecutiveDistributor d, {
  required LeaderMapFuelFilter fuel,
}) {
  final t = Theme.of(context).textTheme;
  final qty = NumberFormat.decimalPattern('vi');
  final apiId = d.serverDonViId;
  final Future<LeaderMapDistributorInventoryDto?> invFuture = apiId != null
      ? ref.read(leaderMapApiProvider).getDistributorInventory(apiId)
      : Future<LeaderMapDistributorInventoryDto?>.value(null);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final h = MediaQuery.sizeOf(ctx).height * 0.7;
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: LeaderTheme.card,
          child: SizedBox(
            height: h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: LeaderTheme.muted.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<LeaderMapDistributorInventoryDto?>(
                    future: invFuture,
                    builder: (context, snap) {
                      if (apiId != null && snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
                      }
                      final inv = snap.hasData ? snap.data : null;
                      final name = inv?.tenDonVi ?? d.name;
                      final addr = inv != null && inv.diaChi != null && inv.diaChi!.trim().isNotEmpty
                          ? inv.diaChi!.trim()
                          : d.address;
                      final xTon = inv?.tonXang ?? d.xangTon;
                      final dTon = inv?.tonDau ?? d.dauTon;
                      final double? daysXang;
                      final double? daysDau;
                      if (inv == null) {
                        daysXang = d.daysXang;
                        daysDau = d.daysDau;
                      } else {
                        daysXang = inv.daysXang?.toDouble() ?? d.daysXang;
                        daysDau = inv.daysDau?.toDouble() ?? d.daysDau;
                      }
                      final sx = inv?.trangThaiXang ?? d.trangThaiXang;
                      final sd = inv?.trangThaiDau ?? d.trangThaiDau;
                      final stub = LeaderExecutiveDistributor(
                        mapKey: d.mapKey,
                        serverDonViId: d.serverDonViId,
                        name: name,
                        address: addr,
                        position: d.position,
                        logoUrl: d.logoUrl,
                        xangTon: xTon,
                        dauTon: dTon,
                        daysXang: daysXang,
                        daysDau: daysDau,
                        trangThaiXang: sx,
                        trangThaiDau: sd,
                      );
                      final coverageSel = stub.coverageDaysFor(fuel);
                      final statusSel = stub.displayStatusFor(fuel);
                      final statusLabel = getDistributorStatusLabelForDisplayStatus(statusSel);
                      final statusColor = getDistributorStatusColorForDisplayStatus(statusSel);
                      final tonLine = 'Xăng: ${qty.format(xTon)} m³ · Dầu: ${qty.format(dTon)} tấn';
                      final daysLine =
                          coverageSel == null ? '—' : '${coverageSel.toStringAsFixed(1)} ngày';

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottomInset),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Chi tiết đầu mối',
                                    style: t.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: LeaderTheme.navy,
                                    ),
                                  ),
                                ),
                                _StatusBadge(label: statusLabel, color: statusColor),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (apiId != null && snap.hasError)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Không tải được tồn kho chi tiết — hiển thị số liệu trên bản đồ.',
                                  style: t.bodySmall?.copyWith(color: LeaderTheme.alert, height: 1.35),
                                ),
                              ),
                            _kvRow(t, 'Tên công ty', name),
                            const SizedBox(height: 12),
                            _kvRow(t, 'Địa chỉ', addr),
                            const SizedBox(height: 12),
                            _kvRow(t, 'Lượng tồn kho', tonLine),
                            const SizedBox(height: 12),
                            _kvRow(t, 'Số ngày dự trữ', daysLine),
                            const SizedBox(height: 12),
                            _kvRow(t, 'Trạng thái', statusLabel, valueColor: statusColor, emphasizeValue: true),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

Widget _kvRow(
  TextTheme t,
  String label,
  String value, {
  Color? valueColor,
  bool emphasizeValue = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: t.labelMedium?.copyWith(
          color: LeaderTheme.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: (emphasizeValue ? t.titleSmall : t.bodyLarge)?.copyWith(
          color: valueColor ?? LeaderTheme.navy,
          fontWeight: emphasizeValue ? FontWeight.w800 : FontWeight.w500,
          height: 1.35,
        ),
      ),
    ],
  );
}

Future<void> showLeaderStationSheet(
  BuildContext context,
  WidgetRef ref,
  StationMapItem s,
) {
  final t = Theme.of(context).textTheme;
  final df = DateFormat('HH:mm dd/MM/yyyy', 'vi');
  final qty = NumberFormat.decimalPattern('vi');
  final av = StationOpenStatus.forMapItem(s);
  final px95 = s.priceRon95;
  final pxDie = s.priceDiesel;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LeaderTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (ctx2, ref2, _) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.paddingOf(ctx2).bottom),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tên cửa hàng', style: t.labelMedium?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(s.stationName, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: LeaderTheme.navy)),
                    const SizedBox(height: 12),
                    Text('Địa chỉ', style: t.labelMedium?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    _rowIcon(Icons.place_outlined, s.shortAddress ?? '—'),
                    const SizedBox(height: 14),
                    if (s.hasValidCoord)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _openLeaderStationDirections(ctx2, s.latitude, s.longitude),
                          icon: const Icon(Icons.directions_rounded),
                          label: const Text(StationDetailStrings.directionsTooltip),
                          style: FilledButton.styleFrom(
                            backgroundColor: LeaderTheme.navy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (s.hasValidCoord) const SizedBox(height: 16),
                    Text('Giá bán', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      px95 != null ? 'Xăng (RON95): ${qty.format(px95)} đ/l' : 'Xăng: chưa có giá trên bảng điều chỉnh',
                      style: t.bodyMedium?.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pxDie != null ? 'Dầu (DO): ${qty.format(pxDie)} đ/l' : 'Dầu: chưa có giá trên bảng điều chỉnh',
                      style: t.bodyMedium?.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: 18),
                    Text(StationDetailStrings.sectionRating, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    StationRatingSummary(stationId: s.stationId),
                    const SizedBox(height: 16),
                    Text('Tình trạng', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      _leaderRetailSupplyHint(s, av),
                      style: t.bodyMedium?.copyWith(color: LeaderTheme.muted, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    Text('Vi phạm / phản ánh', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    FutureBuilder(
                      future: ref2.read(leaderMapApiProvider).getViolations(s.stationId),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        if (snap.hasError) {
                          return Text(
                            'Không tải được danh sách phản ánh.',
                            style: t.bodySmall?.copyWith(color: LeaderTheme.alert),
                          );
                        }
                        final v = snap.data;
                        if (v == null || v.items.isEmpty) {
                          return Text('Chưa có phản ánh từ người dùng.', style: t.bodySmall?.copyWith(color: LeaderTheme.muted));
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final r in v.items.take(12))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(df.format(r.createdAt.toLocal()), style: t.labelSmall?.copyWith(color: LeaderTheme.muted)),
                                    const SizedBox(height: 2),
                                    Text(r.content, style: t.bodyMedium?.copyWith(height: 1.35)),
                                    Text('Trạng thái: ${r.status}', style: t.labelSmall?.copyWith(color: LeaderTheme.muted)),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _openLeaderStationDirections(BuildContext context, double lat, double lng) async {
  final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(StationDetailStrings.directionsOpenFail)),
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(StationDetailStrings.directionsLaunchFail)),
    );
  }
}

String _leaderRetailSupplyHint(StationMapItem s, StationAvailability av) {
  if (av.tone != StationOpenTone.open) {
    return '${av.primaryLabel} — kiểm tra lịch hoạt động.';
  }
  if (s.priceRon95 != null || s.priceDiesel != null) {
    return 'Còn hàng (ước lượng): điểm đang mở và có giá niêm yết; tồn thực tế theo kho cửa hàng.';
  }
  return 'Sắp hết / chưa rõ: điểm đang mở nhưng chưa có đủ giá trên bảng điều chỉnh.';
}

Widget _rowIcon(IconData icon, String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: LeaderTheme.navy),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
    ],
  );
}

Future<void> showLeaderClusterSheet(BuildContext context, WidgetRef ref, List<LeaderFilteredStation> members) async {
  final t = Theme.of(context).textTheme;
  final h = MediaQuery.sizeOf(context).height * 0.5;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LeaderTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: SizedBox(
          height: h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  '${members.length} cửa hàng trong cụm',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: LeaderTheme.navy),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (_, i) {
                    final e = members[i];
                    return ListTile(
                      title: Text(e.item.stationName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        e.item.shortAddress ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        showLeaderStationSheet(context, ref, e.item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
