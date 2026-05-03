import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store_sale_prices/data/models/store_admin_fuel_product_list_item.dart';
import '../data/my_vehicles_api.dart';

/// Danh mục nhiên liệu cho form xe (`GET /api/my-vehicles/fuel-product-options`, chỉ JWT portal).
final myVehiclesFuelProductsProvider =
    FutureProvider.autoDispose<List<StoreAdminFuelProductListItem>>((ref) async {
  final api = ref.watch(myVehiclesApiProvider);
  return api.listFuelProductOptions(take: 500);
});
