import 'package:flutter/material.dart';

import '../../../../auth/presentation/widgets/gradient_button.dart';
import '../../../../stations/presentation/station_review/station_review_compose_theme.dart';

class SubmitReportButton extends StatelessWidget {
  const SubmitReportButton({
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
    return Opacity(
      opacity: enabled || loading ? 1 : 0.45,
      child: GradientButton(
        label: 'GỬI BÁO CÁO',
        loading: loading,
        loadingMessage: 'Đang gửi…',
        trailingIcon: null,
        gradientColors: const [
          StationReviewComposeTheme.primary,
          StationReviewComposeTheme.accent,
        ],
        onPressed: enabled && !loading ? onPressed : null,
      ),
    );
  }
}
