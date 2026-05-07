# Loca AI Leader Assistant — Hướng dẫn sử dụng & cấu hình

**Đối tượng:** DevOps · Backend dev · Tester nội bộ.
**Phạm vi:** từ cài đặt → chạy được câu hỏi mẫu → vận hành.

Tài liệu thiết kế chi tiết: [`loca-ai-leader-v2.md`](loca-ai-leader-v2.md).
Setup local LLM (Ollama + Qdrant): [`../ai-service/PHASE4_SETUP.md`](../ai-service/PHASE4_SETUP.md).

---

## 1. Kiến trúc 3 lớp

```
┌────────────────┐   HTTPS+JWT   ┌──────────────┐  X-Internal-Key  ┌─────────────┐
│  Flutter App   │ ────────────→ │  .NET API    │ ───────────────→ │  AI Gateway │
│  (Loai = 6)    │ ←──────────── │ (Bearer JWT) │ ←─────────────── │  (FastAPI)  │
└────────────────┘               └──────┬───────┘                  └──────┬──────┘
                                        │ Dapper                          │ httpx
                                        ▼                                 ▼
                                   ┌────────┐                     ┌─────────────┐
                                   │ MS SQL │                     │  OpenAI     │
                                   │ Server │                     │  hoặc       │
                                   └────────┘                     │  Ollama     │
                                                                  └─────┬───────┘
                                                                        │ qdrant-client
                                                                        ▼
                                                                  ┌──────────┐
                                                                  │  Qdrant  │ (RAG)
                                                                  └──────────┘
```

| Service | Port | Code path | Vai trò |
|---|---|---|---|
| **Flutter mobile** | – | [`mobile/lib/features/leader_ai/`](../mobile/lib/features/leader_ai/) | UI chat, role check `Loai = 6` |
| **.NET API** | 5000 | [`backend/src/Httm.XangDau.Api/Features/LeaderAi/`](../backend/src/Httm.XangDau.Api/Features/LeaderAi/) | JWT auth, rate limit, persist hội thoại, audit |
| **AI Gateway** | 8001 | [`ai-service/app/`](../ai-service/) | LangGraph 10-node, gọi LLM, RAG, anomaly detect |
| **SQL Server** | 1433 | – | DB chính (`AiConversations`, `AiMessages`, `AiToolLogs`, ...) |
| **Ollama** | 11434 | – | (chỉ khi LOCAL_ONLY) qwen3 + bge-m3 |
| **Qdrant** | 6333 | – | (chỉ khi cần RAG) vector DB tài liệu nghiệp vụ |

---

## 2. Yêu cầu hệ thống

**Tối thiểu (CLOUD_API):**
- Windows / Linux / macOS
- .NET 10 SDK
- Python 3.11+
- SQL Server 2014+ (đã có sẵn)
- OPENAI_API_KEY (trả phí)

**Đầy đủ (LOCAL_ONLY):**
- Cộng thêm: GPU ≥ 12GB VRAM (đề xuất), Docker, Ollama, ~16GB disk cho models

---

## 3. Setup theo thứ tự

### 3.1. Database — chạy migrations

Migrations tự apply khi `.NET API` start. Connection string trong `backend/src/Httm.XangDau.Api/appsettings.json`:

```json
"ConnectionStrings": {
  "DefaultConnection": "Server=...;Database=DMPPortal_29042026;User Id=...;Password=...;"
}
```

Migrations Phase 1A → 2A đã tự tạo:
- 8 bảng `Ai*` ([`db-schema.md`](db-schema.md) §Loca AI)
- 12 intent seed `AiIntentConfigs`
- 4 SP `sp_Ai_*` (Phase 2A đã refactor sang query bảng thật)

### 3.2. .NET API

```bash
cd backend
dotnet build
dotnet run --project src/Httm.XangDau.Api/Httm.XangDau.Api.csproj
# → API listen tại http://localhost:5000
```

Cấu hình bắt buộc trong `appsettings.json` hoặc env var (env var ưu tiên cao hơn):

```json
{
  "AiGateway": {
    "BaseUrl": "http://localhost:8001",
    "InternalKey": ""
  },
  "RateLimit": { "PerMinute": 5, "PerHour": 20, "PerDay": 50 },
  "Jwt": {
    "Issuer": "Httm.XangDau.Api",
    "Audience": "DMPPortal",
    "SigningKey": "REPLACE_WITH_RANDOM_32_BYTE_SIGNING_KEY"
  }
}
```

