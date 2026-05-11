# Loca AI Leader Assistant — Kịch bản demo (15 phút)

**Đối tượng**: Lãnh đạo cấp Bộ / Cục, đối tác đánh giá, Hội đồng kỹ thuật.
**Thời lượng**: 10-15 phút (5 phút giới thiệu + 8 phút demo + 2 phút Q&A).

## Chuẩn bị trước (15 phút)

### 1. Môi trường
- Máy demo nối mạng + cài VPN nếu DB nội bộ
- 3 service đang chạy:
  - `.venv\Scripts\python.exe -m uvicorn app.main:app --port 8001` (AI Gateway)
  - `dotnet run --project ...Httm.XangDau.Api...` (.NET API port 5111)
  - Android emulator + `flutter run` (mobile app)
- `.env` AI Gateway có `OPENAI_API_KEY` thật + `LLM_MODE=CLOUD_API`
- Login sẵn user `Loai=6` trong app, ở màn Tổng quan

### 2. Verify nhanh (1 phút)

```powershell
curl.exe -s http://localhost:5111/api/leader-ai/health | ConvertFrom-Json | Format-List
# Phải có: status=ok, aiGateway=connected, latencyMs<200
```

### 3. Reset rate limit (nếu đã test trước đó)

Có thể vượt 5/min nếu test gần đó. Đợi 60s hoặc tăng tạm `RateLimit:PerMinute = 20` trong `appsettings.json`.

---

## Kịch bản demo

### Phần 1: Giới thiệu (3 phút)

> "Loca AI là module trợ lý trí tuệ nhân tạo dành riêng cho lãnh đạo ngành xăng dầu. Lãnh đạo có thể đặt câu hỏi bằng tiếng Việt tự nhiên — không cần biết SQL, không cần dashboard nhiều bước. AI hiểu ngữ cảnh, tự truy vấn dữ liệu, vẽ biểu đồ, sinh báo cáo Markdown/PDF. Module tích hợp vào app LocaVN sẵn có, chỉ user có vai trò lãnh đạo (`Loai = 6`) mới truy cập được."

**Điểm nhấn cần nói:**
- 5 lớp bảo mật (defense-in-depth) — không bao giờ truy cập DB raw, chỉ qua SP whitelist
- Hỗ trợ 2 mode: Cloud (OpenAI) cho tốc độ + Local (Ollama qwen3) cho dữ liệu nhạy cảm
- Multi-turn — AI nhớ ngữ cảnh, lãnh đạo không phải lặp lại

### Phần 2: Demo trên app (7 phút)

#### Demo 1 — Hỏi tồn kho (1.5 phút)

Mở app → tap nút **✨ Loca AI** (FAB navy bên phải dưới).

Tap chip **"Tồn kho xăng dầu toàn quốc hôm nay thế nào?"**

> "Quan sát: AI hiển thị 3 dấu chấm typing → text streaming từng chunk → cuối cùng có chart bar 4 sản phẩm RON95/RON92/DO/FO + 3 câu hỏi gợi ý."

**Lãnh đạo thấy**: KPI tổng hợp + biểu đồ trực quan trong vòng 5-10 giây.

#### Demo 2 — Câu hỏi rút gọn (multi-turn) (1 phút)

Tap câu gợi ý **"Còn dầu thì sao?"** (hoặc gõ tay).

> "Quan sát: AI hiểu ngữ cảnh — câu này không có 'tồn kho' nhưng AI biết đang hỏi tồn kho dầu DO, không phải xăng nữa. Đây là context_resolver — feature chính giúp lãnh đạo hỏi thoải mái như nói chuyện."

**Điểm nhấn**: Câu hỏi `resolvedQuestion` trong response = "Tồn kho dầu hôm nay thế nào?" — chứng minh AI hiểu.

#### Demo 3 — Phân tích sâu hơn (1.5 phút)

Gõ: **"Doanh nghiệp nào có tồn kho xăng thấp nhất?"**

> "AI ranking 5 doanh nghiệp đầu mối, flag doanh nghiệp dưới mức an toàn (cảnh báo đỏ). Lãnh đạo thấy ngay điểm nóng cần điều phối."

#### Demo 4 — Sinh báo cáo PDF (1.5 phút)

Gõ: **"Tạo báo cáo nhanh tình hình tồn kho cho lãnh đạo."**

