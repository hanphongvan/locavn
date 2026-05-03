import 'package:flutter/material.dart';

import '../account_palette.dart';

class MenuSection extends StatelessWidget {
  const MenuSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: AccountPalette.textSecondary.withValues(alpha: 0.95),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AccountPalette.cardWhite,
            borderRadius: BorderRadius.circular(AccountPalette.radiusLg),
            border: Border.all(color: AccountPalette.border),
            boxShadow: AccountPalette.cardShadow(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ],
    );
  }
}
