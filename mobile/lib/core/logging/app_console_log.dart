import 'package:flutter/foundation.dart';

/// Ghi lỗi ra terminal/IDE khi chạy `flutter run` để có thể copy nguyên văn.
void logAppError(String context, Object error, [StackTrace? stackTrace]) {
  debugPrint('[httm_xangdau] $context');
  debugPrint('[httm_xangdau] $error');
  if (stackTrace != null) {
    debugPrintStack(stackTrace: stackTrace, label: '[httm_xangdau] stack');
  }
}
