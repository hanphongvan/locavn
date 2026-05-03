import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import 'data/account_activity_api.dart';
import 'data/account_activity_models.dart';

/// Chỉ có nghĩa khi đã đăng nhập; tab Tài khoản gọi sau khi có session.
final accountActivitySummaryProvider =
    FutureProvider.autoDispose<AccountActivitySummary>((ref) async {
  // Chỉ rebuild khi `isAuthenticated` đổi (login/logout) — không invalidate
  // mỗi lần `notifyListeners` lặt vặt của AuthSessionController.
  final isAuthed = ref.watch(
    authSessionControllerProvider.select((c) => c.isAuthenticated),
  );
  if (!isAuthed) {
    return const AccountActivitySummary(reviewsCount: 0, reportsCount: 0, fuelTransactionsCount: 0);
  }
  return ref.watch(accountActivityApiProvider).getSummary();
});
