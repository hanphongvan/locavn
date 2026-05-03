import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/password_reset_api.dart';
import '../data/password_reset_providers.dart';

class ForgotPasswordController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ForgotPasswordResult> submit({required String email}) async {
    final api = ref.read(passwordResetApiProvider);
    state = const AsyncLoading();
    try {
      final res = await api.forgotPassword(email: email);
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

final forgotPasswordControllerProvider =
    AutoDisposeAsyncNotifierProvider<ForgotPasswordController, void>(
  ForgotPasswordController.new,
);
