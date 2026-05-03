/// Mặc định máy chủ API (root, không có `/` cuối). Ghi đè: `--dart-define=API_BASE_URL=...`
///
/// Trên điện thoại / máy ảo, `http://localhost:...` trỏ vào chính thiết bị đó, không phải máy dev.
/// Android emulator: thường dùng `http://10.0.2.2:<cổng>` để tới localhost máy host.
String devDefaultBaseUrl() => 'http://xdapi.tpg.vn';
