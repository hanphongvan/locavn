import 'package:flutter_riverpod/flutter_riverpod.dart';

// Cross-feature imports — `bad_reports` ở đây "biết" tới các provider mà việc submit
// báo cáo vi phạm sẽ làm stale (dashboard tổng hợp tài khoản, list "báo cáo của tôi").
// Cùng pragmatic coupling như `StationReviewSubmitController` — gom logic invalidate
// vào 1 chỗ thay vì để mỗi caller nhớ.
import '../../../more/presentation/account/account_activity_providers.dart' show accountActivitySummaryProvider;
import '../../data/bad_reports_api.dart';
import '../my_bad_reports_providers.dart' show myBadReportsFirstPageProvider;

/// Submit-flow controller cho `ReportStationIssuePage` (`POST /api/bad-reports`).
///
/// `family<int?>` = stationId — `null` cho báo cáo chung không gắn trạm cụ thể.
/// AutoDispose: mỗi page instance có notifier riêng, dispose khi pop.
///
/// Sau khi submit thành công, controller chủ động `invalidate`:
/// - `myBadReportsFirstPageProvider` (list "Báo cáo của tôi" trong tab Tài khoản)
/// - `accountActivitySummaryProvider` (đếm số báo cáo trên dashboard tài khoản)
class BadReportSubmitController
    extends AutoDisposeFamilyAsyncNotifier<void, int?> {
  @override
  Future<void> build(int? stationId) async {
    // Idle ban đầu — `AsyncData(null)`.
  }

  Future<void> submit({
    required String content,
    List<String>? imageUrls,
  }) async {
    final stationId = arg;
    final api = ref.read(badReportsApiProvider);
    state = const AsyncLoading();
    try {
      await api.submit(
        stationId: stationId,
        content: content,
        imageUrls: imageUrls,
      );
      _invalidateRelated();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Cache stale sau khi báo cáo mới được tạo:
  /// - dashboard tài khoản (số báo cáo của tôi tăng lên)
  /// - list "Báo cáo của tôi" (entry mới ở trang đầu)
  void _invalidateRelated() {
    ref.invalidate(myBadReportsFirstPageProvider);
    ref.invalidate(accountActivitySummaryProvider);
  }
}

final badReportSubmitControllerProvider =
    AutoDisposeAsyncNotifierProviderFamily<
        BadReportSubmitController, void, int?>(
  BadReportSubmitController.new,
);
