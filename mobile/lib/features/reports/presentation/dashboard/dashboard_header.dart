import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import 'dashboard_menu_actions.dart';
import 'loca_dashboard_tokens.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LocaLogo(),
                    const SizedBox(height: 16),
                    Text(
                      'Xin chào, $greetName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: LocaDashboardTokens.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Chúc bạn một ngày tốt lành!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: LocaDashboardTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        tooltip: 'Thông báo',
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none_rounded, color: LocaDashboardTokens.textSecondary),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    tooltip: 'Tài khoản & thêm',
                    onSelected: (v) => handleDashboardOverflowSelection(context, ref, v),
                    itemBuilder: (ctx) => buildDashboardOverflowMenuEntries(ref),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.12),
                      child: Text(
                        greetName.isNotEmpty ? greetName.characters.first.toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: LocaDashboardTokens.primaryBlue,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocaLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Loca',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: LocaDashboardTokens.primaryBlue,
            height: 1,
          ),
        ),
        Text(
          'VN',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: LocaDashboardTokens.accentGreen,
            height: 1,
          ),
        ),
      ],
    );
  }
}
