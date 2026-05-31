import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../stations/data/models/station_detail_dto.dart';
import '../../stations/domain/station_availability.dart' show LocalClockTime;
import '../../stations/station_open_status.dart';
import '../../../shared/widgets/async_value_body.dart';
import 'station_detail_formatters.dart';
import 'station_detail_providers.dart';
import 'station_detail_strings.dart';
import 'station_detail_shell_theme.dart';
import 'station_reviews_section.dart';
import 'widgets/station_detail_action_buttons.dart';
import 'widgets/station_detail_secondary_sections.dart';
import 'widgets/station_extra_info.dart';
import 'widgets/station_header_card.dart';
import 'widgets/station_price_list.dart';
import 'widgets/station_rating_summary.dart';

/// Detail for `GET /api/stations/{id}` plus public reviews (`rating-summary`, `reviews`).
class StationDetailShellPage extends ConsumerWidget {
  const StationDetailShellPage({super.key, required this.stationId});

  final int stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stationDetailProvider(stationId));

    return Scaffold(
      backgroundColor: StationDetailShellTheme.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: StationDetailShellTheme.background,
        foregroundColor: StationDetailShellTheme.primary,
        title: async.maybeWhen(
          data: (s) => Text(
            _stationTitle(s, stationId),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: StationDetailShellTheme.textPrimary,
            ),
          ),
          orElse: () => Text(
            '${StationDetailStrings.stationFallbackPrefix}$stationId',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: StationDetailShellTheme.textPrimary,
            ),
          ),
        ),
        actions: [
          if (async.hasValue &&
              async.value!.latitude != null &&
              async.value!.longitude != null)
            IconButton(
              tooltip: StationDetailStrings.directionsTooltip,
              onPressed: () => _openDirections(
                context,
                async.value!.latitude!,
                async.value!.longitude!,
              ),
              icon: const Icon(Icons.directions_rounded),
            ),
        ],
      ),
      body: AsyncValueBody<StationDetailDto>(
        value: async,
        errorLogLabel: StationDetailStrings.errorLogLabel,
        loadingLabel: StationDetailStrings.loadingDetail,
        onRetry: () => ref.invalidate(stationDetailProvider(stationId)),
        dataBuilder: (data) => _StationDetailBody(stationId: stationId, data: data),
      ),
    );
  }
}

class _StationDetailBody extends StatelessWidget {
  const _StationDetailBody({required this.stationId, required this.data});

  final int stationId;
  final StationDetailDto data;

  @override
  Widget build(BuildContext context) {
    final displayName = _stationTitle(data, stationId);
    final addressLines = _fullAddressLines(data);
    final addressSingle = _stationAddressSingleLine(data);
    final availability = StationOpenStatus.forDetail(data);
    final gap = StationDetailShellTheme.sectionGap;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              StationHeaderCard(
                stationName: displayName,
                addressLines: addressLines,
                availability: availability,
                openingDisplay: LocalClockTime.displayCell(data.openingTime),
                closingDisplay: LocalClockTime.displayCell(data.closingTime),
              ),
              SizedBox(height: gap),
              StationPriceList(data: data),
              SizedBox(height: gap),
              if (data.storeServices != null && data.storeServices!.isNotEmpty) ...[
                StationStoreServicesCard(services: data.storeServices!),
                SizedBox(height: gap),
              ],
              StationRatingSummary(stationId: stationId),
              SizedBox(height: gap),
              StationReviewsSection(
                stationId: stationId,
                stationName: displayName,
                stationAddress: addressSingle,
                listOnly: true,
              ),
              if (_hasWeeklyHours(data)) ...[
                SizedBox(height: gap),
                StationWeeklyCard(slots: data.weeklyOperatingHours!),
              ],
              if (_hasStockSummary(data)) ...[
                SizedBox(height: gap),
                StationStockSection(
                  stock: data.latestReportingStock!,
                  periodLine: data.latestReportingStock!.period != null
                      ? stationDetailPeriodLine(data.latestReportingStock!.period!)
                      : '',
                ),
              ],
              if (_hasAdminArea(data)) ...[
                SizedBox(height: gap),
                StationAreaCard(
                  province: _provinceLine(data),
                  ward: _wardLine(data),
                ),
              ],
              if (_hasContact(data)) ...[
                SizedBox(height: gap),
                StationContactCard(
                  phone: stationDetailNonEmpty(data.phone),
                  email: stationDetailNonEmpty(data.email),
                ),
              ],
              SizedBox(height: gap),
              StationExtraInfo(data: data),
              const SizedBox(height: 28),
            ],
          ),
        ),
        StationDetailActionButtons(
          stationId: stationId,
          displayName: displayName,
          stationAddress: addressSingle,
        ),
      ],
    );
  }
}

Future<void> _openDirections(BuildContext context, double lat, double lng) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
  );
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

String _stationTitle(StationDetailDto s, int stationId) {
  final t = s.stationName.trim();
  if (t.isNotEmpty) return t;
  return '${StationDetailStrings.stationFallbackPrefix}$stationId';
}

List<String> _fullAddressLines(StationDetailDto d) {
  final lines = <String>[];
  final street = stationDetailNonEmpty(d.addressLine);
  if (street != null) lines.add(street);

  final tail = <String>[];
  final ward = stationDetailNonEmpty(d.wardName);
  if (ward != null) tail.add(ward);
  final prov = stationDetailNonEmpty(d.provinceName);
  if (prov != null) tail.add(prov);
  if (tail.isNotEmpty) {
    lines.add(tail.join(', '));
  }
  return lines;
}

String? _stationAddressSingleLine(StationDetailDto d) {
  final lines = _fullAddressLines(d);
  if (lines.isEmpty) return null;
  return lines.join(', ');
}

bool _hasWeeklyHours(StationDetailDto d) =>
    d.weeklyOperatingHours != null && d.weeklyOperatingHours!.isNotEmpty;

bool _hasStockSummary(StationDetailDto d) {
  final s = d.latestReportingStock;
  return s != null && s.lineCount > 0;
}

bool _hasAdminArea(StationDetailDto d) {
  return stationDetailNonEmpty(d.provinceName) != null ||
      stationDetailNonEmpty(d.provinceCode) != null ||
      stationDetailNonEmpty(d.wardName) != null ||
      stationDetailNonEmpty(d.wardCode) != null;
}

bool _hasContact(StationDetailDto d) =>
    stationDetailNonEmpty(d.phone) != null || stationDetailNonEmpty(d.email) != null;

String _provinceLine(StationDetailDto d) {
  final name = stationDetailNonEmpty(d.provinceName);
  final code = stationDetailNonEmpty(d.provinceCode);
  if (name != null && code != null) return '$name (mã $code)';
  return name ?? code ?? StationDetailStrings.emDash;
}

String _wardLine(StationDetailDto d) {
  final name = stationDetailNonEmpty(d.wardName);
  final code = stationDetailNonEmpty(d.wardCode);
  if (name != null && code != null) return '$name (mã $code)';
  return name ?? code ?? StationDetailStrings.emDash;
}
