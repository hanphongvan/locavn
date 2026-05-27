/**
 * 12 enum lists hardcode cho form phiếu khảo sát (decision D1).
 * Tham chiếu `docs/modules/httm/screens.md` S2.2.
 * Future Phase 3: chuyển sang catalog dynamic.
 */

export interface SurveyOption {
  code: string;
  label: string;
}

/** Step 3 — Loại đơn vị bị khảo sát (multi-select, min 1 khi submit). */
export const UNIT_TYPES: SurveyOption[] = [
  { code: 'market_grade1', label: 'Chợ hạng I' },
  { code: 'market_grade2', label: 'Chợ hạng II' },
  { code: 'market_grade3', label: 'Chợ hạng III' },
  { code: 'supermarket_1', label: 'Siêu thị hạng I' },
  { code: 'supermarket_2', label: 'Siêu thị hạng II' },
  { code: 'supermarket_3', label: 'Siêu thị hạng III' },
  { code: 'mall', label: 'Trung tâm thương mại' },
  { code: 'wholesale_market', label: 'Chợ đầu mối' },
  { code: 'convenience_store', label: 'Cửa hàng tiện lợi' },
  { code: 'management_unit', label: 'Đơn vị quản lý nhà nước' },
  { code: 'other', label: 'Loại hình khác' },
];

/** Step 3 — Hoạt động chính. */
export const MAIN_ACTIVITIES: SurveyOption[] = [
  { code: 'retail', label: 'Bán lẻ' },
  { code: 'wholesale', label: 'Bán buôn' },
  { code: 'service', label: 'Dịch vụ' },
  { code: 'food', label: 'Ăn uống' },
  { code: 'fresh_food', label: 'Thực phẩm tươi sống' },
  { code: 'fashion', label: 'Thời trang' },
  { code: 'electronics', label: 'Điện máy' },
  { code: 'management', label: 'Quản lý' },
  { code: 'other', label: 'Khác' },
];

/** Step 3 — Công cụ làm báo cáo. */
export const REPORT_TOOLS: SurveyOption[] = [
  { code: 'excel', label: 'Microsoft Excel' },
  { code: 'word', label: 'Microsoft Word' },
  { code: 'paper', label: 'Sổ giấy' },
  { code: 'web', label: 'Phần mềm web' },
  { code: 'desktop', label: 'Phần mềm desktop' },
  { code: 'other', label: 'Khác' },
];

/** Step 3 — Phương thức gửi báo cáo. */
export const REPORT_SEND_METHODS: SurveyOption[] = [
  { code: 'paper', label: 'Văn bản giấy' },
  { code: 'email', label: 'Email' },
  { code: 'portal', label: 'Cổng thông tin / phần mềm' },
  { code: 'fax', label: 'Fax' },
  { code: 'chat', label: 'Tin nhắn / Zalo' },
  { code: 'other', label: 'Khác' },
];

/** Step 4 — Loại mạng. */
export const NETWORK_TYPES: SurveyOption[] = [
  { code: 'lan', label: 'Mạng LAN nội bộ' },
  { code: 'wan', label: 'Mạng WAN diện rộng' },
  { code: 'fiber', label: 'Internet cáp quang' },
  { code: '4g', label: 'Internet 4G' },
  { code: 'wifi', label: 'WiFi' },
  { code: 'none', label: 'Không có' },
];

/** Step 4 — Biện pháp bảo mật. */
export const SECURITY_MEASURES: SurveyOption[] = [
  { code: 'firewall', label: 'Tường lửa (Firewall)' },
  { code: 'antivirus', label: 'Phần mềm diệt virus' },
  { code: 'backup', label: 'Sao lưu định kỳ' },
  { code: 'access_control', label: 'Phân quyền truy cập' },
  { code: 'vpn', label: 'VPN' },
  { code: 'ssl', label: 'Mã hoá SSL' },
  { code: 'none', label: 'Chưa áp dụng' },
];

