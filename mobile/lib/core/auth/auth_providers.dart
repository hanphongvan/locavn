import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_auth_repository.dart';
import 'app_session_bootstrap.dart';
import 'auth_service.dart';
import 'auth_session_controller.dart';
import 'google/google_sign_in_service.dart';
import 'local_persistent_session_store.dart';
import 'portal_session_scope.dart';

final localPersistentSessionStoreProvider = Provider<LocalPersistentSessionStore>((ref) {
  return SecureLocalPersistentSessionStore();
});

final adminAuthDioProvider = Provider<Dio>((ref) => createAdminAuthDio());

final adminAuthRepositoryProvider = Provider<AdminAuthRepository>((ref) {
  return AdminAuthRepository(ref.watch(adminAuthDioProvider));
});

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(adminAuthRepositoryProvider),
    ref.watch(localPersistentSessionStoreProvider),
    ref.watch(googleSignInServiceProvider),
  );
});

final authSessionControllerProvider =
    ChangeNotifierProvider<AuthSessionController>((ref) {
  final c = AuthSessionController(ref.watch(authServiceProvider));
  AppSessionBootstrap.scheduleInitialSessionRestore(c);
  return c;
});

/// Current portal identity for **data requests** (username, DonViId, Loai, …).
///
/// `null` when logged out. Prefer this over re-reading secure storage in services/widgets.
///
/// Dùng `.select((c) => c.session)` để chỉ rebuild khi reference của session thay đổi
/// (login/logout/restore), không phải mọi `notifyListeners` của AuthSessionController.
final portalSessionScopeProvider = Provider<PortalSessionScope?>((ref) {
  final session = ref.watch(
    authSessionControllerProvider.select((c) => c.session),
  );
  if (session == null) return null;
  return PortalSessionScope(
    userName: session.userName,
    donViId: session.donViId,
    loai: session.loai,
    fullSystemScope: session.fullSystemScope,
    portalRole: session.portalRole,
  );
});
