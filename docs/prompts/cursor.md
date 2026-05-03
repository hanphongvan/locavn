# Hướng dẫn Cursor (UI, Angular, debug)

Dùng khi làm việc chủ yếu trên **giao diện**, **Angular**, và **gỡ lỗi** trong repo này.

## Ưu tiên

1. **Khớp pattern UI hiện có** — component structure, service, routing, style (SCSS/CSS) theo cùng thư mục app đang sửa (`admin/`, `DMPPortal/ClientApp/`, v.v.).
2. **Contract từ API** — không đoán field JSON; đối chiếu OpenAPI/Swagger hoặc client TypeScript đã generate; với nghiệp vụ CSDL xem `docs/architecture/database.md` và `docs/modules/field-mapping.md`.
3. **Angular** — standalone components nếu project đã dùng; lazy loading theo module hiện tại; tránh thêm dependency nặng không cần thiết cho demo.

## Debug

- Kiểm tra **CORS**, **base URL**, và **auth** (JWT / API key) khớp `appsettings` / environment.
- Lỗi 404/500: xác nhận route API backend và proxy dev (`environment.ts`).
- So sánh payload thực tế với DTO backend; gap dữ liệu ghi nhận theo `docs/architecture/schema-analysis.md` thay vì mock khi yêu cầu là dữ liệu thật.

## Không làm trong phạm vi UI

- Không tự ý đổi schema SQL hoặc thêm bảng; mọi thay đổi DB qua migration và cập nhật docs (xem `docs/README_FOR_AI.md`).
- Không “bịa” tọa độ trạm hoặc cột không có trong tài liệu schema.
