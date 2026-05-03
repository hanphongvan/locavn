import 'package:flutter/material.dart';

import 'login_screen_theme.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingMessage = 'Đang đăng nhập…',
    this.trailingIcon = Icons.arrow_forward_rounded,
    this.gradientColors,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String loadingMessage;
  final IconData? trailingIcon;
  /// When null, uses [LoginScreenTheme] login gradient.
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final effective = loading ? null : onPressed;
    const height = 52.0;
    final radius = BorderRadius.circular(LoginScreenTheme.controlRadius);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        );

    return ClipRRect(
      borderRadius: radius,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: effective,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors ??
                    const [
                      LoginScreenTheme.gradientStart,
                      LoginScreenTheme.gradientEnd,
                    ],
              ),
            ),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: loading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(loadingMessage, style: titleStyle),
                      ],
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 44),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                        ),
                        if (trailingIcon != null)
                          Positioned(
                            right: 16,
                            child: Icon(trailingIcon, color: Colors.white, size: 22),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
