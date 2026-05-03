import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/portal_loai.dart';
import '../../../shared/widgets/async_value_body.dart';
import '../data/models/reports_overview_dto.dart';
import 'dashboard/dashboard_alert_banner.dart';
import 'dashboard/dashboard_background.dart';
import 'dashboard/dashboard_header.dart';
import 'dashboard/dashboard_overview_cards.dart';
import 'dashboard/dashboard_quick_action_grid.dart';
import 'dashboard/dashboard_search_bar.dart';
import 'dashboard/dashboard_section_title.dart';
import 'dashboard/dashboard_stat_cards.dart';
import 'dashboard/dashboard_suggestion_section.dart';
import 'dashboard/dashboard_vehicle_card.dart';
import 'dashboard/citizen/citizen_dashboard_content.dart';
import 'dashboard/loca_dashboard_tokens.dart';
import 'reports_providers.dart';

/// Overview from `GET /api/reports/overview` — chỉ dữ liệu thật từ API, bố cục LocaVN.
class ReportsShellPage extends ConsumerWidget {
  const ReportsShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportsOverviewProvider);

    Future<void> onRefresh() async {
      ref.invalidate(reportsOverviewProvider);
      await ref.read(reportsOverviewProvider.future);
    }

    return Scaffold(
      backgroundColor: LocaDashboardTokens.background,
      body: AsyncValueBody<ReportsOverviewDto>(
        value: async,
        errorLogLabel: 'Báo cáo (reportsOverviewProvider)',
        loadingLabel: 'Đang tải báo cáo',
        onRetry: () => ref.invalidate(reportsOverviewProvider),
        dataBuilder: (overview) {
          final loai = ref.watch(portalSessionScopeProvider)?.loai;
          final hideStationOverview = mapLoaiToPortalRole(loai) == PortalRole.citizen;

          if (hideStationOverview) {
            return CitizenDashboardContent(overview: overview);
          }

          return DashboardBackground(
            child: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: onRefresh,
                color: LocaDashboardTokens.primaryBlue,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    const DashboardHeader(),
                    const DashboardSearchBar(),
                    if (!hideStationOverview && overview.totalStations == 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: LocaDashboardTokens.cardWhite,
                            borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusMd),
                            boxShadow: LocaDashboardTokens.cardShadow(context),
                            border: Border.all(
                              color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.1),
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: const Row(
                            children: [
                              Icon(Icons.inbox_outlined, color: LocaDashboardTokens.textSecondary),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Dữ liệu đang báo 0 cây xăng. Kéo xuống hoặc dùng nút làm mới ở góc trên.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: LocaDashboardTokens.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const DashboardVehicleCard(),
                    DashboardSuggestionSection(overview: overview),
                    if (!hideStationOverview) ...[
                      const DashboardSectionTitle('Tổng quan cây xăng'),
                      DashboardStatCards(overview: overview),
                      DashboardSystemInventoryCard(overview: overview),
                      DashboardProvinceCard(overview: overview),
                    ],
                    if (overview.notes != null && overview.notes!.isNotEmpty) ...[
                      DashboardAlertBanner(
                        title: 'Thông báo từ máy chủ',
                        subtitle: overview.notes!.first,
                      ),
                      ...overview.notes!.skip(1).map(
                            (s) => DashboardInfoNoteCard(body: s),
                          ),
                    ],
                    const DashboardQuickActionGrid(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
