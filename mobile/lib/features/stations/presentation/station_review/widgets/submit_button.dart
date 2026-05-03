import 'package:flutter/material.dart';

import '../station_review_compose_theme.dart';

/// Nút gửi full-width, gradient, bo pill, có bóng và splash.
class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effective = enabled && !loading ? onPressed : null;
    const height = 56.0;

    return Opacity(
      opacity: enabled || loading ? 1 : 0.45,
      child: Material(
        elevation: 0,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: StationReviewComposeTheme.primary.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: effective,
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: StationReviewComposeTheme.submitGradient,
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
                              Text(
                                'Đang gửi…',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Text(
                              'GỬI ĐÁNH GIÁ',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.9,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
