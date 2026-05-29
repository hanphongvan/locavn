import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_root_navigator_key.dart';
import '../data/app_version_policy_api.dart';
import '../data/app_version_policy_models.dart';

/// Listener wrapper: theo dõi [appVersionUpdateCheckProvider] và hiện dialog
/// force/soft update khi backend trả policy yêu cầu cập nhật. Dialog hiện 1 lần / session.
///
/// Đặt bên trong [MaterialApp.router] để có Navigator. Side-effect-only widget —
/// luôn trả child nguyên vẹn.
class AppVersionGate extends ConsumerStatefulWidget {
  const AppVersionGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppVersionGate> createState() => _AppVersionGateState();
}

class _AppVersionGateState extends ConsumerState<AppVersionGate> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppVersionCheckResult>>(
      appVersionUpdateCheckProvider,
      (prev, next) {
        if (_shown) return;
        final value = next.asData?.value;
        if (value == null) return;
        if (value.status == AppVersionUpdateStatus.upToDate ||
            value.status == AppVersionUpdateStatus.unknown) {
          return;
        }
        _shown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showUpdateDialog(value);
        });
      },
    );
    return widget.child;
  }

  Future<void> _showUpdateDialog(AppVersionCheckResult check) async {
    final ctx = appRootNavigatorKey.currentContext;
    if (ctx == null) return;
    final isForce = check.status == AppVersionUpdateStatus.forceUpdate;
    final policy = check.policy;
    final title = isForce ? 'Bắt buộc cập nhật' : 'Có phiên bản mới';
    final msg = policy?.messageVi ??
        (isForce
            ? 'Phiên bản đang dùng không còn được hỗ trợ. Vui lòng cập nhật để tiếp tục sử dụng.'
            : 'Đã có phiên bản mới. Cập nhật ngay để có các cải tiến mới nhất.');
    final storeUrl = policy?.storeUrl;

    await showDialog<void>(
      context: ctx,
      barrierDismissible: !isForce,
      builder: (dialogCtx) {
        return PopScope(
          canPop: !isForce,
          child: AlertDialog(
            title: Text(title),
            content: Text(msg),
            actions: [
              if (!isForce)
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Để sau'),
                ),
              FilledButton(
                onPressed: () => _openStore(storeUrl),
                child: const Text('Cập nhật'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openStore(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
