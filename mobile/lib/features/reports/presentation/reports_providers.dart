import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/reports_overview_dto.dart';
import '../data/reports_api.dart';

final reportsOverviewProvider = FutureProvider.autoDispose<ReportsOverviewDto>((ref) async {
  final api = ref.watch(reportsApiProvider);
  return api.getOverview();
});
