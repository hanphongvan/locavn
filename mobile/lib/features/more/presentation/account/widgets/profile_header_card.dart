import 'package:flutter/material.dart';

import '../../../../../core/auth/auth_session.dart';
import '../account_palette.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.session,
    required this.onEditTap,
  });

  final AuthSession session;
  final VoidCallback onEditTap;

  String get _displayName {
    final d = session.displayName?.trim();
    if (d != null && d.isNotEmpty) return d;
    return session.userName;
  }

  String get _subtitle {
    final e = session.email?.trim();
    if (e != null && e.isNotEmpty) return e;
    return session.userName;
  }

  @override
  Widget build(BuildContext context) {
    final initial = _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      decoration: BoxDecoration(
        color: AccountPalette.cardWhite,
        borderRadius: BorderRadius.circular(AccountPalette.radiusLg),
        border: Border.all(color: AccountPalette.border),
        boxShadow: AccountPalette.cardShadow(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AccountPalette.primaryBlue.withValues(alpha: 0.1),
              border: Border.all(color: AccountPalette.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AccountPalette.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AccountPalette.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AccountPalette.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AccountPalette.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AccountPalette.border),
                  ),
                  child: const Text(
                    'Người dùng',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AccountPalette.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEditTap,
            style: TextButton.styleFrom(
              foregroundColor: AccountPalette.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            child: const Text(
              'Chỉnh sửa',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
