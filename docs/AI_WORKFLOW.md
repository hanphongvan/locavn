# Git & AI workflow (dự án thật)

Tài liệu này mô tả **nhánh Git**, **PR**, và cách phối hợp **Cursor AI**, **Claude Code**, và **Codex** sao cho an toàn với code production, không thay thế quy trình nội bộ của team nếu đã có.

Tham chiếu thêm: [`README_FOR_AI.md`](README_FOR_AI.md), [`architecture/backend.md`](architecture/backend.md), [`prompts/cursor.md`](prompts/cursor.md), [`prompts/codex.md`](prompts/codex.md), [`prompts/claude.md`](prompts/claude.md).

---

## 1. Git — khi chưa khởi tạo repo

Nếu thư mục gốc **chưa** có `.git` (chưa `git init`):

1. Sao lưu / commit nơi khác nếu đang có bản copy quan trọng.
2. Tại thư mục gốc monorepo:
   ```bash
   git init
   git add .
   git status
   ```
3. Kiểm tra `.gitignore` gốc — bỏ ignore nhầm file cần version (ví dụ chỉ template `appsettings`, không ignore nhầm toàn bộ config hợp lệ).
4. Commit đầu tiên khi đã rà soát:
   ```bash
   git commit -m "chore: initial import with gitignore and docs workflow"
   ```
5. Thêm remote và đẩy lên khi có server:
   ```bash
   git remote add origin <URL>
   git branch -M main
   git push -u origin main
   ```

**Không** chạy các lệnh xóa lịch sử (`git reset --hard` trên nhánh đã push, `filter-repo` thiếu hiểu biết, v.v.) trừ khi có quy trình và backup rõ ràng.

---

## 2. Mô hình nhánh (giai đoạn code dự án)

Gợi ý tối thiểu, phù hợp team nhỏ–vừa:

| Nhánh | Vai trò |
|--------|---------|
| `main` | Luôn **có thể release** (đã review, CI xanh nếu có). |
| `develop` *(tuỳ chọn)* | Tích hợp tính năng đang phát triển; merge vào `main` theo sprint/release. |
| `feature/<ticket>-mô-tả-ngắn` | Một tính năng / bugfix / doc batch. |
| `hotfix/<mô-tả>` | Sửa gấp production từ `main`. |

Luồng làm việc ngắn:

1. `git checkout main && git pull`
2. `git checkout -b feature/xxx`
3. Làm việc, commit nhỏ, có message rõ.
4. Push + mở Pull Request vào `main` (hoặc `develop`).
5. Sau merge: xóa nhánh feature trên remote (tuỳ convention team).

---

## 3. Commit message

- Ưu tiên tiếng Anh hoặc thống nhất một ngôn ngữ trong repo.
- Tiền tố gợi ý: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:` (tương thích ý tưởng Conventional Commits).
- Một commit một ý chính; tránh “dump” không liên quan chung một PR.

---

## 4. Pull Request

- Dùng template: [`.github/pull_request_template.md`](../.github/pull_request_template.md).
- PR nhỏ dễ review hơn PR khổng lồ.
- Nếu đổi **schema / migration / API**: cập nhật `docs/architecture/database.md` và các doc liên quan (theo [`README_FOR_AI.md`](README_FOR_AI.md)).

---

## 5. Cursor AI

- **Nhánh:** luôn làm trên `feature/*`, không commit thẳng lên `main` nếu team có rule.
- **Phạm vi:** mô tả rõ file/module trong prompt; tham chiếu `docs/prompts/cursor.md` cho UI / Angular / debug.
- **Review:** diff trước khi stage; không merge code AI mà không đọc thay đổi, nhất là chỗ auth, SQL, migration.

---

## 6. Claude Code

- Dùng mạnh cho **phân tích, spec, thiết kế**, refactor doc — xem `docs/prompts/claude.md`.
- **Không** thay thế review người cho thay đổi schema hoặc luồng tiền/nghiệp vụ nhạy cảm.
- Kết quả phân tích nên được **ghi vào PR mô tả** hoặc `docs/` khi là quyết định kiến trúc lâu dài.

---

## 7. Codex (CLI / IDE)

- Tập trung **API, migration, backend** — `docs/prompts/codex.md`.
- Tuân thủ **stored procedure first** và nguồn schema trong `docs/architecture/database.md`.
- Sau chỉnh backend: chạy `dotnet build`; không đẩy PR nếu build đỏ (trừ khi có lý do và ghi rõ).

---

## 8. SQL Server & secrets

- Không commit file `.mdf`, `.bak`, chuỗi kết nối production, API key — đã loại trong `.gitignore` gốc (mức pattern chung).
- Mọi thay đổi schema qua **migration** trong repo + cập nhật doc.

---

## 9. Tóm tắt trách nhiệt theo công cụ

| Công cụ | Ưu tiên sử dụng cho |
|--------|----------------------|
| **Cursor** | UI, Angular, debug tích hợp IDE, chỉnh sửa file cục bộ có kiểm soát |
| **Claude Code** | Spec, thiết kế, phân tích gap, viết / tái cấu trúc tài liệu |
| **Codex** | Endpoint, migration, script SQL trong codebase, pattern backend |

Mọi công cụ: **cùng một Git flow** — branch → PR → merge, không “vẽ” nhánh song song ngoài Git.
