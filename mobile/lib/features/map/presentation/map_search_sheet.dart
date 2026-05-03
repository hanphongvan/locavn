import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_console_log.dart';
import '../../../core/network/api_exception.dart';
import '../../stations/data/models/station_list_item.dart';
import '../../stations/data/stations_api.dart';

/// Search via GET /api/stations; returns selected [StationListItem] or null.
Future<StationListItem?> showMapStationSearchSheet(BuildContext context) {
  return showModalBottomSheet<StationListItem>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _MapSearchSheetBody(),
  );
}

class _MapSearchSheetBody extends ConsumerStatefulWidget {
  const _MapSearchSheetBody();

  @override
  ConsumerState<_MapSearchSheetBody> createState() => _MapSearchSheetBodyState();
}

class _MapSearchSheetBodyState extends ConsumerState<_MapSearchSheetBody> {
  final _controller = TextEditingController();
  List<StationListItem> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _error = 'Nhập từ khóa (tên, địa chỉ, giấy phép…).';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(stationsApiProvider);
      final page = await api.listStations(keyword: q, skip: 0, take: 30);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = page.items;
        if (_results.isEmpty) {
          _error = 'Không tìm thấy cây xăng phù hợp.';
        }
      });
    } catch (e, st) {
      logAppError('MapSearchSheet._runSearch', e, st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : e.toString();
        _results = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Tìm cây xăng…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _runSearch(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tìm',
                    onPressed: _loading ? null : _runSearch,
                    icon: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: Theme.of(context).textTheme.bodySmall),
              ),
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = _results[i];
                  final sub = s.addressLine?.trim();
                  return ListTile(
                    title: Text(s.stationName),
                    subtitle: sub != null && sub.isNotEmpty ? Text(sub) : Text('Mã: ${s.stationCode}'),
                    onTap: () => Navigator.of(context).pop(s),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
