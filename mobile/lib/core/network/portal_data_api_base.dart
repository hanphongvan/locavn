import 'package:dio/dio.dart';

import '../auth/portal_session_scope.dart';
import 'portal_scoped_query_params.dart';

/// Shared Dio + portal scope for data APIs that may send optional `donViId` (store/trader lists).
class PortalDataApiBase {
  PortalDataApiBase(this.dio, this.readPortalScope);

  final Dio dio;
  final PortalScopeReader readPortalScope;

  PortalSessionScope? get portalScope => readPortalScope();

  Map<String, dynamic> queryWithOptionalDonViId(Map<String, dynamic> base) =>
      PortalScopedQueryParams.mergeOptionalDonViId(base, portalScope);
}
