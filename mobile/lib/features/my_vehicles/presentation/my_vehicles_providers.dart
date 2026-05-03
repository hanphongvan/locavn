import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/my_vehicles_list_response.dart';
import '../data/my_vehicles_api.dart';

final myVehiclesListProvider = FutureProvider.autoDispose<MyVehiclesListResponse>((ref) async {
  final api = ref.watch(myVehiclesApiProvider);
  return api.getMyVehicles(page: 1, pageSize: 0);
});
