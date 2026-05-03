import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/reports_overview_dto.dart';
import '../dashboard_alert_banner.dart';
import '../dashboard_background.dart';
import '../dashboard_overview_cards.dart';
import '../dashboard_quick_action_grid.dart';
import '../dashboard_search_bar.dart';
import '../loca_dashboard_tokens.dart';
import '../../reports_providers.dart';
import 'citizen_dashboard_header.dart';
import 'citizen_dashboard_map_suggestions_provider.dart';
import 'citizen_dashboard_suggestions.dart';
import 'citizen_dashboard_vehicle_card.dart';

/// Citizen (`Loai == 5`) dashboard layout — same providers & [ReportsOverviewDto] as default shell.
class CitizenDashboardContent extends ConsumerWidget {
  const CitizenDashboardContent({
    super.key,
    required this.overview,
  });

  final ReportsOverviewDto overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> onRefresh() async {
      ref.invalidate(reportsOverviewProvider);
      ref.invalidate(citizenDashboardMapSuggestionsProvider);
      await ref.read(reportsOverviewProvider.future);
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
              const CitizenDashboardHeader(),
              const DashboardSearchBar(),
              const CitizenDashboardVehicleCard(),
              const CitizenDashboardSuggestions(),
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
  }
}
