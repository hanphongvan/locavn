import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/stabilization_fund_models.dart';
import '../../data/stabilization_fund_service.dart';
import '../leader_theme.dart';
import '../stabilization_fund_money_format.dart';

void showStabilizationFundDetailSheet(
  BuildContext context, {
  required StabilizationFundDistributorRow row,
  required int reportMonth,
  required int reportYear,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => _StabilizationFundDetailBody(
      row: row,
      reportMonth: reportMonth,
      reportYear: reportYear,
    ),
  );
}

class _StabilizationFundDetailBody extends ConsumerStatefulWidget {
  const _StabilizationFundDetailBody({
    required this.row,
    required this.reportMonth,
    required this.reportYear,
  });

  final StabilizationFundDistributorRow row;
  final int reportMonth;
  final int reportYear;

  @override
  ConsumerState<_StabilizationFundDetailBody> createState() => _StabilizationFundDetailBodyState();
}

class _StabilizationFundDetailBodyState extends ConsumerState<_StabilizationFundDetailBody> {
  Future<StabilizationFundHistoryDto>? _historyFuture;
  var _historyStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_historyStarted) {
      return;
    }
    _historyStarted = true;
    _historyFuture = ref.read(stabilizationFundServiceProvider).getDistributorHistory(
          widget.row.distributorId,
          month: widget.reportMonth,
          year: widget.reportYear,
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = widget.row;
    final h = MediaQuery.sizeOf(context).height * 0.88;

    return SizedBox(
      height: h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    r.distributorName,
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: kStabilizationFundPrimary),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                if ((r.address ?? '').trim().isNotEmpty)
                  _kv('Địa chỉ', r.address!.trim(), t),
                _kv('Số dư quỹ', formatStabilizationFundMoney(r.balance), t),
                _kv('Tháng báo cáo', '${r.reportMonth.toString().padLeft(2, '0')}/${r.reportYear}', t),
                _kv('Số phát sinh tăng', formatStabilizationFundMoney(r.increaseAmount), t),
                _kv('Số phát sinh giảm', formatStabilizationFundMoney(r.decreaseAmount), t),
                _kv('Số dư cuối kỳ', formatStabilizationFundMoney(r.endingBalance), t),
                _kv('Trạng thái báo cáo', r.reportStatus, t),
                _kv('Ghi chú', (r.note ?? '').trim().isEmpty ? '—' : r.note!.trim(), t),
                const SizedBox(height: 20),
                Text(
                  'Lịch sử 6 tháng gần nhất',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: LeaderTheme.navy),
                ),
                const SizedBox(height: 12),
                FutureBuilder<StabilizationFundHistoryDto>(
                  future: _historyFuture,
                  builder: (context, snap) {
                    if (_historyFuture == null || snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                    }
                    if (snap.hasError) {
                      final msg = snap.error is ApiException
                          ? (snap.error! as ApiException).message
                          : snap.error.toString();
                      return Text(msg, style: t.bodyMedium?.copyWith(color: LeaderTheme.alert));
                    }
                    final data = snap.data;
                    if (data == null) {
                      return const SizedBox.shrink();
                    }
                    final items = data.items;
                    if (items.isEmpty) {
                      return Text('Chưa có lịch sử.', style: t.bodyMedium?.copyWith(color: LeaderTheme.muted));
                    }
                    return Column(
                      children: [
                        for (final h in items)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: LeaderTheme.cardDecoration(context: context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${h.month.toString().padLeft(2, '0')}/${h.year}',
                                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: kStabilizationFundPrimary),
                                ),
                                const SizedBox(height: 8),
                                _mini('Đầu kỳ', formatStabilizationFundMoney(h.beginningBalance), t),
                                _mini('Tăng', formatStabilizationFundMoney(h.increaseAmount), t),
                                _mini('Giảm', formatStabilizationFundMoney(h.decreaseAmount), t),
                                _mini('Cuối kỳ', formatStabilizationFundMoney(h.endingBalance), t),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _kv(String k, String v, TextTheme t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: t.labelLarge?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(v, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: LeaderTheme.navy)),
        ],
      ),
    );
  }

  static Widget _mini(String k, String v, TextTheme t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(k, style: t.bodySmall?.copyWith(color: LeaderTheme.muted))),
          Text(v, style: t.bodySmall?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
