import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/formatting/vnd_currency_format.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../map/presentation/map_discovery_navigation.dart';
import '../../../../map/presentation/map_providers.dart';
import '../loca_dashboard_tokens.dart';
import 'citizen_dashboard_map_suggestions_provider.dart';

const double _kCitizenSuggestionCardRadius = 16;

/// Ba gợi ý (uy tín / gần nhất / rẻ nhất) — dữ liệu từ [citizenDashboardMapSuggestionsProvider] (cùng GPS + lọc với Bản đồ).
class CitizenDashboardSuggestions extends ConsumerWidget {
  const CitizenDashboardSuggestions({super.key});

  /// Dòng phụ dưới tên trạm (địa chỉ); không lặp [StationMapItem.stationName] vì đã dùng làm tiêu đề.
  static String _stationLocationLine(CitizenMapStationSuggestion s) {
    final a = s.item.shortAddress?.trim();
    if (a != null && a.isNotEmpty) return a;
    return 'Chạm để xem trên bản đồ';
  }

  static String _nearestSubtitle(CitizenDashboardMapSuggestions d) {
    if (d.nearestNeedsLocation) {
      return 'Bật định vị để xem cây xăng gần bạn, hoặc mở Bản đồ.';
    }
    final s = d.nearest;
    if (s != null) return _stationLocationLine(s);
    return 'Không có trạm trong phạm vi đã lọc — thử nới bộ lọc trên Bản đồ.';
  }

  static String _topRatedSubtitle(CitizenDashboardMapSuggestions d) {
    final s = d.topRated;
    if (s != null) return _stationLocationLine(s);
    return 'Chưa có dữ liệu uy tín.';
  }

  static String _cheapestSubtitle(CitizenDashboardMapSuggestions d) {
    final s = d.cheapest;
    if (s != null) return _stationLocationLine(s);
    return 'Chưa có giá RON95 trong danh sách đã lọc.';
  }

  static String _stationTitle(CitizenMapStationSuggestion? s, String whenEmpty) {
    final n = s?.item.stationName.trim();
    if (n != null && n.isNotEmpty) return n;
    return whenEmpty;
  }

  static String _nearestBadge(CitizenDashboardMapSuggestions d) {
    if (d.nearestNeedsLocation) return 'GPS';
    final km = d.nearest?.distanceKm;
    if (km != null) return '${km.toStringAsFixed(1)} km';
    return 'GPS';
  }

  static String _topRatedBadge(CitizenMapStationSuggestion? s) {
    final r = s?.averageRating;
    if (r != null) return r.toStringAsFixed(1);
    return 'Bản đồ';
  }

  static String _priceLine(CitizenMapStationSuggestion? s) {
    final p = s?.priceRon95;
    if (p != null) return '${formatVndCurrency(p)}/lít';
    return 'Xem giá trên bản đồ';
  }

  static String _ratingMain(CitizenMapStationSuggestion? s) {
    final r = s?.averageRating;
    if (r != null) return r.toStringAsFixed(1);
    return '—';
  }

  static String _ratingReviews(CitizenMapStationSuggestion? s) {
    final n = s?.reviewCount;
    if (n != null && n > 0) return '$n đánh giá';
    if (s?.averageRating != null) return 'đánh giá';
    return ' ';
  }

