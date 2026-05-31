import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/presentation/citizen_login_prompt.dart';
import '../../more/presentation/account/account_activity_providers.dart';
import '../../my_reviews/presentation/my_station_reviews_providers.dart';
import '../../station_detail/presentation/station_detail_providers.dart';
import '../../station_detail/presentation/station_detail_shell_theme.dart';
import '../../stations/data/models/station_detail_dto.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../stations/station_open_status.dart';
import 'map_bad_report_compose_sheet.dart';
import 'map_providers.dart';
import 'map_review_compose_sheet.dart';
import 'station_map_preview/station_map_preview_strings.dart';
import 'station_map_preview/station_preview_action_row.dart';
import 'station_map_preview/station_preview_expanded_block.dart';
import 'station_map_preview/station_preview_mini_card.dart';
import 'station_map_preview/station_preview_open_badge.dart';
import 'station_map_preview/station_preview_price_quick_view.dart';
import 'station_map_preview/station_preview_rating_mini.dart';
import 'station_map_preview/station_preview_services_row.dart';

/// Bottom sheet when tapping a map marker: quick read + actions; expands for more detail.
///
/// [spotlightDistanceKm]: from `GET /api/stations/nearest` or local haversine on loaded markers only.
Future<void> showStationMapPreviewSheet({
  required BuildContext context,
  required StationMapItem station,
  double? spotlightDistanceKm,
}) {
  final hostContext = context;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (modalContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.38,
        minChildSize: 0.28,
        maxChildSize: 0.9,
        builder: (sheetContext, scrollController) {
          return Consumer(
            builder: (_, ref, _) {
              final detailAsync = ref.watch(stationDetailProvider(station.stationId));
              return _StationMapPreviewSheetBody(
                hostContext: hostContext,
                modalContext: modalContext,
                sheetContext: sheetContext,
                scrollController: scrollController,
                station: station,
                detailAsync: detailAsync,
                spotlightDistanceKm: spotlightDistanceKm,
              );
            },
          );
        },
      );
    },
  );
}

class _StationMapPreviewSheetBody extends ConsumerStatefulWidget {
  const _StationMapPreviewSheetBody({
    required this.hostContext,
    required this.modalContext,
    required this.sheetContext,
    required this.scrollController,
    required this.station,
    required this.detailAsync,
    this.spotlightDistanceKm,
  });

  final BuildContext hostContext;
  final BuildContext modalContext;
  final BuildContext sheetContext;
  final ScrollController scrollController;
  final StationMapItem station;
  final AsyncValue<StationDetailDto> detailAsync;
  final double? spotlightDistanceKm;

  @override
  ConsumerState<_StationMapPreviewSheetBody> createState() => _StationMapPreviewSheetBodyState();
}

class _StationMapPreviewSheetBodyState extends ConsumerState<_StationMapPreviewSheetBody> {
  static const double _expandThreshold = 0.48;
  double _extent = 0.38;

