import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../map/data/map_geo.dart';
import '../../map/data/map_user_location.dart';
import '../../map/presentation/map_cheapest_station.dart';
import '../../map/presentation/map_discovery_results_sheet.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../map/data/map_filters.dart';
import '../../store_services/presentation/store_service_icon.dart';
import '../../map/presentation/map_providers.dart';
import '../data/leader_map_ui_state.dart';
import 'leader_map_ui_provider.dart';
import 'leader_theme.dart';

/// Sheet chọn dịch vụ lọc cửa hàng lẻ trên bản đồ Lãnh đạo (cùng catalog với Citizen).
Future<void> showLeaderRetailServicesFilterSheet(BuildContext context, WidgetRef ref) {
  final initial = List<String>.from(ref.read(leaderMapUiProvider).selectedServiceCodes);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _LeaderRetailServicesSheet(initialSelected: initial, hostRef: ref);
    },
  );
}

class _LeaderRetailServicesSheet extends ConsumerStatefulWidget {
  const _LeaderRetailServicesSheet({
    required this.initialSelected,
    required this.hostRef,
  });

  final List<String> initialSelected;
  final WidgetRef hostRef;

  @override
  ConsumerState<_LeaderRetailServicesSheet> createState() => _LeaderRetailServicesSheetState();
}

class _LeaderRetailServicesSheetState extends ConsumerState<_LeaderRetailServicesSheet> {
  late Set<String> _draft;

  @override
  void initState() {
    super.initState();
    _draft = {for (final c in widget.initialSelected) c.toUpperCase()};
  }

  void _apply() {
    final next = widget.hostRef.read(leaderMapUiProvider).copyWith(
          selectedServiceCodes: MapFilters.normalizeSelectedServices(_draft),
        );
    widget.hostRef.read(leaderMapUiProvider.notifier).state = next;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(stationStoreServiceCatalogProvider);
    final screenH = MediaQuery.sizeOf(context).height;
    final sheetH = (screenH * 0.58).clamp(320.0, screenH * 0.75);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: LeaderTheme.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: sheetH,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dịch vụ tại cửa hàng',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: LeaderTheme.navy,
                            ),
                      ),
                    ),
                    TextButton(onPressed: () => setState(_draft.clear), child: const Text('Xoá')),
                  ],
                ),
              ),
              Expanded(
                child: catalogAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Không tải danh mục: $e')),
                  data: (catalog) {
                    if (catalog.isEmpty) {
                      return const Center(child: Text('Chưa có danh mục dịch vụ.'));
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in catalog)
                            FilterChip(
                              label: Text(item.defaultDisplayName),
                              avatar: Icon(
                                storeServiceIconForCode(item.serviceCode, item.iconKey),
                                size: 22,
                                color: LeaderTheme.navy,
                              ),
                              selected: _draft.contains(item.serviceCode.toUpperCase()),
                              onSelected: (on) {
                                setState(() {
                                  final u = item.serviceCode.toUpperCase();
                                  if (on) {
                                    _draft.add(u);
                                  } else {
                                    _draft.remove(u);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + MediaQuery.paddingOf(context).bottom),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Huỷ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _apply,
                        child: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

CheapestFuelQuery _cheapestFuelFromLeader(LeaderMapFuelFilter f) =>
    f == LeaderMapFuelFilter.dau ? CheapestFuelQuery.diesel : CheapestFuelQuery.ron95;

/// Gần nhất — trong [items] (đã lọc khung nhìn), sort theo GPS.
Future<void> leaderRetailPresentNearest({
  required BuildContext context,
  required List<StationMapItem> items,
  required Future<void> Function(StationMapItem item, double? distanceKm) onPick,
}) async {
  if (items.isEmpty) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Chưa có cửa hàng trên bản đồ — bật lớp cửa hàng hoặc zoom khu vực.')),
    );
    return;
  }
  final loc = await requestMapUserLocation(
    acceptLastKnownMaxAge: const Duration(minutes: 3),
  );
  if (!context.mounted) return;
  switch (loc) {
    case MapUserLocationDenied():
    case MapUserLocationDeniedForever():
    case MapUserLocationServiceDisabled():
    case MapUserLocationGnssTimeout():
      showMapUserLocationOutcomeSnackbar(context, loc, featureLabel: 'tìm cửa hàng gần nhất');
      return;
    case MapUserLocationOk(:final position):
      final uLat = position.latitude;
      final uLng = position.longitude;
      double kmTo(StationMapItem s) => mapHaversineKm(uLat, uLng, s.latitude, s.longitude);
      final sorted = List<StationMapItem>.from(items)..sort((a, b) => kmTo(a).compareTo(kmTo(b)));
      final rows = <MapStationListRow>[
        for (final e in sorted.take(40))
          MapStationListRow(item: e, distanceKm: kmTo(e)),
      ];
      await showMapDiscoveryResultsSheet(
        context: context,
        rows: rows,
        title: 'Gần nhất',
        subtitle: 'Cửa hàng trong khung nhìn (theo vị trí của bạn)',
        chrome: MapDiscoverySheetChrome.nearest,
        initialChildSize: 0.42,
        onStationChosen: (row) async {
          await onPick(row.item, row.distanceKm);
        },
      );
  }
}

/// Rẻ nhất — client 5 km + loại nhiên liệu theo tab Xăng/Dầu.
Future<void> leaderRetailPresentCheapest({
  required BuildContext context,
  required WidgetRef ref,
  required List<StationMapItem> items,
  required LeaderMapFuelFilter fuel,
  required Future<void> Function(StationMapItem item, double? distanceKm) onPick,
}) async {
  if (items.isEmpty) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Chưa có cửa hàng trên bản đồ — bật lớp cửa hàng hoặc zoom khu vực.')),
    );
    return;
  }
  final loc = await requestMapUserLocation(
    acceptLastKnownMaxAge: const Duration(minutes: 3),
  );
  if (!context.mounted) return;
  switch (loc) {
    case MapUserLocationDenied():
    case MapUserLocationDeniedForever():
    case MapUserLocationServiceDisabled():
    case MapUserLocationGnssTimeout():
      showMapUserLocationOutcomeSnackbar(context, loc, featureLabel: 'tìm giá rẻ nhất trong 5 km');
      return;
    case MapUserLocationOk(:final position):
      final q = _cheapestFuelFromLeader(fuel);
      final pick = pickCheapestStationInRadiusFromLoadedMarkers(
        items: items,
        userLat: position.latitude,
        userLng: position.longitude,
        fuel: q,
      );
      if (pick == null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              'Không có cửa hàng trong 5 km có ${cheapestFuelTitle(q).toLowerCase()} trong dữ liệu hiện tại.',
            ),
          ),
        );
        return;
      }
      final km = mapHaversineKm(
        position.latitude,
        position.longitude,
        pick.latitude,
        pick.longitude,
      );
      await showMapDiscoveryResultsSheet(
        context: context,
        rows: [
          MapStationListRow(
            item: pick,
            distanceKm: km,
            priceEmphasisFuel: cheapestFuelApiValue(q),
          ),
        ],
        title: 'Rẻ nhất',
        subtitle: 'Trong 5 km quanh bạn (theo marker đã tải)',
        chrome: MapDiscoverySheetChrome.cheapest,
        initialChildSize: 0.38,
        onStationChosen: (row) async {
          await onPick(row.item, row.distanceKm);
        },
      );
  }
}
