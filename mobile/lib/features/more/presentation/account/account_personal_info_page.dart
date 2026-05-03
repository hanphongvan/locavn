import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import 'account_palette.dart';

/// Màn chỉ đọc thông tin phiên đăng nhập (không gọi API thêm).
class AccountPersonalInfoPage extends StatelessWidget {
  const AccountPersonalInfoPage({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final name = (session.displayName?.trim().isNotEmpty ?? false)
        ? session.displayName!.trim()
        : session.userName;

    return Scaffold(
      backgroundColor: AccountPalette.background,
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        backgroundColor: AccountPalette.cardWhite,
        foregroundColor: AccountPalette.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('Họ và tên', name),
          _row('Tên đăng nhập', session.userName),
          _row('Email', session.email?.trim().isNotEmpty == true ? session.email!.trim() : '—'),
          _row('Mã đơn vị', session.donViId?.toString() ?? '—'),
        ],
      ),
    );
  }

  static Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AccountPalette.cardWhite,
          borderRadius: BorderRadius.circular(AccountPalette.radiusMd),
          border: Border.all(color: AccountPalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              k,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AccountPalette.textSecondary.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              v,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AccountPalette.textPrimary,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
