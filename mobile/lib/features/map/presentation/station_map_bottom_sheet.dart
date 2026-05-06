import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_geo.dart';
import 'map_discovery_navigation.dart';
import 'map_providers.dart';
import 'map_screen_palette.dart';
import 'station_list_item.dart';

/// Bottom sheet kéo được: danh sách trạm đã tải + sắp xếp client-side.
class StationMapBottomSheet extends ConsumerStatefulWidget {
  const StationMapBottomSheet({super.key});

  @override
  ConsumerState<StationMapBottomSheet> createState() => _StationMapBottomSheetState();
}

class _StationMapBottomSheetState extends ConsumerState<StationMapBottomSheet> {
  double _lastSheetExtent = 0.26;
  Timer? _originRefreshDebounce;

  @override
  void dispose() {
    _originRefreshDebounce?.cancel();
    super.dispose();
  }

  void _scheduleUserOriginRefresh() {
    _originRefreshDebounce?.cancel();
    _originRefreshDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      ref.invalidate(mapSheetUserOriginProvider);
    });
  }

  bool _onDraggableScroll(DraggableScrollableNotification n) {
    final e = n.extent;
    if (e >= 0.44 && _lastSheetExtent < 0.34) {
      _scheduleUserOriginRefresh();
    }
    _lastSheetExtent = e;
    return false;
  }

  static Future<void> _showSortPicker(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: MapScreenPalette.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MapScreenPalette.radiusLg)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (_, ref2, _) {
            final current = ref2.watch(mapStationListSortProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sắp xếp danh sách',
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: MapScreenPalette.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text('Gần nhất (theo GPS)'),
                      trailing: current == MapStationListSort.distanceAsc
                          ? const Icon(Icons.check_rounded, color: MapScreenPalette.primaryBlue)
                          : null,
                      onTap: () {
                        ref2.read(mapStationListSortProvider.notifier).state = MapStationListSort.distanceAsc;
                        ref2.invalidate(mapSheetUserOriginProvider);
                        Navigator.pop(ctx);
                      },
                    ),
                    ListTile(
                      title: const Text('Giá RON 95 rẻ nhất'),
                      trailing: current == MapStationListSort.priceRon95Asc
                          ? const Icon(Icons.check_rounded, color: MapScreenPalette.primaryBlue)
                          : null,
                      onTap: () {
                        ref2.read(mapStationListSortProvider.notifier).state = MapStationListSort.priceRon95Asc;
                        Navigator.pop(ctx);
                      },
                    ),
                    ListTile(
                      title: const Text('Uy tín (tạm thời: A → Z)'),
                      subtitle: const Text(
                        'TODO: Sắp theo điểm đánh giá khi API hỗ trợ lô hoặc trường trên bản đồ.',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: current == MapStationListSort.ratingDescPlaceholder
                          ? const Icon(Icons.check_rounded, color: MapScreenPalette.primaryBlue)
                          : null,
                      onTap: () {
                        ref2.read(mapStationListSortProvider.notifier).state =
                            MapStationListSort.ratingDescPlaceholder;
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(mapSortedStationSheetItemsProvider);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: _onDraggableScroll,
      child: DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.26,
      minChildSize: 0.18,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.26, 0.52, 0.9],
      builder: (context, scrollController) {
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        // CustomScrollView: header cố định + SliverList (lazy) — không dùng Column+Expanded trong chiều cao sheet hẹp.
        return DecoratedBox(
          decoration: BoxDecoration(
            color: MapScreenPalette.cardWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(MapScreenPalette.radiusLg)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        decoration: BoxDecoration(
                          color: MapScreenPalette.textSecondary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Kết quả gần bạn',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: MapScreenPalette.textPrimary,
                                  ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showSortPicker(context, ref),
                            child: const Text('Sắp xếp'),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: MapScreenPalette.chipInactiveBorder.withValues(alpha: 0.65),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(12, 4, 12, bottomInset + 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index.isOdd) {
                        return Divider(
                          height: 1,
                          color: MapScreenPalette.chipInactiveBorder.withValues(alpha: 0.65),
                        );
                      }
                      final i = index ~/ 2;
                      if (i >= items.length) return const SizedBox.shrink();
                      final station = items[i];
                      final origin = ref.watch(mapSheetUserOriginProvider).valueOrNull;
                      final dKm = origin == null
                          ? null
                          : mapHaversineKm(
                              origin.latitude,
                              origin.longitude,
                              station.latitude,
                              station.longitude,
                            );
                      return StationListItem(
                        station: station,
                        distanceKm: dKm,
                        onOpenDetail: () => focusMapStationAndOpenSummary(
                          context,
                          ref,
                          station,
                          distanceKm: dKm,
                        ),
                      );
                    },
                    childCount: items.isEmpty ? 0 : items.length * 2 - 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
    );
  }
}
