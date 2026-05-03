import 'package:flutter/material.dart';

import '../account_palette.dart';

class AccountMenuItem extends StatelessWidget {
  const AccountMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.showDividerBelow = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool showDividerBelow;

  @override
  Widget build(BuildContext context) {
    final textColor = danger ? const Color(0xFFB91C1C) : AccountPalette.textPrimary;
    final iconColor = danger ? const Color(0xFFB91C1C) : AccountPalette.primaryBlue;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AccountPalette.primaryBlue.withValues(alpha: danger ? 0.06 : 0.08),
                    ),
                    child: Icon(icon, size: 22, color: iconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AccountPalette.textSecondary.withValues(alpha: 0.85),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDividerBelow)
          Divider(height: 1, thickness: 1, color: AccountPalette.border.withValues(alpha: 0.7)),
      ],
    );
  }
}