  Future<void> _openSuggestion(
    BuildContext context,
    WidgetRef ref,
    CitizenMapStationSuggestion? suggestion,
  ) async {
    if (suggestion == null) {
      if (context.mounted) context.go(AppRoute.map.path);
      return;
    }
    if (suggestion.needsEphemeralMarker) {
      ref.read(mapEphemeralStationProvider.notifier).state = suggestion.item;
    }
    if (context.mounted) context.go(AppRoute.map.path);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!context.mounted) return;
    await focusMapStationAndOpenSummary(
      context,
      ref,
      suggestion.item,
      distanceKm: suggestion.distanceKm,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(citizenDashboardMapSuggestionsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Gợi ý cho bạn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: LocaDashboardTokens.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(AppRoute.map.path),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  // a11y: giữ Material default tap target ≥ 48dp.
                ),
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: LocaDashboardTokens.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          async.when(
            data: (d) {
              final cards = <_CitizenSuggestionSpec>[
                _CitizenSuggestionSpec(
                  accent: LocaDashboardTokens.primaryBlue,
                  tint: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.1),
                  border: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.2),
                  title: _stationTitle(d.nearest, 'Gần nhất'),
                  location: _nearestSubtitle(d),
                  distanceBadge: _nearestBadge(d),
                  priceLine: _priceLine(d.nearest),
                  ratingStarsValue: _ratingMain(d.nearest),
                  ratingReviewsLabel: _ratingReviews(d.nearest),
                  logo: _SuggestionLogo.near,
                  suggestion: d.nearest,
                ),
                _CitizenSuggestionSpec(
                  accent: const Color(0xFF0D9488),
                  tint: const Color(0xFF0D9488).withValues(alpha: 0.12),
                  border: const Color(0xFF0D9488).withValues(alpha: 0.24),
                  title: _stationTitle(d.cheapest, 'Rẻ nhất'),
                  location: _cheapestSubtitle(d),
                  distanceBadge: 'Giá',
                  priceLine: _priceLine(d.cheapest),
                  ratingStarsValue: _ratingMain(d.cheapest),
                  ratingReviewsLabel: _ratingReviews(d.cheapest),
                  logo: _SuggestionLogo.price,
                  suggestion: d.cheapest,
                ),
                _CitizenSuggestionSpec(
                  accent: LocaDashboardTokens.accentGreen,
                  tint: LocaDashboardTokens.accentGreen.withValues(alpha: 0.12),
                  border: LocaDashboardTokens.accentGreen.withValues(alpha: 0.22),
                  title: _stationTitle(d.topRated, 'Uy tín nhất'),
                  location: _topRatedSubtitle(d),
                  distanceBadge: _topRatedBadge(d.topRated),
                  priceLine: _priceLine(d.topRated),
                  ratingStarsValue: _ratingMain(d.topRated),
                  ratingReviewsLabel: _ratingReviews(d.topRated),
                  logo: _SuggestionLogo.verified,
                  suggestion: d.topRated,
                ),
              ];
              return Column(
                children: cards
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CitizenSuggestionCard(
                          spec: e,
                          onTap: () => _openSuggestion(context, ref, e.suggestion),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => Column(
              children: [
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: LocaDashboardTokens.primaryBlue,
                  backgroundColor: Color(0xFFE8EEF5),
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  3,
                  (i) => Padding(
                    padding: EdgeInsets.only(bottom: i < 2 ? 12 : 0),
                    child: Container(
                      height: 104,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(_kCitizenSuggestionCardRadius),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            error: (_, _) => const Text(
              'Không tải được gợi ý. Kéo xuống làm mới hoặc mở Bản đồ.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: LocaDashboardTokens.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SuggestionLogo { verified, near, price }

class _CitizenSuggestionSpec {
  const _CitizenSuggestionSpec({
    required this.accent,
    required this.tint,
    required this.border,
    required this.title,
    required this.location,
    required this.distanceBadge,
    required this.priceLine,
    required this.ratingStarsValue,
    required this.ratingReviewsLabel,
    required this.logo,
    this.suggestion,
  });

  final Color accent;
  final Color tint;
  final Color border;
  final String title;
  final String location;
  final String distanceBadge;
  final String priceLine;
  final String ratingStarsValue;
  final String ratingReviewsLabel;
  final _SuggestionLogo logo;
  final CitizenMapStationSuggestion? suggestion;
}

class _CitizenSuggestionCard extends StatelessWidget {
  const _CitizenSuggestionCard({required this.spec, required this.onTap});

  final _CitizenSuggestionSpec spec;
  final VoidCallback onTap;

  IconData _logoIcon() {
    switch (spec.logo) {
      case _SuggestionLogo.verified:
        return Icons.verified_rounded;
      case _SuggestionLogo.near:
        return Icons.near_me_rounded;
      case _SuggestionLogo.price:
        return Icons.savings_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: spec.tint,
      borderRadius: BorderRadius.circular(_kCitizenSuggestionCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kCitizenSuggestionCardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kCitizenSuggestionCardRadius),
            border: Border.all(color: spec.border, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: spec.accent.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: spec.accent.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _logoIcon(),
                  size: 28,
                  color: spec.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            spec.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: LocaDashboardTokens.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: spec.accent.withValues(alpha: 0.22)),
                          ),
                          child: Text(
                            spec.distanceBadge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: spec.accent,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      spec.location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: LocaDashboardTokens.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      spec.priceLine,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: LocaDashboardTokens.primaryBlue,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded, size: 20, color: Colors.amber.shade700),
                        const SizedBox(width: 6),
                        Text(
                          spec.ratingStarsValue,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: LocaDashboardTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            spec.ratingReviewsLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: LocaDashboardTokens.textSecondary,
                            ),
                          ),
                        ),
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
                          'Còn nhiều hàng',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: LocaDashboardTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 4),
                child: Icon(Icons.chevron_right_rounded, color: LocaDashboardTokens.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