  @override
  Widget build(BuildContext context) {
    final sheetContext = widget.sheetContext;
    final theme = Theme.of(sheetContext);
    final station = widget.station;
    final detailAsync = widget.detailAsync;
    final catalogAsync = ref.watch(stationStoreServiceCatalogProvider);
    final detail = detailAsync.asData?.value;
    final showDetailProgress = detailAsync.isLoading && !detailAsync.hasValue;

    final name = station.stationName.trim().isNotEmpty
        ? station.stationName
        : '${StationMapPreviewStrings.stationFallbackPrefix}${station.stationId}';
    final address = _resolveAddress(detailAsync, station);
    final availability = StationOpenStatus.merged(station, detail);
    final ron = detail?.priceRon95 ?? station.priceRon95;
    final die = detail?.priceDiesel ?? station.priceDiesel;
    final e5 = _tryE5Price(detail);
    final selectedFuelCode = ref.watch(mapFiltersProvider.select((f) => f.fuelCode));
    final selectedFuelLabel = selectedFuelCode == null
        ? null
        : ref.watch(fuelProductLeavesProvider).maybeWhen(
              data: (leaves) {
                for (final l in leaves) {
                  if (l.code.toUpperCase() == selectedFuelCode.toUpperCase()) {
                    return l.name;
                  }
                }
                return selectedFuelCode;
              },
              orElse: () => selectedFuelCode,
            );
    final expanded = _extent >= _expandThreshold;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (n) {
        if ((n.extent - _extent).abs() > 0.015) {
          setState(() => _extent = n.extent);
        }
        return false;
      },
      child: ColoredBox(
        color: StationDetailShellTheme.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDetailProgress)
              LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: StationDetailShellTheme.primary,
              ),
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                children: [
                  StationPreviewMiniCard(stationName: name, address: address),
                  if (widget.spotlightDistanceKm != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${StationMapPreviewStrings.distancePrefix}'
                      '${_formatKm(widget.spotlightDistanceKm!)}'
                      '${StationMapPreviewStrings.distanceSuffix}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: StationDetailShellTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (detailAsync.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _detailErrorLine(detailAsync),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      StationPreviewOpenBadge(availability: availability),
                      const Spacer(),
                      StationPreviewRatingMini(stationId: station.stationId),
                    ],
                  ),
                  const SizedBox(height: 14),
                  StationPreviewPriceQuickView(
                    ron95: ron,
                    diesel: die,
                    e5Price: e5,
                    selectedFuelLabel: selectedFuelLabel,
                    selectedFuelPrice: selectedFuelCode == null
                        ? null
                        : station.priceForSelectedFuel,
                    pricesList: detail?.prices
                        ?.map((p) => (label: p.displayName, price: p.price))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  catalogAsync.when(
                    data: (catalog) => StationPreviewServicesRow(
                      station: station,
                      detail: detail,
                      catalog: catalog,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => StationPreviewServicesRow(
                      station: station,
                      detail: detail,
                      catalog: null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StationPreviewActionRow(
                    onDetail: () {
                      Navigator.of(widget.modalContext).pop();
                      widget.hostContext.push(AppRoute.stationDetail(station.stationId));
                    },
                    onDirections: () => _openDirections(widget.hostContext, station),
                    onRate: () {
                      if (!ref.read(authSessionControllerProvider).isAuthenticated) {
                        showCitizenLoginRequiredPrompt(widget.modalContext);
                        return;
                      }
                      showMapReviewComposeSheet(
                        context: widget.modalContext,
                        stationId: station.stationId,
                        stationName: name,
                        stationAddress: station.shortAddress,
                        onSubmitted: () {
                          ref.invalidate(stationDetailProvider(station.stationId));
                          ref.invalidate(stationRatingSummaryProvider(station.stationId));
                          ref.invalidate(accountActivitySummaryProvider);
                          ref.invalidate(myStationReviewsFirstPageProvider);
                          ref.read(stationReviewListBumpProvider(station.stationId).notifier).state++;
                        },
                      );
                    },
                    onReport: () {
                      if (!ref.read(authSessionControllerProvider).isAuthenticated) {
                        showCitizenLoginRequiredPrompt(widget.modalContext);
                        return;
                      }
                      showMapBadReportComposeSheet(
                        context: widget.modalContext,
                        stationId: station.stationId,
                        stationName: name,
                        stationAddress: station.shortAddress,
                      );
                    },
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 8),
                    StationPreviewExpandedBlock(
                      stationId: station.stationId,
                      stationName: name,
                      stationAddress: station.shortAddress,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double? _tryE5Price(StationDetailDto? d) {
  if (d == null) return null;
  final lines = d.latestReportingPrices?.lines;
  if (lines == null || lines.isEmpty) return null;
  for (final line in lines) {
    final label = '${line.tenThongKe ?? ''} ${line.maSo ?? ''}'.toUpperCase();
    if (label.contains('E5') || label.contains('RON 92') || label.contains('RON92') || label.contains('92')) {
      return line.so01 ?? line.so02 ?? line.so03;
    }
  }
  return null;
}

String _resolveAddress(AsyncValue<StationDetailDto> async, StationMapItem station) {
  final line = async.maybeWhen(
    data: (d) => d.addressLine?.trim(),
    orElse: () => null,
  );
  if (line != null && line.isNotEmpty) return line;
  final short = station.shortAddress?.trim();
  if (short != null && short.isNotEmpty) return short;
  return '${station.latitude.toStringAsFixed(5)}, ${station.longitude.toStringAsFixed(5)}';
}

String _detailErrorLine(AsyncValue<StationDetailDto> async) {
  final err = async.error;
  if (err is ApiException) {
    return '${StationMapPreviewStrings.detailLoadError} ${err.message}';
  }
  return StationMapPreviewStrings.detailLoadError;
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
        const SnackBar(content: Text(StationMapPreviewStrings.directionsOpenFail)),
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(StationMapPreviewStrings.directionsLaunchFail)),
    );
  }
}
