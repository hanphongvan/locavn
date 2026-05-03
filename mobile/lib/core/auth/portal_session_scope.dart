/// Snapshot of portal session fields used for **data scoping** (API query/body, RBAC).
///
/// Derived from [AuthSession] via [portalSessionScopeProvider] — do not read secure
/// storage or duplicate session parsing inside widgets or REST wrappers.
class PortalSessionScope {
  const PortalSessionScope({
    required this.userName,
    required this.donViId,
    required this.loai,
    required this.fullSystemScope,
    this.portalRole,
  });

  final String userName;
  final int? donViId;
  final int? loai;
  final bool fullSystemScope;
  final String? portalRole;
}

/// Request-time read of the current portal data scope (from in-memory auth).
typedef PortalScopeReader = PortalSessionScope? Function();
