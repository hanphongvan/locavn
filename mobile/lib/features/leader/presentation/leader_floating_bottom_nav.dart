import 'package:flutter/material.dart';

/// Bottom nav dạng viên nổi — pill trắng bo 24px; **vỏ trong suốt** để nội dung
/// (khi [Scaffold.extendBody]) hiện phía dưới khe an toàn / mép viên.
class LeaderFloatingBottomNav extends StatelessWidget {
  const LeaderFloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const Color activeBlue = Color(0xFF1F3C93);
  static const Color inactiveGray = Color(0xFF6B7280);
  static const Color activePillBg = Color(0xFFEAF1FF);

  static const List<({IconData outline, IconData filled, String label})>
  _destinations = [
    (
      outline: Icons.dashboard_outlined,
      filled: Icons.dashboard_rounded,
      label: 'Tổng quan',
    ),
    (outline: Icons.map_outlined, filled: Icons.map_rounded, label: 'Bản đồ'),
    (
      outline: Icons.insights_outlined,
      filled: Icons.insights_rounded,
      label: 'Phân tích',
    ),
    (
      outline: Icons.account_balance_wallet_outlined,
      filled: Icons.account_balance_wallet_rounded,
      label: 'Quỹ bình ổn',
    ),
    (
      outline: Icons.person_outline_rounded,
      filled: Icons.person_rounded,
      label: 'Tài khoản',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomPad = bottomInset > 0 ? bottomInset + 10.0 : 14.0;
    const horizontal = 14.0;

    return ColoredBox(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, bottomPad),
        child: Material(
          color: Colors.white,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _LeaderNavPillItem(
                      selected: currentIndex == i,
                      outline: _destinations[i].outline,
                      filled: _destinations[i].filled,
                      label: _destinations[i].label,
                      onTap: () => onDestinationSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderNavPillItem extends StatelessWidget {
  const _LeaderNavPillItem({
    required this.selected,
    required this.outline,
    required this.filled,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData outline;
  final IconData filled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = selected ? filled : outline;
    final color = selected
        ? LeaderFloatingBottomNav.activeBlue
        : LeaderFloatingBottomNav.inactiveGray;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Material(
        color: selected
            ? LeaderFloatingBottomNav.activePillBg
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: LeaderFloatingBottomNav.activeBlue.withValues(
            alpha: 0.08,
          ),
          highlightColor: LeaderFloatingBottomNav.activeBlue.withValues(
            alpha: 0.04,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.1,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
