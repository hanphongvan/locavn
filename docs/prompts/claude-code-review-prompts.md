# Bộ Prompt Claude Code — Review Mobile Flutter
# Dự án: httm-xangdau
# Dùng trong: VS Code + Claude Code extension
# Cách dùng: Copy từng prompt vào chat Claude Code, chạy theo thứ tự

===========================================================================
## BƯỚC 0 — KHỞI ĐỘNG (Chạy 1 lần duy nhất khi bắt đầu session)
===========================================================================

Paste prompt này ĐẦU TIÊN để Claude Code hiểu context dự án:

---PROMPT 0---
Tôi đang làm dự án Flutter tên httm-xangdau — ứng dụng quản lý trạm xăng dầu.

Tech stack:
- Frontend: Flutter (Dart), feature-first folder structure
- Backend: ASP.NET Core 10 REST API (project DmpPortal.Api)
- Database: SQL Server (DMPPortal)
- Auth: JWT Bearer Token

Cấu trúc mobile/lib/:
- app/        → theme, routing, DI
- features/   → map, stations, reports, complaints
- data/       → API client, models

Trong suốt session này, hãy:
1. Trả lời bằng tiếng Việt
2. Phân loại vấn đề theo mức độ: 🔴 Critical / 🟡 Warning / 🔵 Suggestion
3. Với mỗi vấn đề, đưa ra đoạn code fix cụ thể (không chỉ mô tả)
---END PROMPT 0---


===========================================================================
## BƯỚC 1 — REVIEW ARCHITECTURE & FOLDER STRUCTURE
===========================================================================

---PROMPT 1A — Tổng quan cấu trúc---
Hãy đọc toàn bộ cấu trúc thư mục mobile/lib/ và pubspec.yaml.

Đánh giá:
1. Có tuân thủ feature-first architecture không?
2. Separation of concerns giữa UI / business logic / data layer có rõ ràng không?
3. Dependency injection được setup như thế nào? Có đúng hướng không?
4. pubspec.yaml có package nào không cần thiết, lỗi thời, hoặc thiếu không?

Liệt kê vấn đề theo format:
[Mức độ] Vấn đề: ...
Vị trí: file/thư mục
Đề xuất: ...
---END PROMPT 1A---

---PROMPT 1B — Review Routing---
Đọc toàn bộ code routing trong mobile/lib/app/routing/ (hoặc nơi routing được định nghĩa).

Kiểm tra:
1. Routing có type-safe không? (GoRouter / AutoRoute / Navigator 2.0)
2. Deep linking có được cấu hình không?
3. Route guard / auth check có hoạt động đúng không?
4. Có route nào bị hardcode string dễ gây lỗi không?
---END PROMPT 1B---

---PROMPT 1C — Review Dependency Injection / State Management---
Đọc code DI và state management trong toàn bộ project.

Đánh giá:
1. Pattern DI đang dùng là gì? (GetIt, Provider, Riverpod, Bloc...)
2. Scope của các dependency có đúng không? (singleton vs factory vs lazySingleton)
3. Có circular dependency không?
4. State management: widget nào rebuild nhiều hơn cần thiết không?
---END PROMPT 1C---


===========================================================================
## BƯỚC 2 — REVIEW TỪNG FEATURE
===========================================================================

---PROMPT 2A — Feature: Stations (Ưu tiên cao nhất)---
Đọc toàn bộ code trong mobile/lib/features/stations/.

Review theo 4 góc độ:

**1. UI Layer:**
- Widget tree có quá sâu không (>5 cấp)?
- Có StatefulWidget nào nên là StatelessWidget không?
- Có dùng const constructor đúng chỗ không?
- List rendering có dùng ListView.builder không hay dùng Column + map?

**2. Business Logic:**
- Logic có bị đặt trong Widget không? (vi phạm separation of concerns)
- Error handling có đầy đủ không? (network error, empty state, loading state)
- Có xử lý pagination / infinite scroll đúng không?

**3. Data Flow:**
- API call có được cache không hay gọi lại mỗi lần rebuild?
- Model mapping từ API response có đúng field name không?

**4. Performance:**
- Có image loading với caching không?
- Có dispose controller / subscription đúng chỗ không?
---END PROMPT 2A---

---PROMPT 2B — Feature: Map---
Đọc toàn bộ code trong mobile/lib/features/map/.

Kiểm tra đặc biệt:
1. Map controller có được dispose đúng cách không? (memory leak)
2. Marker clustering có được implement không khi có nhiều điểm?
3. Có xử lý trường hợp tọa độ null/invalid không?
4. Permission location được xử lý như thế nào (Android + iOS)?
5. Map có bị rebuild toàn bộ khi state thay đổi không?
6. Nếu dùng Google Maps: API key có bị hardcode trong code không? (bảo mật)
---END PROMPT 2B---

---PROMPT 2C — Feature: Reports---
Đọc toàn bộ code trong mobile/lib/features/reports/.

Kiểm tra:
1. Chart/biểu đồ dùng package nào? Có phù hợp không?
2. Data lớn (nhiều điểm dữ liệu) có được xử lý lazy không?
3. Date range picker có validate input không?
4. Có loading state khi fetch báo cáo không?
5. Số liệu có được format đúng locale Việt Nam không? (dấu phẩy, đơn vị...)
---END PROMPT 2C---

---PROMPT 2D — Feature: Complaints (nếu đã implement)---
Đọc toàn bộ code trong mobile/lib/features/complaints/.

