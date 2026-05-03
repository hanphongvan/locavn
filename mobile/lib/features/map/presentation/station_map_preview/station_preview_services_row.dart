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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final services = detail?.storeServices;
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
                    storeServiceIconData(s.iconKey),
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

    final codes = station.activeServiceCodes;
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
                  storeServiceIconData(_iconKeyForCode(code)),
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
