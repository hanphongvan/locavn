/// Aligns with Angular `store-price.constants.ts` + hub `STORE_PRICE_LIST_MAX_TAKE`.
abstract final class StorePriceListConstants {
  static const int hubFuelProductsTake = 200;
  static const int hubStoresTake = 200;

  /// Angular form `listProducts({ take: 500, defaultsOnly: false })`.
  static const int formProductCatalogTake = 500;
}
