import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inventory/data/inventory_api.dart';
import '../../inventory/data/models/station_map_stock_by_ids_response.dart';
import '../../stations/data/models/station_map_item.dart';
import '../data/map_discovery.dart';
import '../data/map_geo.dart';
import '../data/map_user_location.dart';
import 'map_cheapest_station.dart';
import 'map_discovery_navigation.dart';
import 'map_discovery_results_sheet.dart';
import 'map_filter_sheet.dart';
import 'map_services_quick_sheet.dart';
import 'map_nearest_station.dart';
import 'map_providers.dart';
import 'map_screen_palette.dart';
import 'map_top_rated_station.dart';

/// Chip lọc nhanh (Gần nhất / Rẻ nhất / …) — hành vi giữ nguyên luồng discovery hiện có.
class MapFilterChipBar extends ConsumerStatefulWidget {
  const MapFilterChipBar({super.key});

  @override
  ConsumerState<MapFilterChipBar> createState() => _MapFilterChipBarState();
}

class _MapFilterChipBarState extends ConsumerState<MapFilterChipBar> {
  bool _inStockLoading = false;
  bool _nearestLoading = false;
  bool _cheapestLoading = false;

  List<StationMapItem> _requireLoadedItems(BuildContext context, WidgetRef ref) {
    final v = ref.read(stationMapMarkersProvider);
    final data = v.asData?.value;
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải dữ liệu cây xăng — thử lại sau vài giây.')),
      );
      return const [];
    }
    return data.items;
  }

  @override
  Widget build(BuildContext context) {
    final shortcut = ref.watch(mapDiscoveryShortcutProvider);
    final hasServiceFilter = ref.watch(mapFiltersProvider).selectedServiceCodes.isNotEmpty;

    Future<void> onNearest() async {
      if (_nearestLoading) return;
      if (_requireLoadedItems(context, ref).isEmpty) return;
      setState(() => _nearestLoading = true);
      ref.read(mapDiscoveryShortcutProvider.notifier).state = MapDiscoveryShortcut.nearest;
      try {
        // Spinner xoay trong giai đoạn GPS + API; tắt ngay khi sheet/snackbar đã sẵn sàng hiển thị.
        await presentNearestPetrolStation(
          context,
          ref,
          onResolveDone: () {
            if (mounted && _nearestLoading) {
              setState(() => _nearestLoading = false);
            }
          },
        );
      } finally {
        if (mounted && _nearestLoading) {
          setState(() => _nearestLoading = false);
        }
        if (context.mounted) {
          ref.read(mapDiscoveryShortcutProvider.notifier).state = MapDiscoveryShortcut.none;
        }
      }
    }

    Future<void> onCheapest() async {
      if (_cheapestLoading) return;
      if (_requireLoadedItems(context, ref).isEmpty) return;
      setState(() => _cheapestLoading = true);
      ref.read(mapDiscoveryShortcutProvider.notifier).state = MapDiscoveryShortcut.cheapest;
      try {
        final sheetFuture = presentCheapestPetrolStation(context, ref);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _cheapestLoading = false);
        });
        await sheetFuture;
      } finally {
        if (mounted && _cheapestLoading) {
          setState(() => _cheapestLoading = false);
        }
        if (context.mounted) {
          ref.read(mapDiscoveryShortcutProvider.notifier).state = MapDiscoveryShortcut.none;
        }
      }
    }

    Future<void> onTrusted() async {
      if (_requireLoadedItems(context, ref).isEmpty) return;
      ref.read(mapDiscoveryShortcutProvider.notifier).state = MapDiscoveryShortcut.bestRated;
      try {
        await presentTopRatedPetrolStation(context, ref);
      } finally {
        if (context.mounted) {
          ref.read(mapDiscoveryShortcutProvider.notifier).state = MapDiscoveryShortcut.none;
        }
      }
    }

    Future<void> onStock() async {
      final items = _requireLoadedItems(context, ref);
      if (items.isEmpty) return;
      if (_inStockLoading) return;
      setState(() => _inStockLoading = true);
      ref.read(mapDiscoveryShortcutProvider.notifier).state = MapDiscoveryShortcut.openNow;
      try {
        final api = ref.read(inventoryApiProvider);
        final ids = items.map((e) => e.stationId).toList(growable: false);
        final stockFuture = api.getMapStockByDonViIds(ids);
        final locFuture = requestMapUserLocation();
        final results = await Future.wait<Object>([stockFuture, locFuture]);
        final stock = results[0] as StationMapStockByIdsResponse;
        final loc = results[1] as MapUserLocationOutcome;
        final byId = {for (final s in stock.items) s.stationId: s.totalStockQuantity};
        final inStock = items
            .where((e) => (byId[e.stationId] ?? 0) > 0)
            .toList();
        if (loc is MapUserLocationOk) {
          const stockRadiusKm = 5.0;
          double kmTo(StationMapItem s) => mapHaversineKm(
                loc.position.latitude,
                loc.position.longitude,
                s.latitude,
                s.longitude,
              );
          bool inRadius(StationMapItem s) => kmTo(s) <= stockRadiusKm;
          inStock.sort((a, b) {
            final aIn = inRadius(a);
            final bIn = inRadius(b);
            if (aIn != bIn) {
              return aIn ? -1 : 1;
            }
            if (aIn) {
              final dk = kmTo(a).compareTo(kmTo(b));
              if (dk != 0) {
                return dk;
              }
              return (byId[b.stationId] ?? 0).compareTo(byId[a.stationId] ?? 0);
            }
            final byStock = (byId[b.stationId] ?? 0).compareTo(byId[a.stationId] ?? 0);
            if (byStock != 0) {
              return byStock;
            }
            return kmTo(a).compareTo(kmTo(b));
          });
        } else {
          inStock.sort((a, b) => (byId[b.stationId] ?? 0).compareTo(byId[a.stationId] ?? 0));
        }
        final ranked = inStock.take(60).toList();
        if (!context.mounted) return;
        final sheetFuture = showMapDiscoveryResultsSheet(
          context: context,
          rows: ranked.map((e) {
            if (loc is MapUserLocationOk) {
              return MapStationListRow(
                item: e,
                distanceKm: mapHaversineKm(
                  loc.position.latitude,
                  loc.position.longitude,
                  e.latitude,
                  e.longitude,
                ),
              );
            }
            return MapStationListRow(item: e);
          }).toList(),
          title: 'Còn hàng',
          subtitle: 'Các cửa hàng còn xăng/dầu gần bạn',
          chrome: MapDiscoverySheetChrome.inStock,
          emptyMessage: 'Chưa tìm thấy cửa hàng còn hàng',
          emptySubtitle: 'Vui lòng thử thay đổi bộ lọc hoặc khu vực tìm kiếm',
          initialChildSize: ranked.length <= 4 ? 0.36 : 0.44,
          onStationChosen: (row) => focusMapStationAndOpenSummary(
                context,
                ref,
                row.item,
                distanceKm: row.distanceKm,
              ),
        );
        // Sheet future chỉ complete khi đóng modal — tắt spinner sau frame đầu khi route đã lên.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _inStockLoading = false);
          }
        });
        await sheetFuture;
      } on Object catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không tải được tồn kho: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _inStockLoading = false);
        }
        if (context.mounted) {
          ref.read(mapDiscoveryShortcutProvider.notifier).state = MapDiscoveryShortcut.none;
        }
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MapFilterPill(
            selected: shortcut == MapDiscoveryShortcut.nearest,
            icon: Icons.near_me_outlined,
            label: 'Gần nhất',
            busy: _nearestLoading,
            onTap: () => unawaited(onNearest()),
          ),
          const SizedBox(width: 10),
          _MapFilterPill(
            selected: shortcut == MapDiscoveryShortcut.cheapest,
            icon: Icons.payments_outlined,
            label: 'Rẻ nhất',
            busy: _cheapestLoading,
            onTap: () => unawaited(onCheapest()),
          ),
          const SizedBox(width: 10),
          _MapFilterPill(
            selected: shortcut == MapDiscoveryShortcut.bestRated,
            icon: Icons.verified_outlined,
            label: 'Uy tín',
            onTap: () => unawaited(onTrusted()),
          ),
          const SizedBox(width: 10),
          _MapFilterPill(
            selected: hasServiceFilter,
            icon: Icons.design_services_outlined,
            label: 'Dịch vụ',
            onTap: () => showMapServicesQuickFilterSheet(context, ref),
          ),
          const SizedBox(width: 10),
          _MapFilterPill(
            selected: shortcut == MapDiscoveryShortcut.openNow,
            icon: Icons.inventory_2_outlined,
            label: 'Còn hàng',
            busy: _inStockLoading,
            onTap: () => unawaited(onStock()),
          ),
          const SizedBox(width: 10),
          _MapFilterPill(
            selected: false,
            icon: Icons.tune_rounded,
            label: 'Bộ lọc',
            onTap: () => showMapFilterSheet(context, ref),
          ),
        ],
      ),
    );
  }
}

class _MapFilterPill extends StatelessWidget {
  const _MapFilterPill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  /// Đang xử lý (ví dụ tải tồn kho) — hiện spinner, chặn tap lặp.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final progressColor = selected ? Colors.white : MapScreenPalette.primaryBlue;
    return Material(
      color: selected ? MapScreenPalette.primaryBlue : MapScreenPalette.cardWhite,
      elevation: selected ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? MapScreenPalette.primaryBlue : MapScreenPalette.chipInactiveBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                Semantics(
                  label: 'Đang tải',
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: progressColor,
                    ),
                  ),
                )
              else
                Icon(icon, size: 18, color: selected ? Colors.white : MapScreenPalette.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : MapScreenPalette.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
