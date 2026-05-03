import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/async_value_body.dart';
import '../data/inventory_map_providers.dart';
import '../data/models/inventory_map_response.dart';
import '../map/inventory_stock_map_google_view.dart';
import '../map/inventory_stock_map_pins_from_api.dart';
import 'inventory_stock_map_map_controls.dart';
import 'inventory_stock_map_station_detail_sheet.dart';

/// Map-first shell: Google Map + API-driven stock markers by fuel group.
class InventoryStockMapShellPage extends ConsumerWidget {
  const InventoryStockMapShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(inventoryMapSelectedGroupProvider);
    final async = ref.watch(inventoryMapForSelectedGroupProvider);

    final theme = Theme.of(context);
    final canPop = GoRouter.of(context).canPop();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Quay lại',
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          'Bản đồ tồn kho',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AsyncValueBody<InventoryMapResponse>(
              value: async,
              errorLogLabel: 'Bản đồ tồn kho (inventoryMapForSelectedGroupProvider)',
              loadingLabel: 'Đang tải dữ liệu tồn kho',
              emptyMessage: 'Không có trạm nào trong nhóm này.',
              isEmpty: (data) => data.stations.isEmpty,
              onRetry: () => ref.invalidate(inventoryMapForSelectedGroupProvider),
              dataBuilder: (data) {
                final plotted = pinsFromInventoryMapStations(data.stations);
                if (plotted.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
                      child: Text(
                        'Không có trạm nào có tọa độ và trạng thái tồn kho hợp lệ cho nhóm đã chọn.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  );
                }
                return InventoryStockMapGoogleView(
                  pins: plotted,
                  markerLayerKey: ValueKey<String>(group),
                  onMarkerTap: (pin) {
                    showInventoryMapStationDetailSheet(context, pin);
                  },
                );
              },
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            top: 8,
            child: InventoryStockMapMapControls(
              selectedGroup: group,
              onGroupSelected: (code) {
                ref.read(inventoryMapSelectedGroupProvider.notifier).state = code;
              },
            ),
          ),
        ],
      ),
    );
  }
}
