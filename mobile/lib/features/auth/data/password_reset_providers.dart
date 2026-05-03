import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import 'password_reset_api.dart';

/// Shared by both forgot- and reset-password flows.
final passwordResetApiProvider = Provider<PasswordResetApi>((ref) {
  return PasswordResetApi(ref.watch(dioProvider));
});
