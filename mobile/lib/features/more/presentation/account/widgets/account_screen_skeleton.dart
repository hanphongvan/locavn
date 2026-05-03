import 'package:flutter/material.dart';

import '../account_palette.dart';

class AccountScreenSkeleton extends StatelessWidget {
  const AccountScreenSkeleton({super.key});

  static Widget _bone({double h = 14, double w = double.infinity, BorderRadius? r}) {
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: AccountPalette.border.withValues(alpha: 0.65),
        borderRadius: r ?? BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AccountPalette.cardWhite,
            borderRadius: BorderRadius.circular(AccountPalette.radiusLg),
            border: Border.all(color: AccountPalette.border),
          ),
          child: Row(
            children: [
              _bone(h: 60, w: 60, r: BorderRadius.circular(30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bone(h: 18, w: 180),
                    const SizedBox(height: 10),
                    _bone(h: 14, w: 220),
                    const SizedBox(height: 12),
                    _bone(h: 26, w: 100, r: BorderRadius.circular(20)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _bone(h: 96, r: BorderRadius.circular(AccountPalette.radiusMd))),
            const SizedBox(width: 10),
            Expanded(child: _bone(h: 96, r: BorderRadius.circular(AccountPalette.radiusMd))),
            const SizedBox(width: 10),
            Expanded(child: _bone(h: 96, r: BorderRadius.circular(AccountPalette.radiusMd))),
          ],
        ),
        const SizedBox(height: 24),
        _bone(h: 12, w: 120),
        const SizedBox(height: 10),
        _bone(h: 120, r: BorderRadius.circular(AccountPalette.radiusLg)),
        const SizedBox(height: 20),
        _bone(h: 12, w: 100),
        const SizedBox(height: 10),
        _bone(h: 160, r: BorderRadius.circular(AccountPalette.radiusLg)),
      ],
    );
  }
}