**Quan trọng:**
- `AI_GATEWAY_INTERNAL_KEY` (env var) phải khớp với `AI_GATEWAY_INTERNAL_KEY` trong `.env` của AI Gateway → 2 chiều xác thực
- Không commit `appsettings.json` (đã gitignore); dùng `appsettings.example.json` làm template

Verify .NET API hoạt động:
```bash
curl http://localhost:5000/api/leader-ai/health
# {"status":"ok","aiGateway":"disconnected","latencyMs":2000}  ← đúng (AI Gateway chưa start)
```

### 3.3. AI Gateway — chọn 1 trong 3 mode

Tạo `.env` trong `ai-service/`:
```bash
cd ai-service
cp .env.example .env
```

#### Mode A — `CLOUD_API` (đơn giản nhất, dùng OpenAI)

Sửa `.env`:
```env
LLM_MODE=CLOUD_API
ALLOW_CLOUD_LLM=true
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxx
AI_GATEWAY_INTERNAL_KEY=<cùng key với .NET API>
DOTNET_API_BASE_URL=http://localhost:5000
USE_MOCK_DATA=true              # true=Phase 1B mock, false=gọi SP qua .NET
```

Khởi chạy:
```bash
python -m venv .venv
.venv/Scripts/python.exe -m pip install -r requirements.txt
.venv/Scripts/python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8001
```

#### Mode B — `LOCAL_ONLY` (offline, không phụ thuộc OpenAI)

Cần cài Ollama + Qdrant trước (xem [`PHASE4_SETUP.md`](../ai-service/PHASE4_SETUP.md) §1-2):
```bash
ollama pull qwen3:8b qwen3:14b bge-m3
docker run -d -p 6333:6333 qdrant/qdrant
```

`.env`:
```env
LLM_MODE=LOCAL_ONLY
ALLOW_CLOUD_LLM=false           # an toàn — đảm bảo không gọi cloud
OLLAMA_BASE_URL=http://localhost:11434
QDRANT_URL=http://localhost:6333
AI_GATEWAY_INTERNAL_KEY=<cùng key với .NET API>
USE_MOCK_DATA=true
```

Index tài liệu nghiệp vụ vào Qdrant (1 lần):
```bash
.venv/Scripts/python.exe index_documents.py docs/   # đặt PDF/TXT trong ai-service/docs/
```

Khởi chạy như Mode A.

#### Mode C — `HYBRID_SAFE` (tasks chính local, report cloud)

`.env`: kết hợp cả 2:
```env
LLM_MODE=HYBRID_SAFE
ALLOW_CLOUD_LLM=true
OPENAI_API_KEY=sk-xxx           # cho report_generator
OLLAMA_BASE_URL=http://localhost:11434  # cho intent/answer/...
QDRANT_URL=http://localhost:6333
```

Khi muốn đổi mode runtime mà không restart, xem §5.1 bên dưới.

### 3.4. Mobile Flutter

```bash
cd mobile
flutter pub get
flutter run                    # debug trên emulator/device
# hoặc build APK release:
flutter build apk --release
```

API base URL config trong `lib/core/network/api_config.dart` — đảm bảo trỏ đúng `.NET API` host.

---

## 4. Test end-to-end

### 4.1. Health check toàn stack

```bash
# 1. SQL Server (qua .NET migration)
curl http://localhost:5000/health
# {"status":"healthy"}

# 2. .NET API → AI Gateway
curl http://localhost:5000/api/leader-ai/health
# {"status":"ok","aiGateway":"connected","latencyMs":42}

# 3. AI Gateway internal
curl http://localhost:8001/health
# {"status":"ok","phase":"4","llm_mode":"CLOUD_API",...}

# 4. AI Gateway provider availability
curl -H "X-Internal-Key: $KEY" http://localhost:8001/admin/llm-mode
# {"currentMode":"CLOUD_API","openaiKeyConfigured":true,...}
```

### 4.2. Chat thử (cần JWT của user `Loai = 6`)

```bash
# Lấy JWT (Loai=6 từ DB)
JWT=$(curl -s -X POST http://localhost:5000/api/oauth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"<leader_username>","password":"<password>"}' \
  | jq -r .access_token)

# Hỏi câu mẫu
curl -X POST http://localhost:5000/api/leader-ai/chat \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"message":"Tồn kho xăng dầu hôm nay thế nào?"}'
```