Kiểm tra:
1. Form validation có đầy đủ không? (required fields, max length...)
2. Image upload: có resize ảnh trước khi upload không? (tránh upload file quá lớn)
3. Có optimistic update không hay đợi API response mới update UI?
4. Duplicate submission có được ngăn không? (disable button sau khi submit)
5. Offline case: nếu mất mạng khi đang submit thì xử lý thế nào?
---END PROMPT 2D---


===========================================================================
## BƯỚC 3 — REVIEW DATA LAYER
===========================================================================

---PROMPT 3A — API Client---
Đọc toàn bộ code trong mobile/lib/data/api/.

Kiểm tra bảo mật & độ tin cậy:
1. Base URL có được lấy từ config/env không hay hardcode?
2. JWT token có được refresh tự động khi hết hạn không?
3. Interceptor có log request/response trong debug mode không?
4. Timeout được set chưa? (connect timeout, receive timeout)
5. Certificate pinning có cần thiết không?
6. Error code từ API (400, 401, 403, 404, 500) có được xử lý riêng từng loại không?

Với mỗi vấn đề, đưa ra code fix cụ thể.
---END PROMPT 3A---

---PROMPT 3B — Data Models---
Đọc toàn bộ models trong mobile/lib/data/models/.

So sánh với API contracts (nếu có file docs/modules/httm/data-model.md):
1. Tên field trong model có khớp với response từ API không?
2. Nullable fields có được đánh dấu đúng không (field? vs field)?
3. fromJson / toJson có handle null safety đúng không?
4. Có dùng code generation (freezed, json_serializable) không? Nếu chưa, có nên dùng không?
5. Enum values có map đúng với giá trị từ backend không?
---END PROMPT 3B---


===========================================================================
## BƯỚC 4 — REVIEW BẢO MẬT
===========================================================================

---PROMPT 4 — Security Audit---
Scan toàn bộ project mobile/ để tìm các vấn đề bảo mật:

1. **Hardcoded secrets:** API keys, passwords, base URLs nào đang được hardcode?
2. **Token storage:** JWT token được lưu ở đâu? (SharedPreferences không an toàn, nên dùng flutter_secure_storage)
3. **Log sensitive data:** Có log token, password, thông tin cá nhân ra console không?
4. **HTTP vs HTTPS:** Có endpoint nào dùng HTTP không?
5. **User input:** Có validate và sanitize input từ người dùng trước khi gửi lên API không?
6. **ProGuard/R8:** android/app/build.gradle có cấu hình obfuscation không?

Với mỗi vấn đề, đánh giá mức độ rủi ro và đưa ra cách fix.
---END PROMPT 4---


===========================================================================
## BƯỚC 5 — REVIEW UI/UX
===========================================================================

---PROMPT 5A — Màn hình Đăng Nhập---
Đọc code màn hình đăng nhập và file docs/design/login-reference.png.

So sánh implementation với design:
1. Layout, spacing, font size có khớp design không?
2. Có show/hide password toggle không?
3. Keyboard type đúng cho từng field chưa? (email keyboard cho email, v.v.)
4. Có xử lý bàn phím che input field không? (resizeToAvoidBottomInset)
5. Loading state khi đang đăng nhập có rõ ràng không?
6. Error message (sai mật khẩu, hết phiên...) hiển thị thân thiện không?
---END PROMPT 5A---

---PROMPT 5B — Responsive & Accessibility---
Review toàn bộ UI trong features/ về responsive và accessibility:

1. App có hiển thị đúng trên màn hình nhỏ (5") và màn hình lớn (6.7") không?
2. Text có bị overflow không khi font size hệ thống được tăng lên?
3. Có dùng Semantics widget cho screen reader không?
4. Color contrast có đủ tiêu chuẩn WCAG không?
5. Touch target có đủ 48x48dp không?
6. Có hỗ trợ dark mode không?
---END PROMPT 5B---


===========================================================================
## BƯỚC 6 — TẠO BÁO CÁO TỔNG HỢP
===========================================================================

---PROMPT 6 — Tổng hợp kết quả review---
Dựa trên toàn bộ những gì đã review trong session này, hãy tạo báo cáo tổng hợp theo format:

## BÁO CÁO REVIEW — HTTM Xăng Dầu Mobile

### Tóm tắt điểm số
- Architecture: X/10
- Code Quality: X/10
- Security: X/10
- UI/UX: X/10
- **Tổng thể: X/10**

### Vấn đề cần xử lý ngay (Critical 🔴)
[Liệt kê, mỗi mục có: vấn đề + file + cách fix]

### Nên cải thiện (Warning 🟡)
[Liệt kê]

### Đề xuất nâng cao (Suggestion 🔵)
[Liệt kê]

### Ưu điểm của codebase
[Những điểm tốt cần giữ lại]

### Thứ tự ưu tiên xử lý
1. ...
2. ...
3. ...
---END PROMPT 6---


===========================================================================
## TIPS SỬ DỤNG CLAUDE CODE HIỆU QUẢ
===========================================================================

💡 Mỗi prompt nên chạy trong 1 session riêng để tránh mất context

💡 Trước khi chạy prompt, dùng lệnh:
   /add mobile/lib/features/stations/   ← để focus vào folder cụ thể

💡 Nếu Claude Code chưa đọc đúng file, dùng:
   /add mobile/pubspec.yaml
   /add mobile/lib/main.dart

💡 Tạo file CLAUDE.md ở root project để Claude Code tự load context:
   httm-xangdau/CLAUDE.md

💡 Sau khi fix bug theo đề xuất, yêu cầu Claude Code viết test:
   "Viết unit test cho phần vừa fix"

===========================================================================
