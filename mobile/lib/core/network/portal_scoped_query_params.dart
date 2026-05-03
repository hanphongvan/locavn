import '../auth/portal_session_scope.dart';

/// Central helpers for optional organization/store filters on list and report APIs.
abstract final class PortalScopedQueryParams {
  /// Merges `donViId` when [scope] carries a positive id (typical store/trader admin lists).
  ///
  /// Backend list endpoints often accept `[FromQuery] int? donViId` to narrow scope when
  /// the account can access multiple retail stores.
  static Map<String, dynamic> mergeOptionalDonViId(
    Map<String, dynamic> query,
    PortalSessionScope? scope,
  ) {
    final id = scope?.donViId;
    if (id != null && id > 0) {
      return <String, dynamic>{...query, 'donViId': id};
    }
    return query;
  }
}
