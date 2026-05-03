# Hướng dẫn Claude (phân tích, spec, thiết kế)

Dùng khi cần **phân tích hệ thống**, **viết spec**, **thiết kế** luồng dữ liệu và ranh giới module — ít nhấn mạnh từng dòng UI.

## Nguồn đọc theo thứ tự gợi ý

1. `docs/README_FOR_AI.md` — domain Fuel vs HTTM và quy tắc chung.
2. `docs/architecture/overview.md` — mục tiêu demo, stack, quy tắc dữ liệu.
3. `docs/architecture/database.md` — bảng/cột thực tế (không bịa).
4. `docs/architecture/schema-analysis.md` — gap và diễn giải nghiệp vụ theo vùng.
5. `docs/modules/api-mapping.md` — gom module API ↔ bảng.
6. `docs/modules/phase-1-scope.md` — phạm vi phase (read-only, Flutter list/detail).

## Thiết kế

- Phân biệt rõ **Fuel** (ứng dụng công dân / cửa hàng) và **HTTM** (tổng hợp/lãnh đạo); nếu ranh giới chưa rõ, ghi TODO và đề xuất tách doc sau.
- Mọi đề xuất schema mới phải đi kèm **migration path** và **cập nhật tài liệu**; không giả định greenfield.
- Ưu tiên **an toàn demo**: read-only trước, query hẹp, không hủy dữ liệu.

## Output mong đợi

- Spec ngắn, có traceability tới bảng/cột hoặc SP khi khả thi.
- Liệt kê rủi ro và gap thay vì che bằng mock.
