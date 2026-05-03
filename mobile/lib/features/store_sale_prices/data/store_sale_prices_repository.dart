import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/portal_session_scope.dart';
import 'models/store_don_vi_tinh_lookup.dart';
import 'models/store_fuel_product_lookup.dart';
import 'models/store_sale_price_batch_models.dart';
import 'models/store_sale_price_detail.dart';
import 'models/store_sale_price_list_item.dart';
import 'models/store_sale_price_latest_submission_row.dart';
import 'models/store_sale_price_upsert_request.dart';
import 'store_sale_prices_api.dart';
import 'store_sale_prices_exceptions.dart';
import 'store_sale_prices_role_guard.dart';

final storeSalePricesRepositoryProvider = Provider<StoreSalePricesRepository>((ref) {
  return StoreSalePricesRepository(
    api: ref.watch(storeSalePricesApiProvider),
    readScope: () => ref.read(portalSessionScopeProvider),
  );
});

/// Store-scoped sale price data access (same backend rules as Angular + `StoreAdminRetailStoreAccess`).
///
/// All mutating methods require **body `donViId` == session `donViId`** for the store account
/// (matches Angular `applyLoggedInDonViToBatchForm` / pinned store filter).
class StoreSalePricesRepository {
  StoreSalePricesRepository({
    required StoreSalePricesApi api,
    required PortalScopeReader readScope,
  })  : _api = api,
        _readScope = readScope;

  final StoreSalePricesApi _api;
  final PortalScopeReader _readScope;

  /// Backend allows `PUT` when `CanAccessRetailStoreDonViAsync` passes for the row's `donViId`.
  /// For **Store**, that is exactly **one** permitted `donViId` — must match the loaded detail.
  static bool canEditSalePriceDetail({
    required StoreSalePriceDetail detail,
    required PortalSessionScope scope,
  }) {
    if (!StoreSalePricesRoleGuard.isStoreLoai(scope.loai)) return false;
    final id = scope.donViId;
    if (id == null || id <= 0) return false;
    return detail.donViId == id;
  }

  /// Whether a hub list row may open the single-line edit sheet (same `DonViId` rule as [canEditSalePriceDetail]).
  static bool canEditSalePriceListItem({
    required StoreSalePriceListItem item,
    required PortalSessionScope scope,
  }) {
    if (!StoreSalePricesRoleGuard.isStoreLoai(scope.loai)) return false;
    final id = scope.donViId;
    if (id == null || id <= 0) return false;
    return item.donViId == id;
  }

  PortalSessionScope _requireStoreSalePriceScope() {
    final scope = _readScope();
    if (scope == null) {
      throw StoreSalePricesSessionException(
        'Chưa đăng nhập hoặc phiên không hợp lệ. Không thể tải giá bán.',
      );
    }
    if (!StoreSalePricesRoleGuard.canUseStoreSalePricesDataLayer(scope)) {
      throw StoreSalePricesAccessException(
        'Chỉ tài khoản cửa hàng (Loai = 4) có DonViId mới được dùng tính năng nhập giá bán.',
      );
    }
    return scope;
  }

  int _requireDonViId(PortalSessionScope scope) {
    final id = scope.donViId;
    if (id == null || id <= 0) {
      throw StoreSalePricesSessionException(
        'Tài khoản chưa gắn DonViId (cửa hàng). Không thể thao tác giá bán.',
      );
    }
    return id;
  }

  void _assertBodyDonViMatchesSession(int bodyDonViId, int sessionDonViId) {
    if (bodyDonViId != sessionDonViId) {
      throw StoreSalePricesAccessException(
        'DonViId trong yêu cầu không khớp cửa hàng của phiên đăng nhập.',
      );
    }
  }

  /// Angular hub: `GET .../current/by-store/{donViId}`.
  Future<List<StoreSalePriceListItem>> loadCurrentPricesForSessionStore() async {
    final scope = _requireStoreSalePriceScope();
    final donViId = _requireDonViId(scope);
    return _api.getCurrentByStore(donViId);
  }

