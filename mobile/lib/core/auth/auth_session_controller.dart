import 'package:flutter/foundation.dart';

import 'auth_session.dart';
import 'auth_service.dart';

/// Holds in-memory auth after [restoreFromLocalStorage] (cold start) or [login].
/// Drives [GoRouter] via [notifyListeners].
class AuthSessionController extends ChangeNotifier {
  AuthSessionController(this._authService);

  final AuthService _authService;

  bool _ready = false;
  AuthSession? _session;

  /// `false` until the first [restoreFromLocalStorage] finishes (splash stays up).
  bool get isReady => _ready;

  bool get isAuthenticated => _session != null;

  AuthSession? get session => _session;

  String? get accessToken => _session?.accessToken;

  /// App startup: load `access_token`, `username`, `DonViId`, `Loai` (+ profile extras) from
  /// secure storage; invalid or unknown `Loai` yields `null` session (user sent to login).
  Future<void> restoreFromLocalStorage() async {
    try {
      _session = await _authService.loadPersistedSession();
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    final result = await _authService.login(username, password);
    _session = result.session;
    notifyListeners();
  }

  /// Clears secure storage via [AuthService.logout], drops in-memory [AuthSession], then
  /// [notifyListeners] so [GoRouter] (`refreshListenable`) runs [redirect] → `/login`.
  ///
  /// Do **not** call [GoRouter.go] here: redirect already navigates away; a second [go]
  /// during the same frame can hit `Navigator` `!_debugLocked` while the old shell disposes.
  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      _session = null;
      notifyListeners();
    }
  }
}
