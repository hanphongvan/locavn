import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/store_admin_fuel_product_list_item.dart';
import '../data/models/store_admin_store_row.dart';
import '../data/models/store_don_vi_tinh_lookup.dart';
import '../data/models/store_fuel_product_lookup.dart';
import '../data/models/store_sale_price_list_item.dart';
import '../data/store_admin_hub_catalog_api.dart';
import '../data/store_price_list_constants.dart';
import '../data/store_sale_prices_repository.dart';

/// Hub filter state — mirrors Angular `filterForm.productId` + `historyFocusProductId`.
///
/// Angular: `histPid = historyFocusProductId() ?? f.productId ?? null` for
/// `GET .../by-store/{donViId}?productId=`; current table uses `filterByProductId(store.cur, productId)`.
@immutable
class StoreSalePricesHubQuery {
  const StoreSalePricesHubQuery({
    this.currentProductFilter,
    this.historyFocusProductId,
  });

  final int? currentProductFilter;
  final int? historyFocusProductId;

  int? get historyApiProductId => historyFocusProductId ?? currentProductFilter;

  @override
  bool operator ==(Object other) =>
      other is StoreSalePricesHubQuery &&
      other.currentProductFilter == currentProductFilter &&
      other.historyFocusProductId == historyFocusProductId;

  @override
  int get hashCode => Object.hash(currentProductFilter, historyFocusProductId);
}

final storeSalePricesHubProvider =
    FutureProvider.autoDispose.family<StoreSalePricesHubData, StoreSalePricesHubQuery>((ref, q) async {
  final repo = ref.watch(storeSalePricesRepositoryProvider);
  final allCurrent = await repo.loadCurrentPricesForSessionStore();
  final current = q.currentProductFilter == null
      ? allCurrent
      : allCurrent.where((e) => e.productId == q.currentProductFilter).toList();
  final history = await repo.loadHistoryForSessionStore(productId: q.historyApiProductId);
  return StoreSalePricesHubData(current: current, history: history);
});

class StoreSalePricesHubData {
  const StoreSalePricesHubData({
    required this.current,
    required this.history,
  });

  final List<StoreSalePriceListItem> current;
  final List<StoreSalePriceListItem> history;
}

/// Angular hub: `forkJoin` fuel `GET /api/admin/fuel-products` + stores `GET /api/admin/stores`.
final storeSalePricesHubCatalogProvider = FutureProvider.autoDispose<StoreSalePricesHubCatalog>((ref) async {
  final api = ref.watch(storeAdminHubCatalogApiProvider);
  final products = await api.listFuelProducts(
    skip: 0,
    take: StorePriceListConstants.hubFuelProductsTake,
  );
  final stores = await api.listStores(
    skip: 0,
    take: StorePriceListConstants.hubStoresTake,
  );
  return StoreSalePricesHubCatalog(products: products, stores: stores);
});

class StoreSalePricesHubCatalog {
  const StoreSalePricesHubCatalog({
    required this.products,
    required this.stores,
  });

  final List<StoreAdminFuelProductListItem> products;
  final List<StoreAdminStoreRow> stores;
}

/// Product + unit pickers for batch / edit sheets (Angular form `forkJoin` take **500**).
final storeSalePriceFormLookupsProvider = FutureProvider.autoDispose<StoreSalePriceFormLookups>((ref) async {
  final repo = ref.watch(storeSalePricesRepositoryProvider);
  final products = await repo.loadProductLookups(
    take: StorePriceListConstants.formProductCatalogTake,
    defaultsOnly: false,
  );
  final units = await repo.loadDonViTinhLookups();
  return StoreSalePriceFormLookups(products: products, units: units);
});

class StoreSalePriceFormLookups {
  const StoreSalePriceFormLookups({
    required this.products,
    required this.units,
  });

  final List<StoreFuelProductLookup> products;
  final List<StoreDonViTinhLookup> units;

  /// `DropdownButtonFormField` requires each [DropdownMenuItem.value] to appear **once**;
  /// `GET .../don-vi-tinh` can return duplicate `id` rows.
  List<StoreDonViTinhLookup> get uniqueUnitsById {
    final seen = <int>{};
    return units.where((u) => seen.add(u.id)).toList();
  }
}
