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
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              height: 1.2,
              color: AccountPalette.textSecondary.withValues(alpha: 0.9),
              decoration: TextDecoration.none,
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
