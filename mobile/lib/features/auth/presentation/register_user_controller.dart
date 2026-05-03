import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/register_user_models.dart';
import '../data/register_user_providers.dart';

/// Controls the register-user submit flow. UI watches this for loading/error
/// state and calls [submit] to trigger the API.
class RegisterUserController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Idle by default — `AsyncData(null)`.
  }

  Future<RegisterUserResponseDto> submit(RegisterUserRequestDto body) async {
    final api = ref.read(registerUserApiProvider);
    state = const AsyncLoading();
    try {
      final res = await api.register(body);
      state = const AsyncData(null);
      return res;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final registerUserControllerProvider =
    AutoDisposeAsyncNotifierProvider<RegisterUserController, void>(
  RegisterUserController.new,
);
