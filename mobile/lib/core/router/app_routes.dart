/// Phase-1 shell paths (bottom tabs). Keep in sync with [createAppRouter] branches.
enum AppRoute {
  map('/map'),
  /// Dashboard báo cáo — không còn tab bottom; mở bằng `context.go` / menu Thêm.
  reports('/reports'),
  /// Giá nhiên liệu / kỳ báo cáo (tab Nhiên liệu).
  fuel('/fuel'),

  /// Form thêm lần đổ xăng (full screen, không nằm trong bottom tab stack).
  addFuelTransaction('/fuel/add-transaction'),

  /// Danh sách đầy đủ lịch sử đổ xăng (sửa / xóa).
  fuelTransactionsHistory('/fuel/transactions-history'),
  /// Xe của tôi — `GET /api/my-vehicles`.
  myVehicles('/my-vehicles'),
  /// Tab thứ 4 (Tài khoản / Thêm) trong shell.
  more('/more'),

  /// Đổi mật khẩu (`POST /api/auth/change-password`, JWT).
  changePassword('/account/change-password'),

  /// Báo vi phạm đã gửi — `GET /api/my-bad-reports`.
  myViolationReports('/account/my-violation-reports'),

  /// Đánh giá cây xăng đã gửi — `GET /api/my-reviews`.
  myStationReviews('/account/my-station-reviews');

  const AppRoute(this.path);
  final String path;

  static const String splash = '/splash';
  static const String login = '/login';
  /// Đăng ký tài khoản (API `POST /api/auth/register-user`, anonymous + admin API key).
  static const String register = '/register';

  /// Quên mật khẩu — `POST /api/auth/forgot-password`.
  static const String forgotPassword = '/forgot-password';

  /// Đặt lại mật khẩu — `POST /api/auth/reset-password?token=` (query tùy chọn, UI đọc `token`).
  static const String resetPassword = '/reset-password';

  /// Shell **Lãnh đạo** (`Loai == 6`) — `LeaderMainScreen`: Tổng quan, Bản đồ, Bán lẻ, Phân tích, Quỹ bình ổn.
  /// `leaderAccount` không còn ở bottom tab — mở qua icon AppBar (top-level GoRoute).
  static const String leaderOverview = '/leader/overview';
  static const String leaderMap = '/leader/map';
  static const String leaderRetail = '/leader/retail';
  static const String leaderAnalytics = '/leader/analytics';
  static const String leaderStabilizationFund = '/leader/stabilization-fund';
  static const String leaderAccount = '/leader/account';

  /// Loca AI Leader Assistant (Phase 2B) — top-level GoRoute, mở qua icon
  /// trên LeaderExecutiveAppBar khi `Loai == 6`.
  static const String leaderAiChat = '/leader/ai-chat';

  static const String accessDenied = '/access-denied';

  /// Shell roots — parent redirect targets (mỗi root redirect về tab đầu của shell).
  static const String leaderRoot = '/leader';
  static const String storeRoot = '/store';

  /// Pattern path cho [GoRoute.path] — chứa placeholder `:id` / `:headerId`.
  static const String stationDetailPattern = '/stations/:id';
  static const String storeInventoryVoucherPattern = '/store/inventory/voucher/:headerId';

  /// Base prefix dùng cho `path.startsWith(...)` ở RBAC checks.
  static const String stationDetailBase = '/stations/';
  static const String storeInventoryVoucherBase = '/store/inventory/voucher/';

  static String stationDetail(int stationId) => '$stationDetailBase$stationId';

  /// Full-screen inventory stock map (not a bottom-tab root).
  static const String inventoryStockMap = '/inventory/stock-map';

  /// Admin / Trader placeholder homes (not the consumer or store shells).
  static const String portalAdminHome = '/portal/admin/home';
  static const String portalTraderHome = '/portal/trader/home';

  /// **Store** portal (`Loai == 4`) — disjoint from consumer [`AppRoute.map`] shell.
  static const String storeMap = '/store/map';
  static const String storeServices = '/store/services';
  static const String storeInventory = '/store/inventory';

  /// Tạo phiếu nhập/xuất (full screen, `Loai == 4`).
  static const String storeInventoryCreate = '/store/inventory/create';

  /// Chi tiết một phiếu (`GET /api/admin/inventory-transactions/{id}`).
  static String storeInventoryVoucherDetail(int headerId) =>
      '$storeInventoryVoucherBase$headerId';

  static const String storeAccount = '/store/account';

  /// Giá bán — tab trong [StoreShellPage]; chỉ `Loai == 4`.
  static const String storeSalePrices = '/store/sale-prices';
}