Expected response shape (Section 4.3 thiết kế):
```json
{
  "success": true,
  "conversationId": "<guid>",
  "intent": "FUEL_INVENTORY_SUMMARY",
  "answerText": "...",
  "data": { "summary": {...}, "chart": {...}, "table": [...] },
  "suggestedQuestions": ["...", "...", "..."],
  "rateLimitInfo": { "requestsToday": 1, "maxPerDay": 50 }
}
```

### 4.3. Test Flutter UI

1. Mở app → đăng nhập user `Loai = 6`
2. Bottom nav lãnh đạo → tap icon ✨ trên AppBar (góc trên phải)
3. Gõ "Tồn kho xăng dầu hôm nay?" → nhận response stream
4. Sau response → tap chip suggested question để hỏi tiếp

Test role denied: đăng nhập user `Loai ≠ 6` → không thấy icon ✨ (LeaderExecutiveAppBar chỉ hiện cho Loai=6).

---

## 5. Vận hành runtime

### 5.1. Đổi LLM mode không cần restart

```bash
# Đọc mode hiện tại
curl -H "X-Internal-Key: $KEY" http://localhost:8001/admin/llm-mode
# {
#   "currentMode": "CLOUD_API",
#   "bootMode": "CLOUD_API",
#   "overridden": false,
#   "openaiKeyConfigured": true,
#   "ollamaBaseUrl": "http://localhost:11434",
#   "availableModes": ["CLOUD_API","LOCAL_ONLY","HYBRID_SAFE"]
# }

# Switch sang LOCAL_ONLY
curl -X POST -H "X-Internal-Key: $KEY" \
  -H "Content-Type: application/json" \
  -d '{"mode":"LOCAL_ONLY"}' \
  http://localhost:8001/admin/llm-mode
```

⚠️ Override **chỉ in-memory** — restart sẽ reset về `LLM_MODE` trong `.env`. Để persist phải sửa `.env` rồi restart.

### 5.2. Prometheus metrics

```bash
curl http://localhost:8001/metrics
# 8 metric: ai_request_duration_ms, ai_request_total, ai_error_rate,
# ai_rate_limit_hits, ai_security_block_total, ai_tool_duration_ms,
# ai_llm_token_usage, ai_context_miss_rate
```

Add Prometheus job để Grafana scrape:
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'ai-gateway'
    static_configs:
      - targets: ['ai-gateway:8001']
```

### 5.3. Rate limit

Mặc định: 5/phút, 20/giờ, 50/ngày per user. Khi vượt → 429 với header `Retry-After`.

Đổi giới hạn trong `.NET appsettings.json`:
```json
"RateLimit": { "PerMinute": 10, "PerHour": 50, "PerDay": 200 }
```

UI Flutter tự cảnh báo amber khi `requestsToday < 10` (xem `LeaderAiChatScreen` AppBar).

### 5.4. Báo cáo PDF

```bash
curl -X POST -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"message":"Tình hình tồn kho hôm nay"}' \
  "http://localhost:5000/api/leader-ai/chat?format=pdf" \
  --output report.pdf
```

(Hoặc gọi trực tiếp AI Gateway: `POST /ai/leader/report?format=pdf`.)

### 5.5. Quản lý hội thoại

```bash
# List hội thoại của user
curl -H "Authorization: Bearer $JWT" \
  http://localhost:5000/api/leader-ai/conversations

# Detail
curl -H "Authorization: Bearer $JWT" \
  http://localhost:5000/api/leader-ai/conversations/<guid>

# Soft delete
curl -X DELETE -H "Authorization: Bearer $JWT" \
  http://localhost:5000/api/leader-ai/conversations/<guid>
```

### 5.6. Cleanup data (Section 12)

| Bảng | Giữ | Phương án |
|---|---|---|
| `AiConversations` | 90 ngày | Soft delete (`IsDeleted=1`) |
| `AiResultSnapshots` | 24 giờ (`ExpiresAt`) | Cron job xoá `WHERE ExpiresAt < SYSUTCDATETIME()` |
| `AiToolLogs` | 30 ngày | Cron `DELETE WHERE CreatedAt < DATEADD(DAY, -30, ...)` |
| `AiSecurityAuditLogs` | 1 năm | Archive sang cold storage |
| `AiRateLimitLogs` | 7 ngày | Cron hard delete |

Cron job mẫu (SQL Agent / cronjob Windows): chạy lúc 02:00 hằng đêm.

---

## 6. Troubleshooting

### 6.1. AI Gateway trả lỗi `LLM provider 'openai' cần env 'OPENAI_API_KEY' — chưa set`

→ Set `OPENAI_API_KEY` trong `.env` AI Gateway, hoặc switch sang `LOCAL_ONLY`.

### 6.2. `/health` báo `aiGateway: disconnected`

```bash
# Verify AI Gateway đang chạy
curl http://localhost:8001/health

