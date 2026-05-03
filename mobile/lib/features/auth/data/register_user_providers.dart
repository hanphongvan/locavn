import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import 'register_user_api.dart';

/// Single API instance per Dio (re-created when Dio rebuilds).
final registerUserApiProvider = Provider<RegisterUserApi>((ref) {
  return RegisterUserApi(ref.watch(dioProvider));
});