/** Step 5 — Nhu cầu thông tin (18 loại theo S2.2). */
export const INFO_NEEDS: SurveyOption[] = [
  { code: 'basic_info', label: 'Thông tin cơ bản về HTTM' },
  { code: 'location', label: 'Vị trí địa lý' },
  { code: 'operator', label: 'Đơn vị quản lý / chủ đầu tư' },
  { code: 'scale', label: 'Quy mô (diện tích, số gian)' },
  { code: 'business_type', label: 'Loại hình kinh doanh' },
  { code: 'merchant_count', label: 'Số tiểu thương / hộ KD' },
  { code: 'fill_rate', label: 'Tỷ lệ lấp đầy' },
  { code: 'license', label: 'Giấy phép pháp lý' },
  { code: 'fire_safety', label: 'PCCC' },
  { code: 'food_safety', label: 'VSATTP' },
  { code: 'infrastructure', label: 'Hạ tầng kỹ thuật' },
  { code: 'revenue', label: 'Doanh thu / giá thuê' },
  { code: 'images', label: 'Hình ảnh thực tế' },
  { code: 'operation_history', label: 'Lịch sử hoạt động' },
  { code: 'reports', label: 'Báo cáo định kỳ' },
  { code: 'planning', label: 'Quy hoạch phát triển' },
  { code: 'comparison', label: 'So sánh giữa các tỉnh/khu vực' },
  { code: 'other', label: 'Khác' },
];

/** Step 5 — Tiêu chí tìm kiếm. */
export const SEARCH_CRITERIA: SurveyOption[] = [
  { code: 'name', label: 'Theo tên' },
  { code: 'address', label: 'Theo địa chỉ' },
  { code: 'province', label: 'Theo tỉnh' },
  { code: 'ward', label: 'Theo xã/phường' },
  { code: 'type', label: 'Theo loại hình' },
  { code: 'status', label: 'Theo trạng thái' },
  { code: 'area', label: 'Theo diện tích' },
  { code: 'year', label: 'Theo năm hoạt động' },
];

/** Step 5 — Yêu cầu bản đồ. */
export const MAP_REQUIREMENTS: SurveyOption[] = [
  { code: 'marker', label: 'Đánh dấu vị trí' },
  { code: 'cluster', label: 'Nhóm điểm (clustering)' },
  { code: 'heatmap', label: 'Bản đồ nhiệt mật độ' },
  { code: 'boundary', label: 'Ranh giới tỉnh/huyện' },
  { code: 'satellite', label: 'Ảnh vệ tinh' },
  { code: 'directions', label: 'Chỉ đường' },
  { code: 'filter_layer', label: 'Lọc theo lớp loại hình' },
];

/** Step 6 — Chức năng phần mềm (14 chức năng theo S2.2). */
export const SW_FEATURES: SurveyOption[] = [
  { code: 'manage_httm', label: 'Quản lý hồ sơ HTTM' },
  { code: 'search', label: 'Tìm kiếm nâng cao' },
  { code: 'map', label: 'Bản đồ GIS' },
  { code: 'survey', label: 'Phiếu khảo sát điện tử' },
  { code: 'report', label: 'Báo cáo động' },
  { code: 'export_pdf', label: 'Xuất PDF / Excel' },
  { code: 'image_upload', label: 'Tải ảnh thực địa' },
  { code: 'license_alert', label: 'Cảnh báo giấy phép hết hạn' },
  { code: 'public_portal', label: 'Cổng công khai' },
  { code: 'mobile_app', label: 'Ứng dụng di động' },
  { code: 'workflow', label: 'Luồng phê duyệt' },
  { code: 'audit_log', label: 'Nhật ký thao tác' },
  { code: 'integration', label: 'Tích hợp hệ thống khác' },
  { code: 'dashboard', label: 'Dashboard KPI' },
];

/** Step 6 — Tiện ích. */
export const SW_UTILITIES: SurveyOption[] = [
  { code: 'notification', label: 'Thông báo (Push / Email)' },
  { code: 'search_full_text', label: 'Tìm kiếm full-text' },
  { code: 'multi_language', label: 'Đa ngôn ngữ' },
  { code: 'theme', label: 'Giao diện sáng/tối' },
  { code: 'export_data', label: 'Xuất dữ liệu mở' },
  { code: 'api', label: 'API mở' },
];

/** Step 6 — Nền tảng triển khai. */
export const SW_PLATFORMS: SurveyOption[] = [
  { code: 'web', label: 'Web Browser' },
  { code: 'android', label: 'Android' },
  { code: 'ios', label: 'iOS' },
  { code: 'windows', label: 'Windows Desktop' },
  { code: 'cloud', label: 'Cloud (SaaS)' },
  { code: 'onprem', label: 'On-Premise' },
];
