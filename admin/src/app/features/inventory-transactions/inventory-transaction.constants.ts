/** Matches backend `StoreAdminInventoryTransactionValidator.DefaultTake`. */
export const INVENTORY_TX_LIST_DEFAULT_TAKE = 50;

/** Matches backend `StoreAdminInventoryTransactionValidator.MaxTake`. */
export const INVENTORY_TX_LIST_MAX_TAKE = 200;

/** Matches `[MaxLength(500)]` on inventory save request header/line notes. */
export const INVENTORY_TX_NOTE_MAX = 500;

/** Số dòng tối đa khi nạp mặc hàng mặc định (API `store-prices/products` với defaultsOnly, chỉ lá). */
export const INVENTORY_TX_DEFAULT_DETAIL_ROWS = 18;
