import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session.dart';
import 'portal_loai.dart';

/// Storage key names — single source for secure + in-memory implementations.
abstract final class LocalSessionStorageKeys {
  static const accessToken = 'auth_access_token';
  static const username = 'auth_username';
  static const donViId = 'auth_don_vi_id';
  static const loai = 'auth_loai';
  static const expiresIn = 'auth_expires_in';
  static const displayName = 'auth_display_name';
  static const email = 'auth_email';
  static const portalRole = 'auth_portal_role';
  static const fullSystemScope = 'auth_full_system_scope';

  /// Every persisted session field — extend when adding keys; [clearSession] deletes all of these.
  static const List<String> allKeys = [
    accessToken,
    username,
    donViId,
    loai,
    expiresIn,
    displayName,
    email,
    portalRole,
    fullSystemScope,
  ];
}

/// Centralized local persistence for portal auth (secure storage on device).
///
/// All read/write for `access_token`, `username`, `DonViId`, `Loai`, and optional
/// `expires_in` / `displayName` must go through this type — do not call
/// [FlutterSecureStorage] elsewhere for session fields.
abstract interface class LocalPersistentSessionStore {
  /// Persists session fields after successful login. Token is stored via secure storage.
  Future<void> saveSession({
    required String accessToken,
    required String username,
    required int? donViId,
    required int? loai,
    int? expiresIn,
    String? displayName,
    String? email,
    String? portalRole,
    bool fullSystemScope = false,
  });

  Future<String?> getAccessToken();

  Future<String?> getUsername();

  Future<int?> getDonViId();

  Future<int?> getLoai();

  Future<String?> getDisplayName();

  Future<int?> getExpiresIn();

  Future<String?> getEmail();

  Future<String?> getPortalRole();

  Future<bool> getFullSystemScope();

  /// Removes all session keys (logout).
  Future<void> clearSession();

  /// Builds [AuthSession] from storage; returns `null` if missing/invalid; clears storage if `Loai` is not allowed.
  Future<AuthSession?> readValidatedSession();
}

/// Production store: [FlutterSecureStorage] for all keys (plugin is secure on iOS/Android).
final class SecureLocalPersistentSessionStore implements LocalPersistentSessionStore {
  SecureLocalPersistentSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveSession({
    required String accessToken,
    required String username,
    required int? donViId,
    required int? loai,
    int? expiresIn,
    String? displayName,
    String? email,
    String? portalRole,
    bool fullSystemScope = false,
  }) async {
    await Future.wait<void>([
      _storage.write(key: LocalSessionStorageKeys.accessToken, value: accessToken),
      _storage.write(key: LocalSessionStorageKeys.username, value: username),
      _storage.write(
        key: LocalSessionStorageKeys.donViId,
        value: donViId?.toString() ?? '',
      ),
      _storage.write(
        key: LocalSessionStorageKeys.loai,
        value: loai?.toString() ?? '',
      ),
      _storage.write(
        key: LocalSessionStorageKeys.expiresIn,
        value: expiresIn?.toString() ?? '',
      ),
      _storage.write(
        key: LocalSessionStorageKeys.displayName,
        value: displayName ?? '',
      ),
      _storage.write(key: LocalSessionStorageKeys.email, value: email ?? ''),
      _storage.write(key: LocalSessionStorageKeys.portalRole, value: portalRole ?? ''),
      _storage.write(
        key: LocalSessionStorageKeys.fullSystemScope,
        value: fullSystemScope ? '1' : '0',
      ),
    ]);
  }

