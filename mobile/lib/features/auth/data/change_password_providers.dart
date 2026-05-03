import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import 'change_password_api.dart';

final changePasswordApiProvider = Provider<ChangePasswordApi>((ref) {
  return ChangePasswordApi(ref.watch(dioProvider));
});
