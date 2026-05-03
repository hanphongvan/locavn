import 'package:flutter/material.dart';

import '../../bad_reports/presentation/private_bad_report_compose_sheet.dart';

/// Opens the station violation report form (`POST /api/bad-reports`).
///
/// Public reviews use a different API and UI — do not merge flows.
Future<void> showMapBadReportComposeSheet({
  required BuildContext context,
  int? stationId,
  String? stationName,
  String? stationAddress,
}) {
  return showPrivateBadReportComposeSheet(
    context: context,
    stationId: stationId,
    stationName: stationName,
    stationAddress: stationAddress,
  );
}
