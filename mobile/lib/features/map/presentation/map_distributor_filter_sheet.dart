import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../stations/data/models/station_distributor.dart';
import 'map_providers.dart';
import 'map_screen_palette.dart';

/// Bottom sheet single-select doanh nghiệp đầu mối (CapDonViId=235).
/// Sau khi chọn → set `MapFilters.distributorId` + label → strip chip hiện trên bản đồ.
Future<void> showMapDistributorFilterSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _MapDistributorFilterSheet(),
  );
}

class _MapDistributorFilterSheet extends ConsumerStatefulWidget {
  const _MapDistributorFilterSheet();

  @override
  ConsumerState<_MapDistributorFilterSheet> createState() => _MapDistributorFilterSheetState();
}

class _MapDistributorFilterSheetState extends ConsumerState<_MapDistributorFilterSheet> {
  late int? _selectedId;
  late String? _selectedLabel;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final f = ref.read(mapFiltersProvider);
    _selectedId = f.distributorId;
    _selectedLabel = f.distributorLabel;
  }

  void _apply() {
    final f = ref.read(mapFiltersProvider);
    ref.read(mapFiltersProvider.notifier).state = f.copyWith(
      distributorId: _selectedId,
      distributorLabel: _selectedLabel,
    );
    Navigator.of(context).pop();
  }

  void _clearSelection() {
    setState(() {
      _selectedId = null;
      _selectedLabel = null;
    });
  }

  List<StationDistributor> _filtered(List<StationDistributor> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((d) => d.name.toLowerCase().contains(q)).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(mapDistributorsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Material(
        color: MapScreenPalette.filterSheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(MapScreenPalette.radiusLg)),
        child: Column(
          children: [
            _grabber(),
            _header(context),
            _searchField(),
            Expanded(
              child: async.when(
                data: (all) {
                  final list = _filtered(all);
                  if (list.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Không tìm thấy đầu mối phù hợp',
                          style: TextStyle(color: MapScreenPalette.filterTextSecondary),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _AllOption(
                          selected: _selectedId == null,
                          onTap: _clearSelection,
                          totalCount: all.fold<int>(0, (a, b) => a + b.stationCount),
                        );
                      }
                      final d = list[index - 1];
                      return _DistributorTile(
                        distributor: d,
                        selected: _selectedId == d.id,
                        onTap: () => setState(() {
                          _selectedId = d.id;
                          _selectedLabel = d.name;
                        }),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Không tải được danh sách đầu mối:\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: MapScreenPalette.danger),
                    ),
                  ),
                ),
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _grabber() => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 12, 8),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Lọc theo doanh nghiệp đầu mối',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: MapScreenPalette.filterTextPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: MapScreenPalette.filterTextSecondary),
              tooltip: 'Đóng',
            ),
          ],
        ),
      );

  Widget _searchField() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Tìm tên doanh nghiệp đầu mối...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm),
              borderSide: const BorderSide(color: MapScreenPalette.chipInactiveBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm),
              borderSide: const BorderSide(color: MapScreenPalette.chipInactiveBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm),
              borderSide: const BorderSide(color: MapScreenPalette.filterPrimary, width: 1.4),
            ),
          ),
        ),
      );

  Widget _footer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _clearSelection,
                style: OutlinedButton.styleFrom(
                  foregroundColor: MapScreenPalette.filterClearAction,
                  side: const BorderSide(color: MapScreenPalette.filterClearAction),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm)),
                ),
                child: const Text('Đặt lại', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: MapScreenPalette.filterPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm)),
                ),
                child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllOption extends StatelessWidget {
  const _AllOption({
    required this.selected,
    required this.onTap,
    required this.totalCount,
  });

  final bool selected;
  final VoidCallback onTap;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return _selectableTile(
      selected: selected,
      onTap: onTap,
      leading: const Icon(Icons.all_inclusive_rounded,
          color: MapScreenPalette.filterPrimary),
      title: 'Tất cả đầu mối',
      subtitle: totalCount > 0 ? '$totalCount trạm bán lẻ' : null,
    );
  }
}

class _DistributorTile extends StatelessWidget {
  const _DistributorTile({
    required this.distributor,
    required this.selected,
    required this.onTap,
  });

  final StationDistributor distributor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _selectableTile(
      selected: selected,
      onTap: onTap,
      leading: distributor.brandKey != null
          ? Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MapScreenPalette.filterChipSelectedBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                distributor.name.isNotEmpty ? distributor.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: MapScreenPalette.filterPrimary,
                ),
              ),
            )
          : const Icon(Icons.business_outlined,
              color: MapScreenPalette.filterTextSecondary),
      title: distributor.name,
      subtitle: '${distributor.stationCount} trạm',
    );
  }
}

Widget _selectableTile({
  required bool selected,
  required VoidCallback onTap,
  required Widget leading,
  required String title,
  String? subtitle,
}) {
  return Material(
    color: selected ? MapScreenPalette.filterChipSelectedBg : Colors.white,
    borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm),
          border: Border.all(
            color: selected
                ? MapScreenPalette.filterChipSelectedBorder
                : MapScreenPalette.chipInactiveBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 32, child: Center(child: leading)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? MapScreenPalette.filterChipSelectedText
                          : MapScreenPalette.filterTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: MapScreenPalette.filterTextSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 22,
              color: selected
                  ? MapScreenPalette.filterPrimary
                  : MapScreenPalette.filterTextSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}
