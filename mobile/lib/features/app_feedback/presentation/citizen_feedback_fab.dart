import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../app_version/data/app_config_api.dart';
import '../data/feedback_fab_preference.dart';

/// FAB "Góp ý" cho shell citizen.
///
/// Hiện khi **backend bật cờ** (`/api/app/config`) **VÀ** người dùng **chưa tự ẩn**.
/// Nút `x` góc trên-phải để ẩn (lưu cục bộ, không bật lại trong app — vẫn còn lối ở Tài khoản).
class CitizenFeedbackFab extends ConsumerWidget {
  const CitizenFeedbackFab({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(appConfigProvider).maybeWhen(
          data: (c) => c.feedbackEnabled,
          orElse: () => true,
        );
    final dismissed = ref.watch(feedbackFabDismissedProvider);
    if (!enabled || dismissed) {
      return const SizedBox.shrink();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: color,
          elevation: 4,
          shadowColor: Colors.black45,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.push(AppRoute.appFeedback.path),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.feedback_outlined, color: Colors.white, size: 24),
                  SizedBox(height: 2),
                  Text(
                    'Góp ý',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: Material(
            color: Colors.white,
            shape: CircleBorder(side: BorderSide(color: color.withValues(alpha: 0.35))),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _dismiss(context, ref),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(Icons.close_rounded, size: 16, color: color),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    await ref.read(feedbackFabDismissedProvider.notifier).dismiss();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã ẩn nút góp ý. Bạn vẫn có thể góp ý trong mục Tài khoản.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Căn FAB vào **cạnh phải, giữa theo chiều dọc**. Không đè nút zoom/vị trí (bottom-right) của bản đồ.
const FloatingActionButtonLocation kCenterRightFabLocation = _CenterRightFabLocation();

class _CenterRightFabLocation extends FloatingActionButtonLocation {
  const _CenterRightFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final x = geometry.scaffoldSize.width - geometry.floatingActionButtonSize.width - 16;
    final y = (geometry.scaffoldSize.height - geometry.floatingActionButtonSize.height) / 2;
    return Offset(x, y);
  }
}
