import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/portal_loai.dart';
import '../../geography/presentation/geography_providers.dart';
import '../../store_services/presentation/store_service_icon.dart';
import '../data/map_filters.dart';
import 'map_cheapest_station.dart';
import 'map_filter_chip_group.dart';
import 'map_filter_filter_section.dart';
import 'map_filter_footer.dart';
import 'map_filter_price_range_slider.dart';
import 'map_providers.dart';
import 'map_screen_palette.dart';
import 'map_top_rated_station.dart';

/// Sheet chỉnh [mapFiltersProvider]. Tải lại API khi đổi tỉnh/huyện/từ khóa/trạng thái;
/// chip loại đơn vị / nhiên liệu / giá lọc client sau khi tải — chỉ cập nhật khi bấm **Áp dụng**.
Future<void> showMapFilterSheet(BuildContext context, WidgetRef ref) {
  final initial = ref.read(mapFiltersProvider);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _MapFilterSheetBody(initial: initial, mapHostContext: context);
    },
  );
}

class _MapFilterSheetBody extends ConsumerStatefulWidget {
  const _MapFilterSheetBody({
    required this.initial,
    required this.mapHostContext,
  });

  final MapFilters initial;
  final BuildContext mapHostContext;

  @override
  ConsumerState<_MapFilterSheetBody> createState() => _MapFilterSheetBodyState();
}

class _MapFilterSheetBodyState extends ConsumerState<_MapFilterSheetBody> {
  late final TextEditingController _keywordCtrl;
  String? _provinceCode;
  String? _provinceLabel;
  String? _districtCode;
  String? _districtLabel;
  late String _statusChoice;
  late MapUnitTypeFilter _unitType;
  late MapFuelTypeFilter _fuelType;
  late MapRatingFilter _ratingFilter;
  late int _priceMinDong;
  late int _priceMaxDong;
  late Set<String> _selectedServiceCodes;
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _keywordCtrl = TextEditingController(text: f.keyword ?? '');
    _provinceCode = f.provinceCode;
    _provinceLabel = f.provinceLabel;
    _districtCode = f.districtCode;
    _districtLabel = f.districtLabel;
    final s = f.status?.trim().toLowerCase();
    _statusChoice = (s == 'open' || s == 'closed') ? s! : 'all';
    _unitType = f.unitType;
    _fuelType = f.fuelType;
    if (ref.read(portalSessionScopeProvider)?.loai == PortalLoai.leader &&
        _fuelType == MapFuelTypeFilter.lpg) {
      _fuelType = MapFuelTypeFilter.all;
    }
    _ratingFilter = f.ratingFilter;
    _priceMinDong = f.priceMinDong;
    _priceMaxDong = f.priceMaxDong;
    _selectedServiceCodes = {for (final c in f.selectedServiceCodes) c.toUpperCase()};
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  MapFilters _buildDraftFilters() {
    final raw = _keywordCtrl.text.trim();
    return MapFilters(
      keyword: raw.isEmpty ? null : raw,
      provinceCode: _provinceCode,
      districtCode: _districtCode,
      provinceLabel: _provinceLabel,
      districtLabel: _districtLabel,
      status: _statusChoice == 'all' ? null : _statusChoice,
      unitType: _unitType,
      fuelType: _fuelType,
      ratingFilter: _ratingFilter,
      priceMinDong: _priceMinDong,
      priceMaxDong: _priceMaxDong,
      selectedServiceCodes: MapFilters.normalizeSelectedServices(_selectedServiceCodes),
    );
  }

