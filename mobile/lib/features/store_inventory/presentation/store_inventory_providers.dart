import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store_sale_prices/data/models/store_don_vi_tinh_lookup.dart';
import '../../store_sale_prices/data/models/store_fuel_product_lookup.dart';
import '../../store_sale_prices/data/store_sale_prices_api.dart';
import '../data/models/inventory_current_line.dart';
import '../data/models/inventory_transaction_bundle.dart';
import '../data/store_inventory_api.dart';
import '../data/store_inventory_repository.dart';

final storeInventoryCurrentProvider =
    FutureProvider.autoDispose<List<InventoryCurrentLine>>((ref) {
  return ref.watch(storeInventoryRepositoryProvider).listCurrentStock();
});

final storeInventoryVouchersProvider =
    FutureProvider.autoDispose<List<InventoryTransactionHeaderVm>>((ref) {
  return ref.watch(storeInventoryRepositoryProvider).listTransactionsWithTotals();
});

final storeInventoryProductsProvider =
    FutureProvider.autoDispose<List<StoreFuelProductLookup>>((ref) {
  return ref.watch(storeSalePricesApiProvider).getProducts(take: 300);
});

final storeInventoryUnitsProvider = FutureProvider.autoDispose<List<StoreDonViTinhLookup>>((ref) {
  return ref.watch(storeSalePricesApiProvider).getDonViTinh();
});

/// Header + detail lines for voucher detail screen.
final inventoryTransactionBundleProvider =
    FutureProvider.autoDispose.family<InventoryTransactionBundle, int>((ref, headerId) {
  return ref.watch(storeInventoryApiProvider).getTransactionBundle(headerId);
});
