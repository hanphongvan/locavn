import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_auth_service.dart';
import 'biometric_credential_store.dart';

final biometricCredentialStoreProvider = Provider<BiometricCredentialStore>((ref) {
  return BiometricCredentialStore();
});

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

/// Trạng thái nút đăng nhập sinh trắc học ở màn login.
enum BiometricLoginUiKind {
  /// Đã bật + thiết bị có sinh trắc — nút bấm được.
  ready,

  /// Đã bật nhưng máy không còn sinh trắc khả dụng — nút tắt + snackbar giải thích.
  enrolledButUnavailable,

  /// Chưa bật — ẩn nút (chỉ đăng nhập mật khẩu).
  hidden,
}

class BiometricLoginUiState {
  const BiometricLoginUiState({
    required this.kind,
    required this.buttonLabel,
    this.unavailableHint,
  });

  final BiometricLoginUiKind kind;
  final String buttonLabel;
  final String? unavailableHint;

  /// Chỉ hiện "HOẶC" + nút khi máy thực sự dùng được sinh trắc (đã bật trong app).
  bool get showButton => kind == BiometricLoginUiKind.ready;
}

final biometricLoginUiProvider = FutureProvider.autoDispose<BiometricLoginUiState>((ref) async {
  final store = ref.watch(biometricCredentialStoreProvider);
  final auth = ref.watch(biometricAuthServiceProvider);
  final label = await auth.loginButtonLabel();

  if (!await store.isEnrollmentActive()) {
    return BiometricLoginUiState(
      kind: BiometricLoginUiKind.hidden,
      buttonLabel: label,
    );
  }

  if (!await auth.canAuthenticateWithBiometrics()) {
    return BiometricLoginUiState(
      kind: BiometricLoginUiKind.enrolledButUnavailable,
      buttonLabel: label,
      unavailableHint:
          'Thiết bị không sẵn sàng cho sinh trắc học (chưa thiết lập hoặc đã tắt). Vui lòng dùng mật khẩu.',
    );
  }

  return BiometricLoginUiState(
    kind: BiometricLoginUiKind.ready,
    buttonLabel: label,
  );
});

final biometricEnrollmentActiveProvider = FutureProvider.autoDispose<bool>((ref) async {
  final store = ref.watch(biometricCredentialStoreProvider);
  return store.isEnrollmentActive();
});
