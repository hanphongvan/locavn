import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'biometric_payload_codec.dart';
import 'biometric_storage_keys.dart';

/// Lưu cờ bật + payload đăng nhập trong [FlutterSecureStorage] (mã hóa theo nền tảng).
///
/// **Không** ghi mật khẩu ra SharedPreferences thường. Logout **không** xoá — chỉ [clearEnrollment].
class BiometricCredentialStore {
  BiometricCredentialStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<bool> isEnrollmentActive() async {
    final v = (await _storage.read(key: BiometricStorageKeys.enabled))?.trim();
    return v == '1';
  }

  Future<BiometricCredentials?> readCredentials() async {
    if (!await isEnrollmentActive()) return null;
    final raw = await _storage.read(key: BiometricStorageKeys.payload);
    final cred = BiometricPayloadCodec.decode(raw);
    if (cred == null) {
      await clearEnrollment();
    }
    return cred;
  }

  Future<void> saveEnrollment(String username, String password) async {
    final payload = BiometricPayloadCodec.encode(username, password);
    await Future.wait<void>([
      _storage.write(key: BiometricStorageKeys.enabled, value: '1'),
      _storage.write(key: BiometricStorageKeys.payload, value: payload),
    ]);
  }

  /// Gọi sau đăng nhập mật khẩu thành công nếu đã bật biometric cùng user — cập nhật mật khẩu lưu khóa.
  Future<void> refreshStoredPasswordIfSameUser(String username, String password) async {
    if (!await isEnrollmentActive()) return;
    final cur = await readCredentials();
    if (cur == null) return;
    if (cur.username == username.trim()) {
      await saveEnrollment(username.trim(), password);
    }
  }

  /// User khác đăng nhập — xoá enrollment cũ để tránh đăng nhập nhầm tài khoản.
  Future<void> clearEnrollmentIfDifferentUser(String username) async {
    if (!await isEnrollmentActive()) return;
    final cur = await readCredentials();
    if (cur != null && cur.username != username.trim()) {
      await clearEnrollment();
    }
  }

  Future<void> clearEnrollment() async {
    await Future.wait<void>([
      _storage.delete(key: BiometricStorageKeys.enabled),
      _storage.delete(key: BiometricStorageKeys.payload),
    ]);
  }
}
