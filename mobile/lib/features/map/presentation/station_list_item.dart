import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatting/vnd_currency_format.dart';
import '../../station_detail/presentation/station_detail_providers.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../stations/domain/station_availability.dart';
import '../../stations/station_open_status.dart';
import 'map_screen_palette.dart';

/// Một dòng trạm trong bottom sheet (dữ liệu map + rating API khi tải xong).
class StationListItem extends ConsumerWidget {
  const StationListItem({
    super.key,
    required this.station,
    required this.onOpenDetail,
    this.distanceKm,
  });

  final StationMapItem station;
  final VoidCallback onOpenDetail;
  final double? distanceKm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(stationRatingSummaryProvider(station.stationId));
    final open = StationOpenStatus.forMapItem(station);
    final (Color dot, String statusLabel) = _statusStyle(open.tone);

    final name =
        station.stationName.trim().isNotEmpty ? station.stationName : 'Cây xăng #${station.stationId}';
    final addr = station.shortAddress?.trim();
    final addrLine = (addr != null && addr.isNotEmpty)
        ? addr
        : '${station.latitude.toStringAsFixed(4)}, ${station.longitude.toStringAsFixed(4)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenDetail,
        borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: MapScreenPalette.screenBackground,
                child: Icon(
                  Icons.local_gas_station_rounded,
                  color: MapScreenPalette.primaryBlue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: MapScreenPalette.textPrimary,
                          ),
                    ),
                    if (distanceKm != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_formatKm(distanceKm!)} km',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: MapScreenPalette.cyan,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      addrLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MapScreenPalette.textSecondary,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusLabel,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: MapScreenPalette.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tồn kho theo báo cáo: xem chi tiết trạm.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: MapScreenPalette.textSecondary.withValues(alpha: 0.85),
                          ),
                    ),
                    const SizedBox(height: 6),
                    ratingAsync.when(
                      data: (r) => Text(
                        r.reviewCount > 0
                            ? '★ ${r.averageRating?.toStringAsFixed(1) ?? '—'} · ${r.reviewCount} đánh giá'
                            : 'Chưa có đánh giá',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: MapScreenPalette.textSecondary,
                            ),
                      ),
                      loading: () => Text(
                        'Đang tải đánh giá…',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: MapScreenPalette.textSecondary,
                            ),
                      ),
                      error: (e, _) => Text(
                        'Không tải được đánh giá',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: MapScreenPalette.warning,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatVndCurrency(station.priceRon95),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: MapScreenPalette.primaryBlue,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _openDirections(context, station),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MapScreenPalette.primaryBlue,
                      side: const BorderSide(color: MapScreenPalette.primaryBlue, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm),
                      ),
                    ),
                    child: const Text('Chỉ đường'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (Color, String) _statusStyle(StationOpenTone tone) {
    return switch (tone) {
      StationOpenTone.open => (MapScreenPalette.green, 'Đang mở cửa'),
      StationOpenTone.closed => (MapScreenPalette.danger, 'Hiện đóng cửa'),
      StationOpenTone.unknown => (MapScreenPalette.warning, 'Chưa xác định'),
    };
  }
}

String _formatKm(double km) {
  if (km >= 100) return km.toStringAsFixed(0);
  if (km >= 10) return km.toStringAsFixed(1);
  return km.toStringAsFixed(2);
}

Future<void> _openDirections(BuildContext context, StationMapItem station) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}',
  );
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng bản đồ.')),
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không mở được chỉ đường.')),
    );
  }
}
