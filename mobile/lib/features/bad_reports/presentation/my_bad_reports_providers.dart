import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/my_bad_reports_models.dart';
import '../data/my_bad_reports_api.dart';

/// First page of violation reports for the signed-in user.
final myBadReportsFirstPageProvider =
    FutureProvider.autoDispose<MyBadReportPage>((ref) async {
  final api = ref.watch(myBadReportsApiProvider);
  return api.list(skip: 0, take: 50);
});
