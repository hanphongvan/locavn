import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _kFeedbackFabDismissedKey = 'feedback_fab_dismissed';

/// Trạng thái: người dùng đã tự ẩn FAB "Góp ý" hay chưa (lưu cục bộ).
///
/// Một chiều — ẩn rồi không bật lại trong app; người dùng vẫn góp ý qua mục Tài khoản.
class FeedbackFabDismissNotifier extends StateNotifier<bool> {
  FeedbackFabDismissNotifier(this._storage) : super(false) {
    _load();
  }

  final FlutterSecureStorage _storage;

  Future<void> _load() async {
    final v = await _storage.read(key: _kFeedbackFabDismissedKey);
    if (mounted) state = v == '1';
  }

  /// Ẩn FAB và lưu để các lần mở app sau không hiện lại.
  Future<void> dismiss() async {
    state = true;
    await _storage.write(key: _kFeedbackFabDismissedKey, value: '1');
  }
}

/// `true` = đã ẩn FAB góp ý. FAB chỉ hiện khi backend bật cờ VÀ chưa bị ẩn.
final feedbackFabDismissedProvider =
    StateNotifierProvider<FeedbackFabDismissNotifier, bool>((ref) {
  return FeedbackFabDismissNotifier(const FlutterSecureStorage());
});