  @override
  Future<String?> getAccessToken() async {
    final v = (await _storage.read(key: LocalSessionStorageKeys.accessToken))?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  @override
  Future<String?> getUsername() async {
    final v = (await _storage.read(key: LocalSessionStorageKeys.username))?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  @override
  Future<int?> getDonViId() async {
    final raw = await _storage.read(key: LocalSessionStorageKeys.donViId);
    if (raw == null || raw.trim().isEmpty) return null;
    return int.tryParse(raw.trim());
  }

  @override
  Future<int?> getLoai() async {
    final raw = await _storage.read(key: LocalSessionStorageKeys.loai);
    if (raw == null || raw.trim().isEmpty) return null;
    return int.tryParse(raw.trim());
  }

  @override
  Future<String?> getDisplayName() async {
    final v = (await _storage.read(key: LocalSessionStorageKeys.displayName))?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  @override
  Future<int?> getExpiresIn() async {
    final raw = await _storage.read(key: LocalSessionStorageKeys.expiresIn);
    if (raw == null || raw.trim().isEmpty) return null;
    return int.tryParse(raw.trim());
  }

  @override
  Future<String?> getEmail() async {
    final v = (await _storage.read(key: LocalSessionStorageKeys.email))?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  @override
  Future<String?> getPortalRole() async {
    final v = (await _storage.read(key: LocalSessionStorageKeys.portalRole))?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  @override
  Future<bool> getFullSystemScope() async {
    final raw = await _storage.read(key: LocalSessionStorageKeys.fullSystemScope);
    return _parseStorageBool(raw);
  }

  @override
  Future<void> clearSession() async {
    await Future.wait<void>(
      LocalSessionStorageKeys.allKeys.map((k) => _storage.delete(key: k)),
    );
  }

  @override
  Future<AuthSession?> readValidatedSession() async {
    final r = await Future.wait<String?>([
      _storage.read(key: LocalSessionStorageKeys.accessToken),
      _storage.read(key: LocalSessionStorageKeys.username),
      _storage.read(key: LocalSessionStorageKeys.donViId),
      _storage.read(key: LocalSessionStorageKeys.loai),
      _storage.read(key: LocalSessionStorageKeys.displayName),
      _storage.read(key: LocalSessionStorageKeys.expiresIn),
      _storage.read(key: LocalSessionStorageKeys.email),
      _storage.read(key: LocalSessionStorageKeys.portalRole),
      _storage.read(key: LocalSessionStorageKeys.fullSystemScope),
    ]);
    final token = r[0]?.trim();
    final user = r[1]?.trim();
    if (token == null || token.isEmpty || user == null || user.isEmpty) {
      return null;
    }
    final donViId = _parseOptionalInt(r[2]);
    final loai = _parseOptionalInt(r[3]);
    final role = mapLoaiToPortalRole(loai);
    if (role == null) {
      await clearSession();
      return null;
    }
    final dn = r[4]?.trim();
    final em = r[6]?.trim();
    final pr = r[7]?.trim();
    return AuthSession(
      accessToken: token,
      userName: user,
      donViId: donViId,
      loai: loai,
      role: role,
      displayName: dn == null || dn.isEmpty ? null : dn,
      expiresIn: _parseOptionalInt(r[5]),
      email: em == null || em.isEmpty ? null : em,
      portalRole: pr == null || pr.isEmpty ? null : pr,
      fullSystemScope: _parseStorageBool(r[8]),
    );
  }
}

int? _parseOptionalInt(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return int.tryParse(raw.trim());
}

bool _parseStorageBool(String? raw) {
  if (raw == null || raw.trim().isEmpty) return false;
  final t = raw.trim().toLowerCase();
  return t == '1' || t == 'true' || t == 'yes';
}

/// In-memory store for widget tests (same contract as [SecureLocalPersistentSessionStore]).
final class InMemoryLocalPersistentSessionStore implements LocalPersistentSessionStore {
  final Map<String, String> _values = {};

  @override
  Future<void> saveSession({
    required String accessToken,
    required String username,
    required int? donViId,
    required int? loai,
    int? expiresIn,
    String? displayName,
    String? email,
    String? portalRole,
    bool fullSystemScope = false,
  }) async {
    _values[LocalSessionStorageKeys.accessToken] = accessToken;
    _values[LocalSessionStorageKeys.username] = username;
    _values[LocalSessionStorageKeys.donViId] = donViId?.toString() ?? '';
    _values[LocalSessionStorageKeys.loai] = loai?.toString() ?? '';
    _values[LocalSessionStorageKeys.expiresIn] = expiresIn?.toString() ?? '';
    _values[LocalSessionStorageKeys.displayName] = displayName ?? '';
    _values[LocalSessionStorageKeys.email] = email ?? '';
    _values[LocalSessionStorageKeys.portalRole] = portalRole ?? '';
    _values[LocalSessionStorageKeys.fullSystemScope] = fullSystemScope ? '1' : '0';
  }

  @override
  Future<String?> getAccessToken() async {
    final v = _values[LocalSessionStorageKeys.accessToken]?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  @override
  Future<String?> getUsername() async {
    final v = _values[LocalSessionStorageKeys.username]?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  @override
  Future<int?> getDonViId() async {
    final raw = _values[LocalSessionStorageKeys.donViId];
    if (raw == null || raw.trim().isEmpty) return null;
    return int.tryParse(raw.trim());
  }

  @override
  Future<int?> getLoai() async {
    final raw = _values[LocalSessionStorageKeys.loai];
    if (raw == null || raw.trim().isEmpty) return null;
    return int.tryParse(raw.trim());
  }

  @override
  Future<String?> getDisplayName() async {
    final v = _values[LocalSessionStorageKeys.displayName]?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  @override
  Future<int?> getExpiresIn() async {
    final raw = _values[LocalSessionStorageKeys.expiresIn];
    if (raw == null || raw.trim().isEmpty) return null;
    return int.tryParse(raw.trim());
  }

  @override
  Future<String?> getEmail() async {
    final v = _values[LocalSessionStorageKeys.email]?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  @override
  Future<String?> getPortalRole() async {
    final v = _values[LocalSessionStorageKeys.portalRole]?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  @override
  Future<bool> getFullSystemScope() async {
    return _parseStorageBool(_values[LocalSessionStorageKeys.fullSystemScope]);
  }

  @override
  Future<void> clearSession() async {
    for (final k in LocalSessionStorageKeys.allKeys) {
      _values.remove(k);
    }
  }

  @override
  Future<AuthSession?> readValidatedSession() async {
    final token = _values[LocalSessionStorageKeys.accessToken]?.trim();
    final user = _values[LocalSessionStorageKeys.username]?.trim();
    if (token == null || token.isEmpty || user == null || user.isEmpty) {
      return null;
    }
    final donViId = _parseOptionalInt(_values[LocalSessionStorageKeys.donViId]);
    final loai = _parseOptionalInt(_values[LocalSessionStorageKeys.loai]);
    final role = mapLoaiToPortalRole(loai);
    if (role == null) {
      await clearSession();
      return null;
    }
    final dn = _values[LocalSessionStorageKeys.displayName]?.trim();
    final em = _values[LocalSessionStorageKeys.email]?.trim();
    final pr = _values[LocalSessionStorageKeys.portalRole]?.trim();
    return AuthSession(
      accessToken: token,
      userName: user,
      donViId: donViId,
      loai: loai,
      role: role,
      displayName: dn == null || dn.isEmpty ? null : dn,
      expiresIn: _parseOptionalInt(_values[LocalSessionStorageKeys.expiresIn]),
      email: em == null || em.isEmpty ? null : em,
      portalRole: pr == null || pr.isEmpty ? null : pr,
      fullSystemScope: _parseStorageBool(_values[LocalSessionStorageKeys.fullSystemScope]),
    );
  }
}
