import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../leader_executive_app_bar.dart';

/// Nút nổi **Loca AI** — bổ sung cho icon trên [LeaderExecutiveAppBar], dễ nhận diện hơn.
///
/// Gradient đồng bộ header lãnh đạo; bóng mềm + viền sáng nhẹ để nổi trên mọi nền tab.
class LeaderLocaAiAssistBubble extends StatelessWidget {
  const LeaderLocaAiAssistBubble({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(26));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Mở Loca AI — trợ lý hỏi đáp dữ liệu điều hành',
      child: Material(
        color: Colors.transparent,
        elevation: 14,
        shadowColor: const Color(0xFF0B2F6B).withValues(alpha: 0.35),
        borderRadius: _radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: _radius,
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: _radius,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  LeaderExecutiveAppBar.navyDeep,
                  LeaderExecutiveAppBar.navyMid,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loca AI',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            height: 1.05,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Trợ lý điều hành',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                            fontSize: 10.5,
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
      ),
    );
  }
}
