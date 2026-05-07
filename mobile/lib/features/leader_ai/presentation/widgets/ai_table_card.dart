import 'package:flutter/material.dart';

import 'leader_ai_palette.dart';

/// Card hiển thị bảng dữ liệu trả về từ AI Gateway. Section 7 yêu cầu:
/// - Tối đa 20 row hiển thị, có nút "Xem thêm" mở rộng đến hết.
/// - Header row màu #EBF2FB.
/// - SingleChildScrollView ngang vì DataTable thường rộng hơn màn hình.
class AiTableCard extends StatefulWidget {
  const AiTableCard({super.key, required this.rows, this.initialLimit = 20});

  final List<Map<String, dynamic>> rows;
  final int initialLimit;

  @override
  State<AiTableCard> createState() => _AiTableCardState();
}

class _AiTableCardState extends State<AiTableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final allColumns = _collectColumns(widget.rows);
    final visible = _expanded
        ? widget.rows
        : widget.rows.take(widget.initialLimit).toList(growable: false);
    final hasMore = !_expanded && widget.rows.length > widget.initialLimit;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LeaderAiPalette.cardRadius),
        side: const BorderSide(color: LeaderAiPalette.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LeaderAiPalette.cardRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStatePropertyAll(LeaderAiPalette.softBlue),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: LeaderAiPalette.primaryNavy,
                  fontSize: 13,
                ),
                dataRowMaxHeight: 48,
                columns: [
                  for (final c in allColumns)
                    DataColumn(label: Text(_humanize(c))),
                ],
                rows: [
                  for (final row in visible)
                    DataRow(
                      cells: [
                        for (final c in allColumns)
                          DataCell(Text(_renderCell(row[c]))),
                      ],
                    ),
                ],
              ),
            ),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _expanded = true),
                    icon: const Icon(Icons.expand_more_rounded, size: 18),
                    label: Text(
                      'Xem thêm (${widget.rows.length - widget.initialLimit})',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: LeaderAiPalette.primaryNavy,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Lấy union các key — giữ thứ tự xuất hiện đầu tiên (tránh hash random).
  List<String> _collectColumns(List<Map<String, dynamic>> rows) {
    final out = <String>[];
    final seen = <String>{};
    for (final r in rows) {
      for (final k in r.keys) {
        if (seen.add(k)) out.add(k);
      }
    }
    return out;
  }

  /// "fuelType" → "Fuel Type" — đẹp hơn mà không cần i18n bảng cứng.
  String _humanize(String camel) {
    final buffer = StringBuffer();
    for (var i = 0; i < camel.length; i++) {
      final ch = camel[i];
      if (i > 0 && ch.toUpperCase() == ch && ch.toLowerCase() != ch) {
        buffer.write(' ');
      }
      buffer.write(i == 0 ? ch.toUpperCase() : ch);
    }
    return buffer.toString();
  }

  String _renderCell(Object? value) {
    if (value == null) return '—';
    if (value is num) return value.toString();
    if (value is bool) return value ? 'Có' : 'Không';
    return value.toString();
  }
}
