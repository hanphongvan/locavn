import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../stations/data/models/station_map_item.dart';
import '../data/map_geo.dart';
import '../data/map_user_location.dart';
import 'map_discovery_navigation.dart';
import 'map_discovery_results_sheet.dart';
import 'map_providers.dart';
import 'map_screen_palette.dart';

/// Bán kính (km) quanh GPS — **chỉ** trong tập marker đã tải (`stationMapMarkersProvider`).
const double kCheapestLocalRadiusKm = 5.0;

/// Chọn trạm giá thấp nhất trong [radiusKm]; hòa: gần hơn, rồi `stationId` nhỏ hơn.
StationMapItem? pickCheapestStationInRadiusFromLoadedMarkers({
  required List<StationMapItem> items,
  required double userLat,
  required double userLng,
  required CheapestFuelQuery fuel,
  double radiusKm = kCheapestLocalRadiusKm,
}) {
  double? priceOf(StationMapItem s) => switch (fuel) {
        CheapestFuelQuery.diesel => s.priceDiesel,
        CheapestFuelQuery.ron95 => s.priceRon95,
      };

  StationMapItem? best;
  double? bestPrice;
  double? bestDist;
  for (final s in items) {
    if (!s.hasValidCoord) continue;
    final d = mapHaversineKm(userLat, userLng, s.latitude, s.longitude);
    if (d > radiusKm) continue;
    final p = priceOf(s);
    if (p == null || !p.isFinite || p <= 0) continue;
    if (best == null) {
      best = s;
      bestPrice = p;
      bestDist = d;
      continue;
    }
    final bp = bestPrice!;
    final bd = bestDist!;
    if (p < bp || (p == bp && d < bd) || (p == bp && d == bd && s.stationId < best.stationId)) {
      best = s;
      bestPrice = p;
      bestDist = d;
    }
  }
  return best;
}

/// Loại nhiên liệu cho chip RON 95 / Diesel (giá lấy từ marker map).
enum CheapestFuelQuery {
  ron95,
  diesel,
}

String cheapestFuelApiValue(CheapestFuelQuery q) => switch (q) {
      CheapestFuelQuery.ron95 => 'ron95',
      CheapestFuelQuery.diesel => 'diesel',
    };

String cheapestFuelTitle(CheapestFuelQuery q) => switch (q) {
      CheapestFuelQuery.ron95 => 'E10 rẻ nhất',
      CheapestFuelQuery.diesel => 'Diesel rẻ nhất',
    };

/// Bottom sheet **Giá rẻ nhất** trong **5 km** quanh GPS: chỉ xét marker bản đồ đã tải (không gọi API spotlight).
Future<void> presentCheapestPetrolStation(
  BuildContext context,
  WidgetRef ref, {
  CheapestFuelQuery initialFuel = CheapestFuelQuery.ron95,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: MapScreenPalette.filterSheetBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return _CheapestSpotlightSheet(
        parentContext: context,
        initialFuel: initialFuel,
      );
    },
  );
}

/// Mở với loại nhiên liệu sẵn (ví dụ từ bộ lọc toàn bản đồ).
Future<void> presentCheapestPetrolStationForFuel(
  BuildContext context,
  WidgetRef ref,
  CheapestFuelQuery fuel,
) =>
    presentCheapestPetrolStation(context, ref, initialFuel: fuel);

class _CheapestSpotlightSheet extends ConsumerStatefulWidget {
  const _CheapestSpotlightSheet({
    required this.parentContext,
    required this.initialFuel,
  });

  final BuildContext parentContext;
  final CheapestFuelQuery initialFuel;

  @override
  ConsumerState<_CheapestSpotlightSheet> createState() => _CheapestSpotlightSheetState();
}

class _CheapestSpotlightSheetState extends ConsumerState<_CheapestSpotlightSheet> {
  late CheapestFuelQuery _fuel;
  bool _loading = true;
  String? _error;
  MapStationListRow? _row;

  /// Lưu ở [didChangeDependencies] — không được gọi [ProviderScope.containerOf] trong [dispose] (context đã deactivate).
  ProviderContainer? _providerContainer;

  @override
  void initState() {
    super.initState();
    _fuel = widget.initialFuel;
    mapClearCheapSpotlightMarker(ref);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerContainer = ProviderScope.containerOf(context);
  }

