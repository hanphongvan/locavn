import 'package:flutter/material.dart';

/// Pill CTA — blue → cyan → green (shared forms; distinct from auth login gradient).
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel = 'Đang lưu…',
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String loadingLabel;

  static const List<Color> _gradient = [
    Color(0xFF1D4ED8),
    Color(0xFF06B6D4),
    Color(0xFF34D399),
  ];

  @override
  Widget build(BuildContext context) {
    final effective = loading ? null : onPressed;
    const height = 50.0;
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: effective,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: _gradient,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Center(
                child: loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
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
                          Text(loadingLabel, style: titleStyle),
                        ],
                      )
                    : Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
