import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/password_reset_api.dart';
import '../data/password_reset_providers.dart';

class ResetPasswordController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ResetPasswordResult> submit({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final api = ref.read(passwordResetApiProvider);
    state = const AsyncLoading();
    try {
      final res = await api.resetPassword(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      state = const AsyncData(null);
      return res;
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } on DioException catch (e, st) {
      final ex = ApiException.fromDio(e);
      state = AsyncError(ex, st);
      throw ex;
    }
  }
}

final resetPasswordControllerProvider =
    AutoDisposeAsyncNotifierProvider<ResetPasswordController, void>(
  ResetPasswordController.new,
);