  @override
  void dispose() {
    final container = _providerContainer;
    super.dispose();
    if (container != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        container.read(mapCheapSpotlightStationIdProvider.notifier).state = null;
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final items = ref.read(stationMapMarkersProvider).asData?.value.items ?? const <StationMapItem>[];
    if (items.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Chưa có dữ liệu bản đồ — tải xong rồi thử lại.';
          _row = null;
        });
      }
      return;
    }

    mapClearCheapSpotlightMarker(ref);

    final loc = await requestMapUserLocation(
      acceptLastKnownMaxAge: const Duration(minutes: 2),
    );
    if (!mounted) return;

    switch (loc) {
      case MapUserLocationDenied():
        setState(() {
          _loading = false;
          _error = 'Cần quyền vị trí để tìm giá rẻ nhất trong 5 km quanh bạn.';
          _row = null;
        });
        return;
      case MapUserLocationDeniedForever():
        setState(() {
          _loading = false;
          _error = 'Quyền vị trí đang bị tắt. Bật trong Cài đặt để tìm giá rẻ nhất trong 5 km.';
          _row = null;
        });
        return;
      case MapUserLocationServiceDisabled():
        setState(() {
          _loading = false;
          _error = 'GPS đang tắt. Bật dịch vụ vị trí để tìm giá rẻ nhất trong 5 km.';
          _row = null;
        });
        return;
      case MapUserLocationGnssTimeout():
        setState(() {
          _loading = false;
          _error = 'Chậm lấy vị trí GPS. Thử lại sau vài giây hoặc ra nơi sóng tốt hơn.';
          _row = null;
        });
        return;
      case MapUserLocationOk(:final position):
        final item = pickCheapestStationInRadiusFromLoadedMarkers(
          items: items,
          userLat: position.latitude,
          userLng: position.longitude,
          fuel: _fuel,
        );
        if (item == null) {
          setState(() {
            _loading = false;
            _error =
                'Không có cây xăng nào trong 5 km có ${cheapestFuelTitle(_fuel).toLowerCase()} trong dữ liệu '
                'bản đồ đang tải. Thử đổi khu vực hoặc bộ lọc, hoặc chờ tải thêm trạm.';
            _row = null;
          });
          return;
        }

        final distanceKm = mapHaversineKm(
          position.latitude,
          position.longitude,
          item.latitude,
          item.longitude,
        );

        ref.read(mapEphemeralStationProvider.notifier).state = null;
        ref.read(mapCheapSpotlightStationIdProvider.notifier).state = item.stationId;

        final row = MapStationListRow(
          item: item,
          spotlightAverageRating: null,
          spotlightReviewCount: null,
          distanceKm: distanceKm,
          priceEmphasisFuel: cheapestFuelApiValue(_fuel),
        );

        setState(() {
          _row = row;
          _loading = false;
        });
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const titleClr = Color(0xFF0B3A7A);
    const subClr = Color(0xFF6B7897);
    const cardBorder = Color(0xFFE6EEF8);

    return ColoredBox(
      color: MapScreenPalette.filterSheetBackground,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.32,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rẻ nhất',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: titleClr,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Các cửa hàng có giá rẻ nhất quanh bạn',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: subClr,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8EF).withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF35D66B).withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.payments_rounded, size: 16, color: MapScreenPalette.filterPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'Rẻ nhất',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: MapScreenPalette.filterPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: cardBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: SegmentedButton<CheapestFuelQuery>(
                  segments: const [
                    ButtonSegment<CheapestFuelQuery>(
                      value: CheapestFuelQuery.ron95,
                      label: Text('Xăng'),
                      icon: Icon(Icons.local_gas_station_outlined, size: 18),
                    ),
                    ButtonSegment<CheapestFuelQuery>(
                      value: CheapestFuelQuery.diesel,
                      label: Text('Dầu'),
                      icon: Icon(Icons.oil_barrel_outlined, size: 18),
                    ),
                  ],
                  style: ButtonStyle(
                    visualDensity: VisualDensity.comfortable,
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return MapScreenPalette.filterChipSelectedBg;
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return MapScreenPalette.filterChipSelectedText;
                      }
                      return MapScreenPalette.filterTextSecondary;
                    }),
                    side: WidgetStateProperty.all(BorderSide.none),
                  ),
                  selected: {_fuel},
                  onSelectionChanged: (Set<CheapestFuelQuery> next) {
                    if (next.isEmpty) return;
                    setState(() => _fuel = next.first);
                    _load();
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_loading) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: MapScreenPalette.filterPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Đang tải…',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: subClr,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...List.generate(
                          2,
                          (i) => Padding(
                            padding: EdgeInsets.only(bottom: i == 0 ? 12 : 0),
                            child: Container(
                              height: 76,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: cardBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error, height: 1.35),
                  ),
                )
              else if (_row != null)
                MapStationDiscoveryTile(
                  row: _row!,
                  chrome: MapDiscoverySheetChrome.cheapest,
                  onTap: () async {
                    final r = _row!;
                    mapClearCheapSpotlightMarker(ref);
                    Navigator.of(context).pop();
                    if (!widget.parentContext.mounted) return;
                    await focusMapStationAndOpenSummary(
                      widget.parentContext,
                      ref,
                      r.item,
                      distanceKm: r.distanceKm,
                    );
                  },
                )
              else
                Text(
                  'Không có dữ liệu.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: subClr, fontWeight: FontWeight.w600),
                ),
            ],
          );
        },
      ),
    );
  }
}
