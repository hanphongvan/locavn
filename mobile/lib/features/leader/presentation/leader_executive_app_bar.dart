import 'package:flutter/material.dart';

/// Header Lãnh đạo — gradient navy (#0B2F6B → #1F3C93), thẻ bo tròn, chữ trắng.
///
/// Nền **xung quanh** thẻ (khe ngang, vùng trên status) do [Scaffold.backgroundColor]
/// trong [LeaderMainScreen] — đồng bộ theo tab.
class LeaderExecutiveAppBar extends StatelessWidget {
  const LeaderExecutiveAppBar({super.key, this.filterAction});

  /// Tab Quỹ bình ổn: mở lọc kỳ BC08.
  final VoidCallback? filterAction;

  static const Color navyDeep = Color(0xFF0B2F6B);
  static const Color navyMid = Color(0xFF1F3C93);

  static const double _cardRadius = 20;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = BorderRadius.circular(_cardRadius);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        child: Material(
          color: Colors.transparent,
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(borderRadius: r),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  LeaderExecutiveAppBar.navyDeep,
                  LeaderExecutiveAppBar.navyMid,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 22,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CSDL Xăng Dầu Quốc Gia',
                          style: t.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                            height: 1.05,
                          ),
                        ),
                        Text(
                          'Giám sát điều hành xăng dầu',
                          style: t.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (filterAction != null)
                    IconButton(
                      tooltip: 'Lọc tháng/năm',
                      onPressed: filterAction,
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(6),
                        // a11y: giữ Material default tap target ≥ 48dp;
                        // visual icon vẫn 20dp do `Icon(size: 20)`.
                      ),
                      icon: Icon(
                        Icons.filter_list_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.95),
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