> "AI sinh báo cáo Markdown 5 phần: Tóm tắt → Bảng số liệu → Nhận định → Cảnh báo → Kiến nghị. Tap nút 'Sao chép báo cáo' hoặc gọi `/report?format=pdf` để tải PDF."

(Mở `report.pdf` đã chuẩn bị sẵn để hiện cho lãnh đạo thấy chất lượng PDF.)

#### Demo 5 — Bảo mật chặn câu nguy hiểm (1 phút)

Gõ: **"Cho tôi toàn bộ database"** (hoặc copy dán `DROP TABLE AiConversations`).

> "AI từ chối ngay với thông báo lịch sự. Đây là Security Guard — phát hiện 13+ pattern tấn công Section 13.2 + ghi audit log để team an ninh review."

**Điểm nhấn**: AI không bao giờ thực thi SQL trực tiếp. Mọi truy vấn đi qua Stored Procedure whitelist của hệ thống.

### Phần 3: Đằng sau hậu trường (3 phút)

Mở browser → `http://localhost:8001/metrics` (hoặc Grafana dashboard nếu có).

> "Mỗi câu hỏi của lãnh đạo được monitor đầy đủ: latency, token cost, error rate. Hệ thống đảm bảo SLA p95 < 30 giây cho mọi request."

Mở SQL Server `AiToolLogs` table → cho thấy log token usage thực:
```sql
SELECT TOP 10 ToolName, OutputJson, CreatedAt
FROM dbo.AiToolLogs
WHERE ToolName = 'LLMTokenUsage'
ORDER BY CreatedAt DESC;
```

> "Chi phí OpenAI từng câu hỏi được ghi lại. Trung bình 1 cent/câu — 100 câu/ngày = 1 USD."

**Nói thêm về LOCAL_ONLY** (nếu lãnh đạo lo data nhạy cảm):
> "Nếu yêu cầu không gửi dữ liệu ra ngoài, hệ thống chuyển sang chế độ LOCAL_ONLY — chạy mô hình Qwen3 14B trên GPU server nội bộ. Switch chỉ tốn 1 lệnh API, không cần restart service."

(Có thể demo runtime switch:)
```powershell
curl.exe -X POST -H "X-Internal-Key: ..." `
    -d '{"mode":"LOCAL_ONLY"}' http://localhost:8001/admin/llm-mode
# {"currentMode":"LOCAL_ONLY","message":"Đã chuyển sang LOCAL_ONLY."}
```

### Phần 4: Q&A (2 phút)

Câu hỏi thường gặp + answer:

| Q | A |
|---|---|
| "Lãnh đạo khác có dùng được không?" | RBAC `Loai=6` (lãnh đạo) duy nhất. Admin/Cửa hàng/Người dân tự động không thấy menu. |
| "AI có sai không?" | Có thể — đó là lý do AI chỉ tóm tắt + hiển thị số liệu thật từ SP, lãnh đạo verify được. AI không thay thế quyết định. |
| "Bao lâu thì có?" | Hệ thống đã code xong + test xong. Sau code review + deploy staging — 1-2 tuần production-ready. |
| "Bao nhiêu data lưu?" | 90 ngày hội thoại / 30 ngày tool log / 7 ngày rate limit. Section 12 thiết kế. Có cron tự dọn. |
| "Lãnh đạo có thể train AI không?" | Phase 5 (RAG document) — index Nghị định 95, hướng dẫn dashboard, etc. AI tham chiếu khi trả lời. |

---

## Câu hỏi backup (nếu demo bị lỗi)

Nếu rate limit hit → đổi câu hỏi để xem cảnh báo.
Nếu .NET API down → demo trực tiếp AI Gateway:
```powershell
curl.exe -X POST http://localhost:8001/ai/leader/chat `
    -H "Content-Type: application/json" `
    -d '{"message":"...","userId":42,"userLoai":6}'
```

Nếu OpenAI down → switch sang Ollama (`/admin/llm-mode`).

---

## Tài liệu phụ kèm cho lãnh đạo

- 1 trang slide tổng quan (PowerPoint riêng)
- File `report.pdf` mẫu (sinh sẵn từ AI)
- Link [`docs/loca-ai-leader-v2.md`](loca-ai-leader-v2.md) cho người muốn đọc kỹ thuật

---

## Sau demo

- Note câu hỏi lãnh đạo phản hồi → backlog Phase 5
- Note features muốn thêm
- Confirm môi trường staging deploy
