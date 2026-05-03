import 'auth_session_controller.dart';

/// Central cold-start flow: **read local session** (access_token, username, DonViId, Loai)
/// from [LocalPersistentSessionStore] via [AuthSessionController.restoreFromLocalStorage],
/// then [GoRouter] redirect routes by stored Loai (`role_home_navigation.dart`).
///
/// Do not start duplicate restore jobs — call [scheduleInitialSessionRestore] exactly once
/// when creating [authSessionControllerProvider].
abstract final class AppSessionBootstrap {
  AppSessionBootstrap._();

  /// Queues restore on the next microtask so [ProviderScope] is mounted and splash can paint
  /// while secure storage reads complete.
  static void scheduleInitialSessionRestore(AuthSessionController auth) {
    Future.microtask(() async {
      await auth.restoreFromLocalStorage();
    });
  }
}
