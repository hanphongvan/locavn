import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_session_controller.dart';
import '../admin_auth_repository.dart';
import 'biometric_providers.dart';

/// Luỗi offer sau đăng nhập mật khẩu + đăng nhập bằng sinh trắc học từ màn login.
abstract final class BiometricLoginCoordinator {
  /// Gọi sau [AuthSessionController.login] thành công, **trước** `context.go(home)`.
  static Future<void> onPasswordLoginSuccess({
    required WidgetRef ref,
    required BuildContext context,
    required String username,
    required String password,
  }) async {
    final store = ref.read(biometricCredentialStoreProvider);
    final auth = ref.read(biometricAuthServiceProvider);

    await store.clearEnrollmentIfDifferentUser(username);
    await store.refreshStoredPasswordIfSameUser(username, password);

    if (await store.isEnrollmentActive()) {
      ref.invalidate(biometricLoginUiProvider);
      ref.invalidate(biometricEnrollmentActiveProvider);
      return;
    }

    if (!await auth.canAuthenticateWithBiometrics()) return;
    if (!context.mounted) return;

    final agree = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Bật đăng nhập nhanh?'),
        content: const Text(
          'Bạn có muốn dùng vân tay hoặc Face ID cho lần đăng nhập sau không?\n\n'
          'Thông tin đăng nhập được lưu trong bộ nhớ được mã hóa của thiết bị (Keychain / Keystore), '
          'không lưu dạng văn bản thường trên máy.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
        ],
      ),
    );
    if (agree != true || !context.mounted) return;

    final bioOk = await auth.authenticate(
      localizedReason: 'Xác nhận để lưu đăng nhập sinh trắc học cho LocaVN',
    );
    if (!bioOk) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.userMessageForFailure())),
        );
      }
      return;
    }

    await store.saveEnrollment(username.trim(), password);
    ref.invalidate(biometricLoginUiProvider);
    ref.invalidate(biometricEnrollmentActiveProvider);
  }

  /// `true` khi đã gọi [AuthSessionController.login] thành công; `false` khi huỷ / thất bại sinh trắc.
  /// Lỗi API đăng nhập: **rethrow** để caller hiển thị [dioErrorUserMessage].
  static Future<bool> loginWithBiometric({
    required WidgetRef ref,
    required BuildContext context,
    required AuthSessionController sessionController,
  }) async {
    final store = ref.read(biometricCredentialStoreProvider);
    final auth = ref.read(biometricAuthServiceProvider);

    final cred = await store.readCredentials();
    if (cred == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa bật đăng nhập sinh trắc học trên thiết bị này.')),
        );
      }
      return false;
    }

    final bioOk = await auth.authenticate(
      localizedReason: 'Xác thực để đăng nhập LocaVN',
    );
    if (!bioOk) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.userMessageForFailure())),
        );
      }
      return false;
    }

    await sessionController.login(cred.username, cred.password);
    ref.invalidate(biometricLoginUiProvider);
    ref.invalidate(biometricEnrollmentActiveProvider);
    return true;
  }

  static String? loginErrorMessage(Object error) => dioErrorUserMessage(error);
}
