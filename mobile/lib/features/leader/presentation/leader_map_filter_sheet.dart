import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../map/presentation/map_screen_palette.dart';
import '../../reports/presentation/dashboard/loca_dashboard_tokens.dart';
import '../data/leader_map_ui_state.dart';
import 'leader_map_ui_provider.dart';

Future<void> showLeaderMapFilterSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MapScreenPalette.filterSheetBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (context, ref2, _) {
          final ui = ref2.watch(leaderMapUiProvider);
          final t = Theme.of(context).textTheme;

          Widget sectionTitle(String s) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  s,
                  style: t.titleSmall?.copyWith(color: MapScreenPalette.filterTextPrimary, fontWeight: FontWeight.w800),
                ),
              );

          void set(LeaderMapUiState next) => ref2.read(leaderMapUiProvider.notifier).state = next;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      decoration: BoxDecoration(
                        color: MapScreenPalette.filterTextSecondary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Bộ lọc bản đồ',
                      style: t.titleLarge?.copyWith(color: MapScreenPalette.filterTextPrimary, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Text(
                      'Bật/tắt lớp đầu mối và cửa hàng trên thanh icon phía trên bản đồ.',
                      style: t.bodySmall?.copyWith(color: MapScreenPalette.filterTextSecondary, height: 1.35),
                    ),
                  ),
                  sectionTitle('Loại nhiên liệu'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Xăng'),
                          selected: ui.fuel == LeaderMapFuelFilter.xang,
                          selectedColor: MapScreenPalette.filterChipSelectedBg,
                          checkmarkColor: MapScreenPalette.filterPrimary,
                          onSelected: (_) => set(ui.copyWith(fuel: LeaderMapFuelFilter.xang)),
                        ),
                        ChoiceChip(
                          label: const Text('Dầu'),
                          selected: ui.fuel == LeaderMapFuelFilter.dau,
                          selectedColor: MapScreenPalette.filterChipSelectedBg,
                          checkmarkColor: MapScreenPalette.filterPrimary,
                          onSelected: (_) => set(ui.copyWith(fuel: LeaderMapFuelFilter.dau)),
                        ),
                      ],
                    ),
                  ),
                  sectionTitle('Trạng thái tồn'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Tất cả'),
                          selected: ui.coverage == LeaderStockCoverageBand.all,
                          selectedColor: MapScreenPalette.filterChipSelectedBg,
                          checkmarkColor: MapScreenPalette.filterPrimary,
                          onSelected: (_) => set(ui.copyWith(coverage: LeaderStockCoverageBand.all)),
                        ),
                        ChoiceChip(
                          label: const Text('An toàn (>10 ngày)'),
                          selected: ui.coverage == LeaderStockCoverageBand.safe,
                          selectedColor: MapScreenPalette.filterChipSelectedBg,
                          checkmarkColor: MapScreenPalette.filterPrimary,
                          onSelected: (_) => set(ui.copyWith(coverage: LeaderStockCoverageBand.safe)),
                        ),
                        ChoiceChip(
                          label: const Text('Cảnh báo (5–10 ngày)'),
                          selected: ui.coverage == LeaderStockCoverageBand.warn,
                          selectedColor: MapScreenPalette.filterChipSelectedBg,
                          checkmarkColor: MapScreenPalette.filterPrimary,
                          onSelected: (_) => set(ui.copyWith(coverage: LeaderStockCoverageBand.warn)),
                        ),
                        ChoiceChip(
                          label: const Text('Nguy cơ (<5 ngày)'),
                          selected: ui.coverage == LeaderStockCoverageBand.risk,
                          selectedColor: MapScreenPalette.filterChipSelectedBg,
                          checkmarkColor: MapScreenPalette.filterPrimary,
                          onSelected: (_) => set(ui.copyWith(coverage: LeaderStockCoverageBand.risk)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: LocaDashboardTokens.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
