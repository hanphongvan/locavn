import 'package:flutter/material.dart';

import 'login_screen_theme.dart';

/// Đường dẫn asset logo (thư mục `mobile/assets/banner/`).
const String kAppLogoAssetPath = 'assets/banner/logo-app.png';

/// Logo ứng dụng từ asset; nếu tải lỗi thì hiển thị biểu trưng dự phòng.
class LoginBrandLogo extends StatelessWidget {
  const LoginBrandLogo({super.key, this.size = 112});

  final double size;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(size * 0.22);
    return Semantics(
      label: 'Biểu trưng ứng dụng',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: [
            BoxShadow(
              color: LoginScreenTheme.gradientStart.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          kAppLogoAssetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return _LoginMarkFallback(size: size, borderRadius: r);
          },
        ),
      ),
    );
  }
}

class _LoginMarkFallback extends StatelessWidget {
  const _LoginMarkFallback({required this.size, required this.borderRadius});

  final double size;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LoginScreenTheme.gradientStart,
            LoginScreenTheme.gradientEnd,
          ],
        ),
      ),
      child: Icon(
        Icons.local_gas_station_rounded,
        size: size * 0.42,
        color: Colors.white,
      ),
    );
  }
}
