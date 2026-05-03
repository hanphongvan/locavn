import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_filters.dart';
import 'map_providers.dart';

/// Horizontal chips for active province / district / keyword filters on the map.
class MapActiveFiltersStrip extends ConsumerWidget {
  const MapActiveFiltersStrip({super.key, required this.filters});

  final MapFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!filters.hasActiveStrip) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      surfaceTintColor: scheme.surfaceTint,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: SizedBox(
          height: 42,
          child: Theme(
            data: Theme.of(context).copyWith(
              chipTheme: Theme.of(context).chipTheme.copyWith(
                side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              children: [
                if (filters.hasActiveKeyword)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InputChip(
                      label: Text(
                        filters.keyword!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onDeleted: () {
                        ref.read(mapFiltersProvider.notifier).state = filters.copyWith(keyword: null);
                        mapClearCheapSpotlightMarker(ref);
                      },
                    ),
                  ),
                if (filters.provinceCode != null && filters.provinceCode!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InputChip(
                      label: Text(filters.provinceLabel ?? filters.provinceCode!),
                      onDeleted: () {
                        ref.read(mapFiltersProvider.notifier).state = filters.copyWith(
                          provinceCode: null,
                          districtCode: null,
                          provinceLabel: null,
                          districtLabel: null,
                        );
                        mapClearCheapSpotlightMarker(ref);
                      },
                    ),
                  ),
                if (filters.districtCode != null && filters.districtCode!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InputChip(
                      label: Text(filters.districtLabel ?? 'QH ${filters.districtCode}'),
                      onDeleted: () {
                        ref.read(mapFiltersProvider.notifier).state = filters.copyWith(
                          districtCode: null,
                          districtLabel: null,
                        );
                        mapClearCheapSpotlightMarker(ref);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
