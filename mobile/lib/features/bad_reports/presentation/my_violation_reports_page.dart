import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/logging/app_console_log.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../more/presentation/account/account_palette.dart';
import '../data/models/my_bad_reports_models.dart';
import 'my_bad_reports_providers.dart';

String _statusLabelVi(int status) {
  switch (status) {
    case 1:
      return 'Đang xem xét';
    case 2:
      return 'Đã xử lý';
    case 0:
    default:
      return 'Chờ tiếp nhận';
  }
}

Color _statusColor(int status) {
  switch (status) {
    case 2:
      return const Color(0xFF2E7D32);
    case 1:
      return const Color(0xFFE65100);
    case 0:
    default:
      return AccountPalette.textSecondary;
  }
}

/// **Báo cáo của tôi** — danh sách báo vi phạm cây xăng (`GET /api/my-bad-reports`).
class MyViolationReportsPage extends ConsumerWidget {
  const MyViolationReportsPage({super.key});

  void _showDetail(BuildContext context, MyBadReportListItem item) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt.toLocal());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: AccountPalette.cardWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AccountPalette.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Text(
                item.stationName ?? (item.stationId != null ? 'Cây xăng #${item.stationId}' : 'Không gắn cây xăng'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AccountPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AccountPalette.textSecondary.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(item.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusLabelVi(item.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(item.status),
                  ),
                ),
              ),
              if (item.imageCount > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.image_outlined, size: 18, color: AccountPalette.textSecondary.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Text(
                      '${item.imageCount} ảnh đính kèm',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AccountPalette.textSecondary.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Nội dung gửi cơ quan quản lý',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AccountPalette.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                item.content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AccountPalette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBadReportsFirstPageProvider);

    return Scaffold(
      backgroundColor: AccountPalette.background,
      appBar: AppBar(
        title: const Text('Báo cáo của tôi'),
        backgroundColor: AccountPalette.cardWhite,
        foregroundColor: AccountPalette.textPrimary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: async.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AccountPalette.primaryBlue),
          ),
        ),
        error: (e, st) {
          logAppError('myBadReportsFirstPageProvider', e, st);
          final message = e is ApiException ? e.message : e.toString();
          return AppErrorState(
            message: message,
            onRetry: () => ref.invalidate(myBadReportsFirstPageProvider),
          );
        },
        data: (page) {
          if (page.items.isEmpty) {
            return RefreshIndicator(
              color: AccountPalette.primaryBlue,
              onRefresh: () async {
                ref.invalidate(myBadReportsFirstPageProvider);
                await ref.read(myBadReportsFirstPageProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 22),
                    decoration: BoxDecoration(
                      color: AccountPalette.cardWhite,
                      borderRadius: BorderRadius.circular(AccountPalette.radiusLg),
                      border: Border.all(color: AccountPalette.border.withValues(alpha: 0.85)),
                      boxShadow: AccountPalette.cardShadow(context),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 56,
                          color: AccountPalette.primaryBlue.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có báo vi phạm',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AccountPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Khi bạn gửi báo cáo từ bản đồ hoặc chi tiết cây xăng (đã đăng nhập), danh sách sẽ hiển thị tại đây.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: AccountPalette.textSecondary.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AccountPalette.primaryBlue,
            onRefresh: () async {
              ref.invalidate(myBadReportsFirstPageProvider);
              await ref.read(myBadReportsFirstPageProvider.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: page.items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                    child: Text(
                      'Báo vi phạm gửi cơ quan quản lý (${page.totalCount})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AccountPalette.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  );
                }
                final item = page.items[index - 1];
                final title = item.stationName ??
                    (item.stationId != null ? 'Cây xăng #${item.stationId}' : 'Không gắn cây xăng');
                final dateStr = DateFormat('dd/MM/yyyy · HH:mm').format(item.createdAt.toLocal());
                return Material(
                  color: AccountPalette.cardWhite,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(AccountPalette.radiusMd),
                  child: InkWell(
                    onTap: () => _showDetail(context, item),
                    borderRadius: BorderRadius.circular(AccountPalette.radiusMd),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AccountPalette.radiusMd),
                        border: Border.all(color: AccountPalette.border.withValues(alpha: 0.9)),
                        boxShadow: AccountPalette.cardShadow(context),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AccountPalette.primaryBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.report_problem_outlined,
                              color: AccountPalette.primaryBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    color: AccountPalette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AccountPalette.textSecondary.withValues(alpha: 0.92),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                    color: AccountPalette.textPrimary.withValues(alpha: 0.88),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(item.status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _statusLabelVi(item.status),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _statusColor(item.status),
                                        ),
                                      ),
                                    ),
                                    if (item.imageCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AccountPalette.background,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AccountPalette.border.withValues(alpha: 0.7),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.image_outlined,
                                              size: 14,
                                              color: AccountPalette.textSecondary.withValues(alpha: 0.9),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${item.imageCount}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AccountPalette.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AccountPalette.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
