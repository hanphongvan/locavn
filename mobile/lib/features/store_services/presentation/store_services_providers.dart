import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/store_service_catalog_item.dart';
import '../data/models/store_service_row.dart';
import '../data/store_services_repository.dart';

final storeServicesListProvider = FutureProvider.autoDispose<List<StoreServiceRow>>((ref) {
  return ref.watch(storeServicesRepositoryProvider).listForSessionStore();
});

final storeServicesCatalogProvider = FutureProvider.autoDispose<List<StoreServiceCatalogItem>>((ref) {
  return ref.watch(storeServicesRepositoryProvider).catalog();
});
