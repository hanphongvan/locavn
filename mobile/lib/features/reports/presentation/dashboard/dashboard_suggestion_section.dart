import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/reports_overview_dto.dart';
import '../../data/models/station_count_by_province.dart';
import '../../../../core/router/app_routes.dart';
import 'loca_dashboard_tokens.dart';

/// “Gợi ý” — dùng dữ liệu thật [stationsByProvince] (top 3 theo số cây xăng).
class DashboardSuggestionSection extends StatelessWidget {
  const DashboardSuggestionSection({super.key, required this.overview});

  final ReportsOverviewDto overview;

  List<StationCountByProvince> _topProvinces() {
    final rows = List<StationCountByProvince>.from(overview.stationsByProvince);
    rows.sort((a, b) => b.stationCount.compareTo(a.stationCount));
    if (rows.length > 3) return rows.sublist(0, 3);
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final top = _topProvinces();
    final tints = [
      LocaDashboardTokens.accentGreen.withValues(alpha: 0.12),
      LocaDashboardTokens.primaryBlue.withValues(alpha: 0.08),
      const Color(0xFF0D9488).withValues(alpha: 0.1),
    ];

    final entries = top.isNotEmpty
        ? List.generate(
            top.length,
            (i) {
              final r = top[i];
              final label = r.provinceName ?? r.provinceCode ?? 'Khu vực';
              return _SuggestionEntry(
                tint: tints[i % tints.length],
                title: label,
                subtitle: 'Khu vực trong báo cáo máy chủ',
                badge: '${r.stationCount} trạm',
              );
            },
          )
        : [
            _SuggestionEntry(
              tint: tints[0],
              title: 'Cây xăng uy tín',
              subtitle: 'Mở bản đồ để xem đánh giá & trạm được tin dùng',
              badge: 'Bản đồ',
            ),
            _SuggestionEntry(
              tint: tints[1],
              title: 'Cây xăng gần nhất',
              subtitle: 'Định vị và tìm trạm gần bạn trên bản đồ',
              badge: 'GPS',
            ),
            _SuggestionEntry(
              tint: tints[2],
              title: 'Cây xăng rẻ nhất',
              subtitle: 'So sánh giá bán lẻ trên bản đồ',
              badge: 'Giá',
            ),
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Gợi ý cho bạn',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: LocaDashboardTokens.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(AppRoute.map.path),
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: LocaDashboardTokens.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(entries.length, (i) {
            final e = entries[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SuggestionProvinceCard(
                tint: e.tint,
                title: e.title,
                subtitle: e.subtitle,
                badge: e.badge,
                onTap: () => context.go(AppRoute.map.path),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SuggestionEntry {
  _SuggestionEntry({
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final Color tint;
  final String title;
  final String subtitle;
  final String badge;
}

class _SuggestionProvinceCard extends StatelessWidget {
  const _SuggestionProvinceCard({
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  final Color tint;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusMd),
            border: Border.all(color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: LocaDashboardTokens.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    title.isNotEmpty ? title.characters.first.toUpperCase() : 'L',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: LocaDashboardTokens.primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: LocaDashboardTokens.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: LocaDashboardTokens.cardWhite,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: LocaDashboardTokens.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: LocaDashboardTokens.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        const Text(
                          'Chi tiết trên bản đồ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: LocaDashboardTokens.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: LocaDashboardTokens.accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Theo báo cáo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: LocaDashboardTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: LocaDashboardTokens.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
