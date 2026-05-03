import 'dart:convert';

/// JSON payload trong Keychain / EncryptedSharedPreferences — không ghi file thường.
abstract final class BiometricPayloadCodec {
  static const int currentVersion = 1;

  static String encode(String username, String password) {
    return jsonEncode(<String, dynamic>{
      'v': currentVersion,
      'u': username,
      'p': password,
    });
  }

  /// `null` nếu hỏng hoặc version không hỗ trợ.
  static BiometricCredentials? decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final v = decoded['v'];
      if (v is! int || v != currentVersion) return null;
      final u = decoded['u'];
      final p = decoded['p'];
      if (u is! String || p is! String) return null;
      if (u.trim().isEmpty || p.isEmpty) return null;
      return BiometricCredentials(username: u.trim(), password: p);
    } on Object {
      return null;
    }
  }
}

class BiometricCredentials {
  const BiometricCredentials({required this.username, required this.password});

  final String username;
  final String password;
}
