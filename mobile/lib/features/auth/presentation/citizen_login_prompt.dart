import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import 'widgets/gradient_button.dart';
import 'widgets/login_screen_theme.dart';

/// Modal khi guest chạm chức năng cần tài khoản — UI đồng bộ tone [LoginScreenTheme].
Future<void> showCitizenLoginRequiredPrompt(BuildContext context) async {
  final goLogin = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          LoginScreenTheme.bgTop,
                          LoginScreenTheme.bgMid,
                          LoginScreenTheme.bgBottom,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                LoginScreenTheme.gradientStart,
                                LoginScreenTheme.gradientEnd,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: LoginScreenTheme.gradientStart.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_person_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Đăng nhập để tiếp tục',
                          textAlign: TextAlign.center,
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LoginScreenTheme.titleBlue,
                                height: 1.25,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                    child: Text(
                      'Bạn có thể xem bản đồ và tìm cây xăng mà không cần tài khoản. '
                      'Vui lòng đăng nhập để sử dụng chức năng đánh giá, báo vi phạm, '
                      'quản lý nhiên liệu và xe cá nhân.',
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GradientButton(
                          label: 'Đăng nhập / Đăng ký',
                          trailingIcon: Icons.arrow_forward_rounded,
                          onPressed: () => Navigator.pop(ctx, true),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: TextButton.styleFrom(
                              foregroundColor: LoginScreenTheme.titleBlue.withValues(alpha: 0.75),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              textStyle: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            child: const Text('Để sau'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  if (goLogin == true && context.mounted) {
    context.push(AppRoute.login);
  }
}
