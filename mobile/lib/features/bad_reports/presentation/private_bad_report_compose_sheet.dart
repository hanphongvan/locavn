import 'package:flutter/material.dart';

import 'report_station_issue/report_station_issue_page.dart';

/// Matches `BadReportRequestValidator` on the server.
const int kBadReportMaxContentLength = 8000;
const int kBadReportMaxImageUrls = 10;
const int kBadReportMaxImageUrlLength = 2048;

bool isBadReportImageUrlAllowed(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t.length > kBadReportMaxImageUrlLength) return false;
  final uri = Uri.tryParse(t);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
  return uri.isScheme('https') || uri.isScheme('http');
}

/// Báo cáo vi phạm → `POST /api/bad-reports` (private; not shown as public reviews).
///
/// Selected violation type(s) are encoded into the `content` field together with optional description
/// (the API has no separate violation field). Images: upload via `POST /api/bad-reports/upload-image` (JWT),
/// then pass returned **http/https** URLs in `imageUrls` on submit.
Future<void> showPrivateBadReportComposeSheet({
  required BuildContext context,
  int? stationId,
  String? stationName,
  String? stationAddress,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => ReportStationIssuePage(
        stationId: stationId,
        stationName: stationName,
        stationAddress: stationAddress,
      ),
    ),
  );
}
