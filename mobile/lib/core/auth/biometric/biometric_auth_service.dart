import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Bọc [LocalAuthentication] — kiểm tra thiết bị, nhãn UI, xác thực.
///
/// Không hard-code tên nền tảng: dùng [BiometricType] có sẵn.
class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? localAuth}) : _local = localAuth ?? LocalAuthentication();

  final LocalAuthentication _local;

  Future<bool> isDeviceSupported() => _local.isDeviceSupported();

  Future<bool> canAuthenticateWithBiometrics() async {
    if (!await _local.isDeviceSupported()) return false;
    final list = await _local.getAvailableBiometrics();
    return list.isNotEmpty;
  }

  /// Nhãn cho nút đăng nhập (tiếng Việt, theo loại sinh trắc có trên máy).
  Future<String> loginButtonLabel() async {
    if (!await isDeviceSupported()) return 'Đăng nhập bằng vân tay / Face ID';
    final types = await _local.getAvailableBiometrics();
    if (types.isEmpty) return 'Đăng nhập bằng vân tay / Face ID';
    final hasFace = types.contains(BiometricType.face);
    final hasFinger = types.contains(BiometricType.fingerprint) ||
        types.contains(BiometricType.strong) ||
        types.contains(BiometricType.weak);
    if (hasFace && hasFinger) return 'Đăng nhập bằng vân tay / Face ID';
    if (hasFace) return 'Đăng nhập bằng Face ID';
    if (hasFinger) return 'Đăng nhập bằng vân tay';
    return 'Đăng nhập bằng sinh trắc học';
  }

  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _local.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: false,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Thông báo ngắn khi [authenticate] trả `false` hoặc ngoại lệ.
  String userMessageForFailure() {
    return 'Không xác thực được sinh trắc học. Bạn vẫn có thể đăng nhập bằng mật khẩu.';
  }
}