# Verify .NET đọc đúng URL
grep AiGateway backend/src/Httm.XangDau.Api/appsettings.json
```

Nếu .NET và AI Gateway khác máy: chỉnh `AiGateway:BaseUrl` thành IP/hostname đúng.

### 6.3. Mobile app không thấy icon ✨ Loca AI

User chưa phải `Loai = 6`. Kiểm tra:
```sql
SELECT Id, UserName, Loai FROM AspNetUsers WHERE UserName = '<user>';
-- Loai phải = 6
```

### 6.4. SecurityGuard chặn câu hỏi hợp lệ

Câu hỏi vô tình trùng pattern Section 13.2 (`SELECT * FROM`, `bypass`, ...). Kiểm tra log structlog:
```bash
# AI Gateway log
grep security_audit ai-service.log
# Xem pattern matched
```

Sửa câu hỏi không dùng từ khoá nhạy cảm. Pattern list trong [`ai-service/app/security/prompt_injection.py`](../ai-service/app/security/prompt_injection.py).

### 6.5. Latency > 30s với LOCAL_ONLY

Xem [`PHASE4_SETUP.md`](../ai-service/PHASE4_SETUP.md) §6 — checklist GPU / prompt size / cache.

### 6.6. Test thất bại sau pull mới

```bash
# .NET
cd backend
dotnet test tests/Httm.XangDau.Api.Tests/Httm.XangDau.Api.Tests.csproj

# AI Gateway
cd ai-service
.venv/Scripts/python.exe -m pytest app/tests

# Flutter
cd mobile
flutter analyze
```

Hiện tại baseline: .NET 42 pass, AI Gateway 117 pass, Flutter analyze 0 issue (Phase 2B).

---

## 7. Bảo mật check-list trước khi deploy production

- [ ] `OPENAI_API_KEY`, `AI_GATEWAY_INTERNAL_KEY`, `Jwt:SigningKey` không có trong git history (`git log -p | grep -i "sk-"`)
- [ ] `appsettings.Production.json` chứa connection string không cùng credential với dev DB
- [ ] AI Gateway listen `0.0.0.0` chỉ trong internal network (firewall block port 8001 từ public)
- [ ] `.env` không commit (đã gitignore — verify `git ls-files | grep "\.env$"`)
- [ ] Prometheus `/metrics` không expose ra public (chỉ scraper internal)
- [ ] HTTPS bật cho .NET API (mobile yêu cầu)
- [ ] Rate limit phù hợp tải dự kiến (xem dashboard `ai_request_total` để tune)
- [ ] LLM_MODE production: tránh `LOCAL_ONLY` nếu chưa test load với GPU thật
- [ ] Cron cleanup `AiResultSnapshots` đã setup (24h TTL)

---

## 8. Tóm tắt CLI quick reference

| Việc | Lệnh |
|---|---|
| Build .NET | `dotnet build` từ `backend/` |
| Run .NET | `dotnet run --project src/Httm.XangDau.Api/...` |
| Test .NET | `dotnet test tests/Httm.XangDau.Api.Tests/...` |
| Run AI Gateway | `.venv/Scripts/python.exe -m uvicorn app.main:app --port 8001` |
| Test AI Gateway | `.venv/Scripts/python.exe -m pytest app/tests` |
| Index docs | `.venv/Scripts/python.exe index_documents.py docs/` |
| Build Flutter | `flutter build apk --release` |
| Switch mode runtime | `curl -X POST -H "X-Internal-Key: $K" -d '{"mode":"LOCAL_ONLY"}' :8001/admin/llm-mode` |
| Đọc mode | `curl :8001/health` (field `llm_mode`) |
| Metrics | `curl :8001/metrics` |

---

*Tài liệu này là quick-start; chi tiết design trong [`loca-ai-leader-v2.md`](loca-ai-leader-v2.md).*
