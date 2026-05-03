import 'package:flutter/material.dart';

import '../../stations/presentation/station_review_compose_sheet.dart';

/// Opens the shared public review composer (same as station detail).
///
/// Private violation reports live under `bad_reports/presentation/private_bad_report_compose_sheet.dart`.
Future<void> showMapReviewComposeSheet({
  required BuildContext context,
  required int stationId,
  required String stationName,
  String? stationAddress,
  VoidCallback? onSubmitted,
}) {
  return showStationReviewComposeSheet(
    context: context,
    stationId: stationId,
    stationName: stationName,
    stationAddress: stationAddress,
    onSubmitted: onSubmitted,
  );
}
