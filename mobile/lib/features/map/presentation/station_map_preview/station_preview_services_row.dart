import 'package:flutter/material.dart';

import '../../../station_detail/presentation/station_detail_shell_theme.dart';
import '../../../stations/data/models/station_detail_dto.dart';
import '../../../stations/data/models/station_map_item.dart';
import '../../../store_services/data/models/store_service_catalog_item.dart';
import '../../../store_services/presentation/store_service_icon.dart';

/// Services from detail when loaded; otherwise active codes from the map row + catalog labels.
class StationPreviewServicesRow extends StatelessWidget {
  const StationPreviewServicesRow({
    super.key,
    required this.station,
    this.detail,
    this.catalog,
  });

  final StationMapItem station;
  final StationDetailDto? detail;
  final List<StoreServiceCatalogItem>? catalog;

  String _labelForCode(String code) {
    final u = code.toUpperCase();
    final c = catalog;
    if (c != null) {
      for (final item in c) {
        if (item.serviceCode.toUpperCase() == u) return item.defaultDisplayName;
      }
    }
    return code;
  }

  String? _iconKeyForCode(String code) {
    final u = code.toUpperCase();
    final c = catalog;
    if (c == null) return null;
    for (final item in c) {
      if (item.serviceCode.toUpperCase() == u) return item.iconKey;
    }
    return null;
  }

  /// Service code là nhiên liệu (E5*/E10*/DIESEL*/RON*) — đã hiển thị ở section
  /// "Giá xăng dầu" / list giá → loại khỏi section "Dịch vụ".
  static bool _isFuelCode(String code) {
    final u = code.trim().toUpperCase();
    return u.startsWith('E5')
        || u.startsWith('E10')
        || u.startsWith('DIESEL')
        || u.startsWith('RON');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Path A: detail loaded — backend V2 đã filter fuel codes; vẫn filter client-side
    // defensively phòng V1 endpoint hoặc edge case.
    final services = detail?.storeServices
        ?.where((s) => !_isFuelCode(s.serviceCode))
        .toList();
    if (services != null && services.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dịch vụ',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: StationDetailShellTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in services)
                Chip(
                  avatar: Icon(
                    storeServiceIconForCode(s.serviceCode, s.iconKey),
                    size: 18,
                    color: s.isActive
                        ? StationDetailShellTheme.primary
                        : StationDetailShellTheme.textSecondary,
                  ),
                  label: Text(
                    s.displayName,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: s.isActive
                          ? StationDetailShellTheme.textPrimary
                          : StationDetailShellTheme.textSecondary,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      );
    }

    // Path B: chưa có detail — dùng activeServiceCodes từ SP map V2 (Fuels column).
    // Fuels include mọi service active gồm cả nhiên liệu → filter ra E5*/E10*/DIESEL*/RON*.
    final codes = station.activeServiceCodes.where((c) => !_isFuelCode(c)).toList();
    if (codes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dịch vụ',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: StationDetailShellTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final code in codes)
              Chip(
                avatar: Icon(
                  storeServiceIconForCode(code, _iconKeyForCode(code)),
                  size: 18,
                  color: StationDetailShellTheme.primary,
                ),
                label: Text(
                  _labelForCode(code),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: StationDetailShellTheme.textPrimary,
                  ),
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
      ],
    );
  }
}
