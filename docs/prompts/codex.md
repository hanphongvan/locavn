# Hướng dẫn Codex (API, migration, backend)

Dùng khi viết **ASP.NET Core API**, **migration EF**, **stored procedure** (script trong `Migrations/`), và tầng persistence.

## Kiến trúc dữ liệu

- **Bắt buộc:** đọc `docs/architecture/backend.md` — chỉ gọi **stored procedure** cho nghiệp vụ đọc/ghi dữ liệu chính; không LINQ trực tiếp lên bảng nghiệp vụ.
- **Schema:** `docs/architecture/database.md` là nguồn tên bảng/cột; phần mở rộng store-admin: `docs/architecture/schema-extension.md`.

## Migration

- Tạo migration có tên rõ ràng; SQL trong migration phải khớp cột/kiểu đã document.
- Không chỉnh tay DB ngoài repo; sau migration cập nhật `database.md` / `schema-extension.md` nếu có object mới hoặc đổi ý nghĩa.

## API

- Controller mỏng; map request → tham số SP; map reader → DTO.
- Theo pattern endpoint và naming hiện có trong solution; tham chiếu `docs/modules/api-mapping.md`.
- Gap schema (không có bảng phản hồi công dân, v.v.) — trả lỗi/placeholder có message trích dẫn doc, không mock silent.

## Kiểm tra

- `dotnet build` trên solution backend sau thay đổi.