  /// Angular hub: `GET .../by-store/{donViId}` with optional `productId` (history / filter).
  Future<List<StoreSalePriceListItem>> loadHistoryForSessionStore({int? productId}) async {
    final scope = _requireStoreSalePriceScope();
    final donViId = _requireDonViId(scope);
    return _api.getByStore(donViId, productId: productId);
  }

  /// Form catalog: `GET .../products` (same query shape as Angular `StorePricesApiService.listProducts`).
  Future<List<StoreFuelProductLookup>> loadProductLookups({
    String? search,
    int take = 200,
    bool defaultsOnly = false,
  }) async {
    _requireStoreSalePriceScope();
    if (take < 1 || take > 500) {
      throw StoreSalePricesAccessException('take must be between 1 and 500 (API clamp).');
    }
    return _api.getProducts(search: search, take: take, defaultsOnly: defaultsOnly);
  }

  /// Form units: `GET .../don-vi-tinh`.
  Future<List<StoreDonViTinhLookup>> loadDonViTinhLookups() async {
    _requireStoreSalePriceScope();
    return _api.getDonViTinh();
  }

  /// Angular **"Sao chép lần gần nhất"**: `GET .../latest-submission?donViId=`.
  Future<List<StoreSalePriceLatestSubmissionRow>> loadLatestSubmissionForSessionStore() async {
    final scope = _requireStoreSalePriceScope();
    final donViId = _requireDonViId(scope);
    return _api.getLatestSubmission(donViId);
  }

  /// Primary bulk create from the Angular **batch** form: `POST .../batch`.
  ///
  /// Server: 1–50 rows, unique products (`StoreAdminStorePriceService.ValidateBatch`).
  Future<StoreSalePriceBatchCreateResponse> createBatch(StoreSalePriceBatchCreateRequest body) async {
    final scope = _requireStoreSalePriceScope();
    final donViId = _requireDonViId(scope);
    _assertBodyDonViMatchesSession(body.donViId, donViId);
    if (body.rows.isEmpty || body.rows.length > 50) {
      throw StoreSalePricesAccessException(
        'Batch phải có từ 1 đến 50 dòng mặt hàng (giới hạn backend).',
      );
    }
    final pids = body.rows.map((r) => r.productId).toSet();
    if (pids.length != body.rows.length) {
      throw StoreSalePricesAccessException('Không được trùng productId trong cùng một batch.');
    }
    return _api.postBatch(body);
  }

  /// Angular single-line `POST /api/admin/store-prices` (used from `submitEdit` when creating).
  Future<StoreSalePriceDetail> createSingle(StoreSalePriceUpsertRequest body) async {
    final scope = _requireStoreSalePriceScope();
    final donViId = _requireDonViId(scope);
    _assertBodyDonViMatchesSession(body.donViId, donViId);
    return _api.postCreate(body);
  }

  /// `PUT /api/admin/store-prices/{id}` — allowed only when [canEditSalePriceDetail] is true.
  Future<StoreSalePriceDetail> updateSingle(int id, StoreSalePriceUpsertRequest body) async {
    final scope = _requireStoreSalePriceScope();
    final donViId = _requireDonViId(scope);
    _assertBodyDonViMatchesSession(body.donViId, donViId);
    final existing = await _api.getById(id);
    if (!canEditSalePriceDetail(detail: existing, scope: scope)) {
      throw StoreSalePricesAccessException(
        'Không được phép sửa bản ghi giá này cho cửa hàng hiện tại.',
      );
    }
    return _api.putUpdate(id, body);
  }

  /// Loads one row for edit flows (Angular route `/:id/edit` — UI not implemented yet).
  Future<StoreSalePriceDetail> loadDetailForSessionStore(int id) async {
    final scope = _requireStoreSalePriceScope();
    _requireDonViId(scope);
    final detail = await _api.getById(id);
    if (!canEditSalePriceDetail(detail: detail, scope: scope)) {
      throw StoreSalePricesAccessException(
        'Bản ghi giá không thuộc cửa hàng của phiên đăng nhập hoặc không tồn tại.',
      );
    }
    return detail;
  }
}
