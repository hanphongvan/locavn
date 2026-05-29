import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store_services/presentation/store_service_icon.dart';
import '../data/map_filters.dart';
import 'map_filter_footer.dart';
import 'map_providers.dart';
import 'map_screen_palette.dart';

/// Sheet nhanh chỉnh [mapFiltersProvider.selectedServiceCodes] (cùng logic bộ lọc bản đồ).
Future<void> showMapServicesQuickFilterSheet(BuildContext context, WidgetRef ref) {
  final initial = List<String>.from(ref.read(mapFiltersProvider).selectedServiceCodes);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _MapServicesQuickSheet(initialSelected: initial, hostRef: ref);
    },
  );
}

class _MapServicesQuickSheet extends ConsumerStatefulWidget {
  const _MapServicesQuickSheet({
    required this.initialSelected,
    required this.hostRef,
  });

  final List<String> initialSelected;
  final WidgetRef hostRef;

  @override
  ConsumerState<_MapServicesQuickSheet> createState() => _MapServicesQuickSheetState();
}

class _MapServicesQuickSheetState extends ConsumerState<_MapServicesQuickSheet> {
  late Set<String> _draft;

  @override
  void initState() {
    super.initState();
    _draft = {for (final c in widget.initialSelected) c.toUpperCase()};
  }

  void _apply() {
    final f = widget.hostRef.read(mapFiltersProvider);
    final next = f.copyWith(
      selectedServiceCodes: MapFilters.normalizeSelectedServices(_draft),
    );
    widget.hostRef.read(mapFiltersProvider.notifier).state = next;
    mapClearCheapSpotlightMarker(widget.hostRef);
    Navigator.of(context).pop();
  }

  void _resetDraft() {
    setState(() {
      _draft.clear();
      _draft.addAll(widget.initialSelected.map((c) => c.toUpperCase()));
    });
  }

  void _clearServices() {
    setState(_draft.clear);
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(stationStoreServiceCatalogProvider);
    final screenH = MediaQuery.sizeOf(context).height;
    final sheetH = (screenH * 0.58).clamp(320.0, screenH * 0.75);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: MapScreenPalette.cardWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: sheetH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MapScreenPalette.filterChipBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dịch vụ',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: MapScreenPalette.filterTextPrimary,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: _draft.isEmpty ? null : _clearServices,
                      child: Text(
                        'Xóa dịch vụ',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: MapScreenPalette.filterClearAction,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: catalogAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text(
                      'Không tải danh mục dịch vụ: $e',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                    data: (catalog) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in catalog)
                          FilterChip(
                            avatar: Icon(
                              storeServiceIconForCode(item.serviceCode, item.iconKey),
                              size: 18,
                              color: MapScreenPalette.filterTextPrimary,
                            ),
                            label: Text(item.defaultDisplayName),
                            selected: _draft.contains(item.serviceCode.toUpperCase()),
                            selectedColor: MapScreenPalette.primaryBlue.withValues(alpha: 0.2),
                            checkmarkColor: MapScreenPalette.primaryBlue,
                            onSelected: (_) {
                              setState(() {
                                final u = item.serviceCode.toUpperCase();
                                if (_draft.contains(u)) {
                                  _draft.remove(u);
                                } else {
                                  _draft.add(u);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              MapFilterFooter(
                onApply: _apply,
                onReset: _resetDraft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