  void _apply() {
    final draft = _buildDraftFilters();
    final kw = draft.keyword?.trim() ?? '';
    if (kw.length > MapFilters.maxKeywordLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Từ khóa tối đa ${MapFilters.maxKeywordLength} ký tự (theo API).')),
      );
      return;
    }
    ref.read(mapFiltersProvider.notifier).state = draft;
    mapClearCheapSpotlightMarker(ref);
    Navigator.of(context).pop();
  }

  void _clearDraftToDefaults() {
    _keywordCtrl.clear();
    setState(() {
      _provinceCode = null;
      _provinceLabel = null;
      _districtCode = null;
      _districtLabel = null;
      _statusChoice = 'all';
      _unitType = MapUnitTypeFilter.all;
      _fuelType = MapFuelTypeFilter.all;
      _ratingFilter = MapRatingFilter.all;
      _priceMinDong = MapFilters.priceSliderMinDong;
      _priceMaxDong = MapFilters.priceSliderMaxDong;
      _selectedServiceCodes.clear();
    });
  }

  void _resetDraftToInitial() {
    final f = widget.initial;
    _keywordCtrl.text = f.keyword ?? '';
    setState(() {
      _provinceCode = f.provinceCode;
      _provinceLabel = f.provinceLabel;
      _districtCode = f.districtCode;
      _districtLabel = f.districtLabel;
      final s = f.status?.trim().toLowerCase();
      _statusChoice = (s == 'open' || s == 'closed') ? s! : 'all';
      _unitType = f.unitType;
      _fuelType = f.fuelType;
      if (ref.read(portalSessionScopeProvider)?.loai == PortalLoai.leader &&
          _fuelType == MapFuelTypeFilter.lpg) {
        _fuelType = MapFuelTypeFilter.all;
      }
      _ratingFilter = f.ratingFilter;
      _priceMinDong = f.priceMinDong;
      _priceMaxDong = f.priceMaxDong;
      _selectedServiceCodes
        ..clear()
        ..addAll(f.selectedServiceCodes.map((c) => c.toUpperCase()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final hideGasFuel = ref.watch(portalSessionScopeProvider)?.loai == PortalLoai.leader;
    final provincesAsync = ref.watch(geographyProvincesProvider);
    final districtsAsync = ref.watch(geographyDistrictsProvider(_provinceCode ?? ''));
    final catalogAsync = ref.watch(stationStoreServiceCatalogProvider);
    final screenH = MediaQuery.sizeOf(context).height;
    final summary = _buildDraftFilters().compactSummaryLabel;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: screenH * 0.94,
        child: NotificationListener<DraggableScrollableNotification>(
          onNotification: (n) {
            final collapsed = n.extent < 0.38;
            if (collapsed != _collapsed) {
              setState(() => _collapsed = collapsed);
            }
            return false;
          },
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.56,
            minChildSize: 0.28,
            maxChildSize: 0.94,
            builder: (context, scrollController) {
              return DecoratedBox(
                decoration: const BoxDecoration(
                  color: MapScreenPalette.filterSheetBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Material(
                    color: MapScreenPalette.cardWhite,
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
                                  'Bộ lọc bản đồ',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: MapScreenPalette.filterTextPrimary,
                                      ),
                                ),
                              ),
                              TextButton(
                                onPressed: _clearDraftToDefaults,
                                child: Text(
                                  'Xóa lọc',
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
                          child: ListView(
                            controller: scrollController,
                            physics: _collapsed ? const NeverScrollableScrollPhysics() : null,
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                            children: [
                              if (!_collapsed) ...[
                                FilterSection(
                                  title: 'Loại đơn vị',
                                  child: FilterChipGroup<MapUnitTypeFilter>(
                                    options: const [
                                      FilterChipOption(value: MapUnitTypeFilter.all, label: 'Tất cả'),
                                      FilterChipOption(value: MapUnitTypeFilter.wholesale, label: 'Doanh nghiệp đầu mối'),
                                      FilterChipOption(value: MapUnitTypeFilter.retail, label: 'Cửa hàng bán lẻ'),
                                    ],
                                    selected: _unitType,
                                    onSelected: (v) => setState(() => _unitType = v),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                FilterSection(
                                  title: 'Loại nhiên liệu',
                                  subtitle: hideGasFuel ? 'Vai trò Lãnh đạo: chỉ Xăng và Dầu.' : null,
                                  child: FilterChipGroup<MapFuelTypeFilter>(
                                    options: [
                                      const FilterChipOption(value: MapFuelTypeFilter.all, label: 'Tất cả'),
                                      const FilterChipOption(value: MapFuelTypeFilter.petrol, label: 'Xăng'),
                                      const FilterChipOption(value: MapFuelTypeFilter.diesel, label: 'Dầu'),
                                      if (!hideGasFuel)
                                        const FilterChipOption(value: MapFuelTypeFilter.lpg, label: 'Khí'),
                                    ],
                                    selected:
                                        hideGasFuel && _fuelType == MapFuelTypeFilter.lpg
                                            ? MapFuelTypeFilter.all
                                            : _fuelType,
                                    onSelected: (v) {
                                      if (hideGasFuel && v == MapFuelTypeFilter.lpg) {
                                        return;
                                      }
                                      setState(() => _fuelType = v);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 22),
                                FilterSection(
                                  title: 'Dịch vụ',
                                  child: catalogAsync.when(
                                    loading: () => const LinearProgressIndicator(),
                                    error: (e, _) => Text(
                                      'Không tải danh mục dịch vụ: $e',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: MapScreenPalette.filterTextSecondary,
                                          ),
                                    ),
                                    data: (catalog) => Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final item in catalog)
                                          FilterChip(
                                            avatar: Icon(
                                              storeServiceIconData(item.iconKey),
                                              size: 18,
                                              color: MapScreenPalette.filterTextPrimary,
                                            ),
                                            label: Text(item.defaultDisplayName),
                                            selected: _selectedServiceCodes.contains(
                                              item.serviceCode.toUpperCase(),
                                            ),
                                            selectedColor: MapScreenPalette.primaryBlue.withValues(alpha: 0.2),
                                            checkmarkColor: MapScreenPalette.primaryBlue,
                                            onSelected: (_) {
                                              setState(() {
                                                final u = item.serviceCode.toUpperCase();
                                                if (_selectedServiceCodes.contains(u)) {
                                                  _selectedServiceCodes.remove(u);
                                                } else {
                                                  _selectedServiceCodes.add(u);
                                                }
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                FilterSection(
                                  title: 'Trạng thái',
                                  child: FilterChipGroup<String>(
                                    options: const [
                                      FilterChipOption(value: 'all', label: 'Tất cả'),
                                      FilterChipOption(value: 'open', label: 'Đang mở cửa'),
                                      FilterChipOption(value: 'closed', label: 'Đóng cửa'),
                                    ],
                                    selected: _statusChoice,
                                    onSelected: (v) => setState(() => _statusChoice = v),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                FilterSection(
                                  title: 'Khoảng giá',
                                  subtitle: 'Theo đơn giá RON95 hoặc diesel trên bản đồ (đồng/lít).',
                                  child: MapFilterPriceRangeSlider(
                                    minDong: _priceMinDong,
                                    maxDong: _priceMaxDong,
                                    onChanged: (a, b) => setState(() {
                                      _priceMinDong = a;
                                      _priceMaxDong = b;
                                    }),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                FilterSection(
                                  title: 'Đánh giá',
                                  child: FilterChipGroup<MapRatingFilter>(
                                    options: const [
                                      FilterChipOption(value: MapRatingFilter.all, label: 'Tất cả'),
                                      FilterChipOption(value: MapRatingFilter.min4, label: '≥ 4 sao'),
                                      FilterChipOption(value: MapRatingFilter.min3, label: '≥ 3 sao'),
                                    ],
                                    selected: _ratingFilter,
                                    onSelected: (v) => setState(() => _ratingFilter = v),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  'Địa điểm & từ khóa',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: MapScreenPalette.filterTextPrimary,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _keywordCtrl,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: 'Từ khóa',
                                    hintText: 'Tên, địa chỉ, giấy phép…',
                                    filled: true,
                                    fillColor: MapScreenPalette.filterSheetBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: MapScreenPalette.filterChipBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: MapScreenPalette.filterChipBorder),
                                    ),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  maxLength: MapFilters.maxKeywordLength,
                                ),
                                const SizedBox(height: 14),
                                provincesAsync.when(
                                  loading: () => const LinearProgressIndicator(),
                                  error: (e, _) => Text('Không tải được tỉnh: $e'),
                                  data: (provinces) {
                                    return InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Tỉnh/Thành phố',
                                        filled: true,
                                        fillColor: MapScreenPalette.filterSheetBackground,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String?>(
                                          value: _provinceCode,
                                          isExpanded: true,
                                          hint: const Text('Chọn tỉnh'),
                                          items: [
                                            const DropdownMenuItem<String?>(
                                              value: null,
                                              child: Text('Toàn quốc'),
                                            ),
                                            ...provinces.map(
                                              (p) => DropdownMenuItem<String?>(
                                                value: p.code,
                                                child: Text(p.name),
                                              ),
                                            ),
                                          ],
                                          onChanged: (code) {
                                            setState(() {
                                              _provinceCode = code;
                                              _provinceLabel = null;
                                              if (code != null) {
                                                for (final p in provinces) {
                                                  if (p.code == code) {
                                                    _provinceLabel = p.name;
                                                    break;
                                                  }
                                                }
                                              }
                                              _districtCode = null;
                                              _districtLabel = null;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                districtsAsync.when(
                                  loading: () => const SizedBox(
                                    height: 4,
                                    child: LinearProgressIndicator(),
                                  ),
                                  error: (e, _) => Text('Quận/huyện: $e', style: Theme.of(context).textTheme.bodySmall),
                                  data: (districts) {
                                    if (_provinceCode == null || _provinceCode!.isEmpty) {
                                      return Text(
                                        'Chọn tỉnh để lọc quận/huyện.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: MapScreenPalette.filterTextSecondary,
                                            ),
                                      );
                                    }
                                    return InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Quận/Huyện',
                                        filled: true,
                                        fillColor: MapScreenPalette.filterSheetBackground,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String?>(
                                          value: _districtCode,
                                          isExpanded: true,
                                          hint: const Text('Chọn quận/huyện'),
                                          items: [
                                            const DropdownMenuItem<String?>(
                                              value: null,
                                              child: Text('Tất cả quận/huyện trong tỉnh'),
                                            ),
                                            ...districts.map(
                                              (d) => DropdownMenuItem<String?>(
                                                value: d.districtCode,
                                                child: Text(d.districtName ?? 'Mã ${d.districtCode}'),
                                              ),
                                            ),
                                          ],
                                          onChanged: (code) {
                                            setState(() {
                                              _districtCode = code;
                                              _districtLabel = null;
                                              if (code != null) {
                                                for (final d in districts) {
                                                  if (d.districtCode == code) {
                                                    _districtLabel = d.districtName ?? 'Mã $code';
                                                    break;
                                                  }
                                                }
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  'Khám phá nhanh',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: MapScreenPalette.filterTextPrimary,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.local_gas_station_outlined, size: 18),
                                        label: const Text('RON 95'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          unawaited(
                                            presentCheapestPetrolStationForFuel(
                                              widget.mapHostContext,
                                              ref,
                                              CheapestFuelQuery.ron95,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.oil_barrel_outlined, size: 18),
                                        label: const Text('Diesel'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          unawaited(
                                            presentCheapestPetrolStationForFuel(
                                              widget.mapHostContext,
                                              ref,
                                              CheapestFuelQuery.diesel,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.star_rate_rounded, size: 20),
                                  label: const Text('Cây xăng đánh giá cao nhất'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    unawaited(presentTopRatedPetrolStation(widget.mapHostContext, ref));
                                  },
                                ),
                                const SizedBox(height: 12),
                              ] else
                                SizedBox(
                                  height: screenH * 0.18,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Text(
                                        summary,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: MapScreenPalette.filterPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        MapFilterFooter(
                          onApply: _apply,
                          onReset: _resetDraftToInitial,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
