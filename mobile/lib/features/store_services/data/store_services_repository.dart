import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/portal_session_scope.dart';
import '../../store_sale_prices/data/store_sale_prices_role_guard.dart';
import 'models/store_service_catalog_item.dart';
import 'models/store_service_create_request.dart';
import 'models/store_service_row.dart';
import 'store_services_api.dart';

final storeServicesRepositoryProvider = Provider<StoreServicesRepository>((ref) {
  return StoreServicesRepository(
    api: ref.watch(storeServicesApiProvider),
    readScope: () => ref.read(portalSessionScopeProvider),
  );
});

class StoreServicesRepository {
  StoreServicesRepository({
    required StoreServicesApi api,
    required PortalScopeReader readScope,
  })  : _api = api,
        _readScope = readScope;

  final StoreServicesApi _api;
  final PortalScopeReader _readScope;

  PortalSessionScope _requireScope() {
    final scope = _readScope();
    if (scope == null) {
      throw StateError('Chưa đăng nhập.');
    }
    if (!StoreSalePricesRoleGuard.canUseStoreSalePricesDataLayer(scope)) {
      throw StateError('Chỉ tài khoản cửa hàng có DonViId mới dùng được quản lý dịch vụ.');
    }
    return scope;
  }

  int _requireDonViId(PortalSessionScope scope) {
    final id = scope.donViId;
    if (id == null || id <= 0) {
      throw StateError('Thiếu DonViId.');
    }
    return id;
  }

  Future<List<StoreServiceRow>> listForSessionStore() async {
    final scope = _requireScope();
    return _api.listByStore(_requireDonViId(scope));
  }

  Future<List<StoreServiceCatalogItem>> catalog() => _api.getCatalog();

  Future<StoreServiceRow> addService(String serviceCode) async {
    final scope = _requireScope();
    final donViId = _requireDonViId(scope);
    final existing = await _api.listByStore(donViId);
    final maxOrder = existing.isEmpty
        ? 0
        : existing.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b);
    return _api.create(
      StoreServiceCreateRequest(
        donViId: donViId,
        serviceCode: serviceCode,
        sortOrder: maxOrder + 1,
      ),
    );
  }

  Future<StoreServiceRow> updateRow(StoreServiceRow row) =>
      _api.update(row.id, row.toUpdateJson());

  Future<void> remove(int id) => _api.delete(id);
}
