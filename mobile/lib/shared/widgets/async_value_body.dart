import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_console_log.dart';
import '../../core/network/api_exception.dart';
import 'app_empty_state.dart';
import 'app_error_state.dart';

/// Standard loading / data / empty / error handling for `AsyncValue` from Riverpod.
class AsyncValueBody<T> extends StatelessWidget {
  const AsyncValueBody({
    super.key,
    required this.value,
    required this.dataBuilder,
    this.emptyMessage,
    this.isEmpty,
    this.onRetry,
    this.loadingLabel = 'Đang tải',
    this.errorLogLabel,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) dataBuilder;
  final String? emptyMessage;
  final bool Function(T data)? isEmpty;
  final VoidCallback? onRetry;

  /// Accessibility label while [AsyncValue.isLoading].
  final String loadingLabel;

  /// Tiền tố log ra terminal khi [value] lỗi (vd. `Bản đồ cây xăng`).
  final String? errorLogLabel;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => Center(
        child: Semantics(
          label: loadingLabel,
          child: const CircularProgressIndicator(),
        ),
      ),
      error: (e, st) {
        final label = errorLogLabel ?? 'AsyncValueBody';
        logAppError(label, e, st);
        final message = e is ApiException ? e.message : e.toString();
        return AppErrorState(message: message, onRetry: onRetry);
      },
      data: (data) {
        if (isEmpty != null && isEmpty!(data)) {
          return AppEmptyState(
            message: emptyMessage ?? 'Không có dữ liệu.',
            onRetry: onRetry,
          );
        }
        return dataBuilder(data);
      },
    );
  }
}
