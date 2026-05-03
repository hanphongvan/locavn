/// User-visible copy for the station detail shell (no inline literals in widgets).
abstract final class StationDetailStrings {
  static const String loadingDetail = 'Đang tải chi tiết cây xăng';
  static const String errorLogLabel = 'Chi tiết cây xăng (stationDetailProvider)';
  static const String stationFallbackPrefix = 'Cây xăng #';

  static const String sectionPrices = 'Giá bán';
  static const String sectionRating = 'Đánh giá';
  static const String sectionReviewsNotes = 'Nhận xét';
  static const String labelProvince = 'Tỉnh/TP';
  static const String labelDistrict = 'Quận/Huyện';
  static const String labelWard = 'Phường/Xã';
  static const String labelPhone = 'Điện thoại';
  static const String labelEmail = 'Email';
  static const String sectionExtra = 'Thông tin bổ sung';
  static const String sectionUnitInfo = 'Thông tin đơn vị';
  static const String sectionWeekly = 'Lịch tuần';
  static const String sectionStock = 'Tồn kho';
  static const String sectionStoreServices = 'Dịch vụ tại trạm';
  static const String storeServiceInactive = 'Tạm tắt';
  static const String sectionArea = 'Khu vực';
  static const String sectionContact = 'Liên hệ';

  static const String labelOpen = 'Mở cửa';
  static const String labelClose = 'Đóng cửa';
  static const String labelRon95 = 'RON 95';
  static const String labelDo = 'DO';
  static const String priceRowFallback = 'Mặt hàng';
  static const String noPrices = 'Chưa có dữ liệu giá.';
  static const String emDash = '—';

  static const String labelLicense = 'Số giấy phép';
  static const String labelIssued = 'Ngày cấp';
  static const String labelExpiry = 'Hết hạn';
  static const String labelStationCode = 'Mã cây xăng';

  static const String ratingLoading = 'Đang tải…';
  static const String ratingRetry = 'Thử lại';
  static const String ratingLoadError = 'Không tải được điểm đánh giá.';
  static const String ratingNone = 'Chưa có đánh giá';
  static const String ratingOutOf = '/ 5';
  static String ratingReviewCountLabel(int n) => '$n đánh giá';
  static const String reviewsLoadMore = 'Xem thêm';
  static const String reviewsEmpty = 'Chưa có nhận xét.';
  static const String reviewsLoadErrorTitle = 'Không tải được nhận xét.';
  static const String reviewsListLoadErrorTitle = 'Không tải được danh sách đánh giá công khai.';

  static const String statusOpen = 'Đang mở cửa';
  static const String statusClosed = 'Đóng cửa';
  static const String statusPaused = 'Tạm nghỉ';

  static const String actionRate = 'ĐÁNH GIÁ';
  static const String actionReport = 'BÁO CÁO VI PHẠM';
  static const String directionsTooltip = 'Chỉ đường';
  static const String directionsOpenFail = 'Không mở được ứng dụng bản đồ.';
  static const String directionsLaunchFail = 'Không mở được chỉ đường.';

  static const String weekdayClosedAllDay = 'Đóng cả ngày';
}
