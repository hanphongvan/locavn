import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/change_password_api.dart';
import '../data/change_password_providers.dart';

class ChangePasswordController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ChangePasswordResultDto> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final api = ref.read(changePasswordApiProvider);
    state = const AsyncLoading();
    try {
      final res = await api.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      state = const AsyncData(null);
      return res;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final changePasswordControllerProvider =
    AutoDisposeAsyncNotifierProvider<ChangePasswordController, void>(
  ChangePasswordController.new,
);
