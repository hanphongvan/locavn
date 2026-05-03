import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'leader_map_api.dart';
import 'leader_map_models.dart';

/// Đầu mối + tồn (GET `/api/leader/map/distributors`).
final leaderMapDistributorsProvider = FutureProvider.autoDispose<LeaderMapDistributorsResponse>((ref) async {
  final api = ref.watch(leaderMapApiProvider);
  return api.getDistributors();
});
