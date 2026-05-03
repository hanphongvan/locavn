import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/portal_session_scope.dart';
import '../../store_sale_prices/data/store_sale_prices_role_guard.dart';
import 'models/inventory_current_line.dart';
import 'models/inventory_transaction_bundle.dart';
import 'models/inventory_transaction_header_list_item.dart';
import 'store_inventory_api.dart';

final storeInventoryRepositoryProvider = Provider<StoreInventoryRepository>((ref) {
  return StoreInventoryRepository(
    api: ref.watch(storeInventoryApiProvider),
    readScope: () => ref.read(portalSessionScopeProvider),
  );
});

/// Aggregated header row for list UI (includes line monetary total from detail fetch).
class InventoryTransactionHeaderVm {
  const InventoryTransactionHeaderVm({
    required this.header,
    required this.totalAmount,
  });

  final InventoryTransactionHeaderListItem header;
  final double totalAmount;
}

class StoreInventoryRepository {
  StoreInventoryRepository({
    required StoreInventoryApi api,
    required PortalScopeReader readScope,
  })  : _api = api,
        _readScope = readScope;

  final StoreInventoryApi _api;
  final PortalScopeReader _readScope;

  static bool isStoreInventoryAllowed(PortalSessionScope? scope) =>
      StoreSalePricesRoleGuard.canUseStoreSalePricesDataLayer(scope);

  PortalSessionScope _requireScope() {
    final scope = _readScope();
    if (scope == null) {
      throw StateError('Chưa đăng nhập.');
    }
    if (!isStoreInventoryAllowed(scope)) {
      throw StateError('Chỉ tài khoản cửa hàng (Loai = 4) có DonViId mới dùng được tồn kho.');
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

  Future<List<InventoryCurrentLine>> listCurrentStock() async {
    final scope = _requireScope();
    return _api.listCurrentByStore(_requireDonViId(scope));
  }

  /// Loads headers then enriches each with total `Amount` from `GET …/{id}` (bounded concurrency).
  Future<List<InventoryTransactionHeaderVm>> listTransactionsWithTotals({
    int concurrency = 8,
  }) async {
    final scope = _requireScope();
    final donViId = _requireDonViId(scope);
    final headers = await _api.listTransactionsByStore(donViId);
    if (headers.isEmpty) return const [];

    Future<double> totalFor(int id) async {
      try {
        final bundle = await _api.getTransactionBundle(id);
        return bundle.totalAmount;
      } catch (_) {
        return 0;
      }
    }

    final totals = <int, double>{};
    for (var i = 0; i < headers.length; i += concurrency) {
      final slice = headers.skip(i).take(concurrency).toList();
      final amounts = await Future.wait(slice.map((h) => totalFor(h.id)));
      for (var j = 0; j < slice.length; j++) {
        totals[slice[j].id] = amounts[j];
      }
    }

    return headers
        .map((h) => InventoryTransactionHeaderVm(header: h, totalAmount: totals[h.id] ?? 0))
        .toList();
  }

  Future<InventoryTransactionBundle> createVoucher(Map<String, dynamic> body) =>
      _api.createTransaction(body);
}
