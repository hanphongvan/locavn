# 🚀 DEVELOPMENT WORKFLOW – HTTM & CSDL XĂNG DẦU

Tài liệu này quy định quy trình phát triển chức năng mới sử dụng:

* Cursor AI
* Codex
* Claude

---

# 🎯 1. NGUYÊN TẮC CHUNG

* Không code trực tiếp trên `main`
* Mỗi chức năng = 1 branch riêng
* Luôn commit trước khi cho AI chạy
* Backend xong → mới làm UI
* Mọi thay đổi DB phải có migration + update docs

---

# 🧭 2. FLOW CHUẨN

```
Spec → Branch → Backend → UI → Test → Commit → Merge
```

---

# 🧩 3. BƯỚC 1 — VIẾT SPEC

Tạo file:

```
/docs/modules/{fuel|httm}/spec-<feature>.md
```

Ví dụ:

```
/docs/modules/httm/spec-market.md
```

---

# 🌿 4. BƯỚC 2 — TẠO BRANCH

```bash
git checkout develop
git pull
git checkout -b feature/<module>-<feature>
```

Ví dụ:

```bash
git checkout -b feature/httm-market
```

---

# 💾 5. BƯỚC 3 — BACKUP TRƯỚC KHI AI CODE

```bash
git add .
git commit -m "backup before implementing <feature>"
```

---

# ⚙️ 6. BƯỚC 4 — CODE BACKEND (CODEX)

Yêu cầu:

* Tạo bảng DB
* Tạo stored procedure
* Tạo API
* Update:

  * `/docs/architecture/database.md`

---

# 🎨 7. BƯỚC 5 — CODE UI (CURSOR)

Thực hiện:

* Tạo màn hình:

  * List
  * Form
  * Detail
* Kết nối API
* Validate form

---

# 🧪 8. BƯỚC 6 — TEST

Checklist:

* [ ] API chạy OK
* [ ] Insert DB đúng
* [ ] UI gọi API OK
* [ ] Không lỗi console
* [ ] Map hiển thị đúng (nếu có)

---

# 💾 9. BƯỚC 7 — COMMIT

```bash
git add .
git commit -m "feat(<module>): add <feature>"
```

Ví dụ:

```bash
git commit -m "feat(httm): add market management"
```

---

# 🔀 10. BƯỚC 8 — MERGE

```bash
git checkout develop
git merge feature/<module>-<feature>
```

---

# 🏷️ 11. (OPTIONAL) TAG VERSION

```bash
git tag v0.x-<feature>
```

---

# 🔄 12. QUY TRÌNH FIX BUG

```bash
git checkout develop
git checkout -b fix/<bug-name>

# sửa code

git add .
git commit -m "fix: <bug description>"

git checkout develop
git merge fix/<bug-name>
```

---

# ⚠️ 13. QUY TẮC QUAN TRỌNG

## ❌ KHÔNG:

* Code trực tiếp trên main
* Sửa DB bằng tay
* Commit file chứa secret
* Làm nhiều feature trong 1 branch

## ✅ LUÔN:

* Dùng branch riêng
* Commit trước khi AI chạy
* Update docs khi đổi schema
* Test trước khi merge

---

# 🤖 14. PHÂN VAI AI

## Claude

* Viết spec
* Thiết kế hệ thống

## Codex

* Backend
* Database
* API
* Refactor lớn

## Cursor

* UI/UX
* Angular/Flutter
* Fix bug nhỏ

---

# 🧠 15. TEMPLATE NHANH

## Tạo feature mới

```bash
git checkout develop
git checkout -b feature/<name>
git add .
git commit -m "backup before <name>"
```

---

## Commit chuẩn

```bash
git commit -m "feat(module): description"
```

---

## Rollback nhanh

```bash
git reset --hard HEAD~1
```

---

# 🎯 KẾT LUẬN

Làm đúng workflow này sẽ giúp:

* Không mất code
* Không bị AI phá hệ thống
* Dễ rollback
* Dễ mở rộng sau này

---
