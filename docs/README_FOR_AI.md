# Hướng dẫn cho AI (Cursor, Codex, Claude)

Tài liệu này là **điểm vào** khi làm việc với repo; chi tiết nằm trong `docs/architecture/`, `docs/modules/`, và `docs/prompts/`.

**Git + AI (nhánh, PR, Cursor / Claude Code / Codex):** `docs/AI_WORKFLOW.md`.

## Hai domain sản phẩm

1. **Fuel (xăng dầu / bán lẻ)** — ứng dụng công dân, cửa hàng xăng dầu, bản đồ trạm, giá/tồn kho khi có dữ liệu thật, báo cáo liên quan DMPPortal.
2. **HTTM** — phần quản trị / lãnh đạo ngành (dashboard, tổng hợp) dùng chung API và CSDL theo phạm vi dự án; ranh giới tính năng có thể mở rộng theo roadmap.

Khi không chắc thuộc domain nào, xem `docs/modules/fuel/README.md`, `docs/modules/httm/README.md`, và các file gốc trong `docs/modules/` (có ghi chú TODO nếu cần phân tách thủ công).

## Stack kỹ thuật

| Thành phần | Công nghệ |
|------------|-----------|
| Backend | ASP.NET Core Web API |
| Truy cập dữ liệu | **Stored procedure** (Dapper / ADO.NET); không query bảng trực tiếp cho nghiệp vụ — xem `docs/architecture/backend.md` |
| Frontend web | Angular (thư mục `admin/` hoặc `DMPPortal/` tùy nhánh) |
| Mobile | Flutter (`mobile/`) |
| CSDL | SQL Server (`DMPPortal`) — **nguồn sự thật cột/bảng:** `docs/architecture/database.md` |

## Quy tắc bắt buộc

- **Migration:** mọi thay đổi schema phải qua **EF migrations** (hoặc script được kiểm soát trong repo); **không** sửa DB production/staging trực tiếp ngoài quy trình.
- **Tài liệu schema:** mỗi thay đổi có ý nghĩa đối với contract hoặc hiểu nghiệp vụ phải **cập nhật** `docs/architecture/database.md` và các file liên quan (`schema-extension`, `field-mapping`, v.v.).
- **API:** giữ **nhất quán** với pattern hiện tại (controller mỏng, DTO, gọi SP, lỗi/gap ghi rõ trong OpenAPI hoặc message) — tham chiếu code và `docs/modules/api-mapping.md`.

## Prompt theo công cụ AI

- **Cursor:** `docs/prompts/cursor.md` — UI, Angular, debug.
- **Codex:** `docs/prompts/codex.md` — API, migration, backend.
- **Claude:** `docs/prompts/claude.md` — phân tích, spec, thiết kế hệ thống.

## Cấu trúc thư mục `docs/`

- `architecture/` — tổng quan, backend, CSDL, phân tích schema.
- `modules/` — mapping API, field, phase scope; `fuel/` và `httm/` là chỉ mục theo domain.
- `standards/` — quy ước chung (mở rộng sau).
- `prompts/` — hướng dẫn theo từng AI.
