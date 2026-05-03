import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pricing/data/models/latest_fuel_prices_response.dart';
import '../../pricing/data/prices_api.dart';

final latestFuelPricesProvider = FutureProvider.autoDispose<LatestFuelPricesResponse>((ref) async {
  final api = ref.watch(pricesApiProvider);
  return api.getLatestPrices();
});
