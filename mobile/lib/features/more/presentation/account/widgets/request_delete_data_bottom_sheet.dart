import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/auth/auth_providers.dart';
import '../../../../../core/auth/biometric/biometric_providers.dart';
import '../../../../../core/network/api_exception.dart';
import '../account_palette.dart';
import '../data/request_delete_data_api.dart';

/// Bottom sheet **Xoá tài khoản** — Apple App Store Guideline 5.1.1(v).
///
/// Tài khoản và dữ liệu cá nhân bị xoá ngay lập tức (không pending, không cancel).
/// Sau khi xoá thành công, app clear biometric enrollment + logout → redirect `/login`.
///
/// Dùng [useRootNavigator] để sheet không gắn vào navigator của nhánh tab
/// ([StatefulNavigationShell]): tránh assert `_elements.contains(element)` khi shell rebuild / logout.
Future<void> showRequestDeleteDataSheet(BuildContext context, WidgetRef ref) async {
  final hostMessenger = ScaffoldMessenger.maybeOf(context);
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RequestDeleteDataSheet(hostMessenger: hostMessenger),
  );
}

class _RequestDeleteDataSheet extends ConsumerStatefulWidget {
  const _RequestDeleteDataSheet({this.hostMessenger});

  /// [ScaffoldMessenger] của màn Tài khoản (trước khi mở sheet) — tránh tra cứu sau khi route sheet bị gỡ.
  final ScaffoldMessengerState? hostMessenger;

  @override
  ConsumerState<_RequestDeleteDataSheet> createState() => _RequestDeleteDataSheetState();
}

class _RequestDeleteDataSheetState extends ConsumerState<_RequestDeleteDataSheet> {
  bool _accepted = false;
  bool _loading = false;
  String? _error;

  static const _successCopy = 'Tài khoản và dữ liệu cá nhân của bạn đã được xoá.';

  static const _deletedItems = <String>[
    'Hồ sơ tài khoản (email, họ tên, ảnh đại diện, mật khẩu)',
    'Phương tiện và toàn bộ lịch sử nhiên liệu',
    'Phiên đăng nhập và sinh trắc học trên thiết bị này',
  ];

  static const _anonymizedItems = <String>[
    'Đánh giá công khai về cây xăng',
    'Báo cáo vi phạm bạn đã gửi',
  ];

  static const _genericError = 'Không thể xoá tài khoản lúc này. Vui lòng thử lại sau.';

  Future<void> _confirmAndSubmit() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: !_loading,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá tài khoản ngay?'),
        content: const Text(
          'Tài khoản và toàn bộ dữ liệu cá nhân của bạn sẽ bị xoá vĩnh viễn. '
          'Bạn sẽ không thể đăng nhập lại bằng tài khoản này. '
          'Hành động này KHÔNG THỂ HOÀN TÁC.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xoá ngay'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _submit();
  }

  Future<void> _submit() async {
    // Capture provider refs before sheet/widget tree may be disposed by logout-driven rebuild.
    final biometricStore = ref.read(biometricCredentialStoreProvider);
    final authController = ref.read(authSessionControllerProvider);
    final messenger = widget.hostMessenger;

    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final res = await ref.read(requestDeleteDataApiProvider).submit();
      if (!mounted) return;
      if (res.success) {
        final msg = res.message.isNotEmpty ? res.message : _successCopy;
        Navigator.of(context, rootNavigator: true).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          messenger?.showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
          );
          await biometricStore.clearEnrollment();
          await authController.logout();
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = res.message.isEmpty ? _genericError : res.message;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message.isEmpty ? _genericError : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _genericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        decoration: const BoxDecoration(
          color: AccountPalette.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AccountPalette.radiusLg)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AccountPalette.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Xoá tài khoản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AccountPalette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Tài khoản và toàn bộ dữ liệu cá nhân sẽ bị xoá NGAY LẬP TỨC khi bạn xác nhận. '
                  'Bạn sẽ không thể đăng nhập lại bằng tài khoản này. '
                  'Hành động này KHÔNG THỂ HOÀN TÁC.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AccountPalette.textSecondary.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Dữ liệu sẽ bị xoá vĩnh viễn',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AccountPalette.textPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                ..._deletedItems.map((t) => _BulletRow(text: t, color: const Color(0xFFB91C1C))),
                const SizedBox(height: 12),
                Text(
                  'Dữ liệu giữ lại nhưng không còn liên kết với bạn (ẩn danh)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AccountPalette.textPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                ..._anonymizedItems.map((t) => _BulletRow(text: t, color: AccountPalette.primaryBlue.withValues(alpha: 0.55))),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _loading ? null : () => setState(() => _accepted = !_accepted),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _accepted,
                          onChanged: _loading ? null : (v) => setState(() => _accepted = v ?? false),
                          activeColor: const Color(0xFFB91C1C),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12, right: 4),
                            child: Text(
                              'Tôi hiểu rằng tài khoản và dữ liệu cá nhân sẽ bị xoá vĩnh viễn và '
                              'hành động này không thể hoàn tác.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: AccountPalette.textPrimary.withValues(alpha: 0.88),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB91C1C),
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: (!_accepted || _loading) ? null : _confirmAndSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFB91C1C),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFB91C1C).withValues(alpha: 0.35),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Text('Xoá tài khoản', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : () => Navigator.of(context, rootNavigator: true).pop(),
                    child: Text(
                      'Huỷ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AccountPalette.textSecondary.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 10),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AccountPalette.textSecondary.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
