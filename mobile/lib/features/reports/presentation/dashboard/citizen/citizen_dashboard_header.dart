import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/auth/auth_providers.dart';
import '../loca_dashboard_tokens.dart';

/// LocaVN header for Citizen dashboard — same session data as [DashboardHeader], layout tuned for role.
class CitizenDashboardHeader extends ConsumerWidget {
  const CitizenDashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chỉ rebuild khi reference của `session` đổi (login/logout/restore).
    final session = ref.watch(
      authSessionControllerProvider.select((c) => c.session),
    );
    final display = session?.displayName?.trim();
    final user = session?.userName.trim() ?? '';
    final greetName = (display != null && display.isNotEmpty) ? display : (user.isNotEmpty ? user : 'bạn');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LocaLogoRow(),
                const SizedBox(height: 18),
                Text(
                  'Xin chào, $greetName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: LocaDashboardTokens.textPrimary,
                    height: 1.2,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chúc bạn một ngày tốt lành!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: LocaDashboardTokens.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 26,
            backgroundColor: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.12),
            child: Text(
              greetName.isNotEmpty ? greetName.characters.first.toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: LocaDashboardTokens.primaryBlue,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocaLogoRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Loca',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            color: LocaDashboardTokens.primaryBlue,
            height: 1,
          ),
        ),
        Text(
          'VN',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            color: LocaDashboardTokens.accentGreen,
            height: 1,
          ),
        ),
      ],
    );
  }
}
