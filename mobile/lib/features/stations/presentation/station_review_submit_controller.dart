import 'package:flutter_riverpod/flutter_riverpod.dart';

// Cross-feature imports — `stations` ở đây "biết" tới các provider mà việc submit
// review sẽ làm stale (rating summary của station, dashboard tổng hợp tài khoản,
// list review của tôi). Đây là pragmatic coupling: 3 callers của compose sheet
// trước đây đã trùng lặp logic invalidate này; gom lại 1 chỗ vẫn tốt hơn.
import '../../more/presentation/account/account_activity_providers.dart' show accountActivitySummaryProvider;
import '../../my_reviews/presentation/my_station_reviews_providers.dart' show myStationReviewsFirstPageProvider;
import '../../station_detail/presentation/station_detail_providers.dart'
    show stationRatingSummaryProvider, stationReviewListBumpProvider;
import '../data/stations_api.dart';

/// Submit-flow controller cho compose review (`POST /api/stations/{id}/reviews`).
///
/// `family<int>` = stationId — cho phép 2 page mở compose sheet cho 2 trạm khác
/// nhau cùng lúc mà state submit không lẫn (mỗi instance autoDispose riêng).
///
/// Sau khi submit thành công, controller chủ động `invalidate` các provider mà
/// trạm/dashboard tài khoản đang cache, để UI lập tức thấy review mới + rating
/// trung bình mới mà không phụ thuộc caller nhớ làm.
class StationReviewSubmitController
    extends AutoDisposeFamilyAsyncNotifier<void, int> {
  @override
  Future<void> build(int stationId) async {
    // Idle ban đầu — `AsyncData(null)`.
  }

  Future<void> submit({
    required int rating,
    String? comment,
    List<String>? imageUrls,
  }) async {
    final stationId = arg;
    final api = ref.read(stationsApiProvider);
    state = const AsyncLoading();
    try {
      await api.submitStationReview(
        stationId: stationId,
        rating: rating,
        comment: comment,
        imageUrls: imageUrls,
      );
      _invalidateRelated(stationId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Cache stale sau khi review mới được tạo:
  /// - rating aggregate của trạm đó (trung bình + count)
  /// - danh sách review của trạm đó (`StationReviewsSection` lắng nghe bump)
  /// - dashboard tài khoản (số review của tôi tăng) + list "đánh giá của tôi"
  void _invalidateRelated(int stationId) {
    ref.invalidate(stationRatingSummaryProvider(stationId));
    ref.invalidate(accountActivitySummaryProvider);
    ref.invalidate(myStationReviewsFirstPageProvider);
    // Bump trigger cho `StationReviewsSection._loadInitial` (page-based, không qua provider).
    ref.read(stationReviewListBumpProvider(stationId).notifier).state++;
  }
}

final stationReviewSubmitControllerProvider =
    AutoDisposeAsyncNotifierProviderFamily<
        StationReviewSubmitController, void, int>(
  StationReviewSubmitController.new,
);
