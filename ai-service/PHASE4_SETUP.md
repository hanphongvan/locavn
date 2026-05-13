# Phase 4 — Setup local LLM (Ollama) + RAG (Qdrant)

Hướng dẫn bật chế độ `LLM_MODE=LOCAL_ONLY` cho AI Gateway. Khi chạy đúng, mọi
request vào pipeline KHÔNG có outbound HTTP tới `api.openai.com` — verify bằng
firewall log hoặc `tcpdump`.

## 1. Cài Ollama + pull models

```bash
# macOS / Linux
curl -fsSL https://ollama.com/install.sh | sh

# Windows: tải installer https://ollama.com/download

# Pull models (dung lượng: qwen3:8b ~5GB, qwen3:14b ~9GB, bge-m3 ~1.2GB)
ollama pull qwen3:8b
ollama pull qwen3:14b
ollama pull bge-m3

# Verify
curl http://localhost:11434/api/tags
```

Yêu cầu phần cứng đề xuất: GPU ≥ 12GB VRAM cho qwen3:14b. Nếu chỉ có
qwen3:8b, sửa `app/config/models.yaml` block `models_local` → đổi mọi `name`
thành `qwen3:8b`.

## 2. Cài / khởi động Qdrant

Convention team: container đặt tên `locavn-qdrant`, storage mount `D:\qdrant_storage`,
expose port `6333` (HTTP) + `6334` (gRPC). Yêu cầu **Docker Desktop đang chạy**
(verify: icon con cá voi xanh ở system tray).

### 2.1 Trường hợp lần đầu — tạo container mới

**Linux/macOS:**
```bash
docker run -d --name locavn-qdrant \
  -p 6333:6333 -p 6334:6334 \
  -v $(pwd)/qdrant_storage:/qdrant/storage \
  qdrant/qdrant
```

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Path D:\qdrant_storage -Force | Out-Null
docker run -d --name locavn-qdrant `
  -p 6333:6333 -p 6334:6334 `
  -v D:\qdrant_storage:/qdrant/storage `
  qdrant/qdrant
```

### 2.2 Trường hợp container đã tồn tại — chỉ start lại

Sau khi reboot máy hoặc tắt Docker Desktop, container đã tạo nhưng đang `Exited`.
KHÔNG cần `docker run` lại (sẽ báo conflict tên), chỉ cần start:

```powershell
# Kiểm tra trạng thái container
docker ps -a --filter "name=locavn-qdrant"

# Nếu thấy STATUS = "Exited..." → start lại
docker start locavn-qdrant

# Verify đã Up + healthy (chờ ~5s sau start)
docker ps --filter "name=locavn-qdrant"
```

Storage tại `D:\qdrant_storage` persist giữa các lần start → collection
`ai_schema_catalog` + `loca_documents` giữ nguyên, KHÔNG cần re-index lại.

### 2.3 Verify Qdrant reachable

```powershell
# REST endpoint
curl http://localhost:6333/collections
# Expect: {"result":{"collections":[{"name":"ai_schema_catalog"},...]},"status":"ok","time":...}

# Web UI (xem collection trực quan)
# Mở trình duyệt: http://localhost:6333/dashboard
```

### 2.4 Troubleshoot

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `curl: Failed to connect to localhost port 6333` | Container chưa start | `docker start locavn-qdrant` |
| `docker: failed to connect to the docker API` | Docker Desktop daemon chưa chạy | Mở Docker Desktop từ Start menu, chờ icon cá voi xanh |
| `docker: Error response: Conflict. The container name "/locavn-qdrant" is already in use` | Container đã tồn tại → đừng `run` mà `start` | `docker start locavn-qdrant` |
| Collection `ai_schema_catalog` trống sau start | Volume mount path sai → mất data persist | Verify `docker inspect locavn-qdrant` → check `Mounts.Source` |

### 2.5 Auto-start Docker Desktop cùng Windows

Docker Desktop mặc định KHÔNG auto-start khi login Windows. Để Qdrant
sẵn sàng mỗi lần khởi động máy:

1. Mở **Docker Desktop** → **Settings** → **General**
2. Tick **"Start Docker Desktop when you sign in"**
3. Apply & Restart Docker Desktop

Container `locavn-qdrant` có `--restart` policy mặc định là `no`. Nếu muốn
Qdrant cũng auto-start khi Docker daemon start:
```powershell
docker update --restart unless-stopped locavn-qdrant
```

## 3. Cấu hình `.env`

Đổi `ai-service/.env` (copy từ `.env.example`):

```env
LLM_MODE=LOCAL_ONLY
ALLOW_CLOUD_LLM=false
OLLAMA_BASE_URL=http://localhost:11434
QDRANT_URL=http://localhost:6333

# Vẫn cần để gọi ngược .NET API (audit log, context summary).
AI_GATEWAY_INTERNAL_KEY=<sync với .NET appsettings>
DOTNET_API_BASE_URL=http://localhost:5000
```

## 4. Index tài liệu nghiệp vụ vào Qdrant

Đặt PDF/TXT tài liệu (Nghị định 95, hướng dẫn dashboard, ...) trong
`ai-service/docs/`, rồi chạy:

```bash
cd ai-service
.venv/Scripts/python.exe index_documents.py docs/        # index folder
.venv/Scripts/python.exe index_documents.py docs/x.pdf   # index 1 file
```

Script tự tạo collection `loca_documents` (1024-dim cho bge-m3) nếu chưa có.

## 5. Chạy AI Gateway

```bash
cd ai-service
.venv/Scripts/python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8001
```

Smoke verify LOCAL_ONLY:

```bash
# Health probe — phải có "llm_mode": "LOCAL_ONLY".
curl http://localhost:8001/health

# 1 request chat (không cần OpenAI key).
curl -X POST http://localhost:8001/ai/leader/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Tồn kho xăng dầu hôm nay?","userId":42,"userLoai":6}'

# Verify metric latency:
curl http://localhost:8001/metrics | grep ai_request_duration_ms
```

## 6. End-to-end latency target

Phase 4 yêu cầu < 30s/request. Đo qua metric `ai_request_duration_ms`
(histogram) — kiểm tra p95 dưới 30000:

```bash
# Sau khi đã chạy vài request:
curl -s http://localhost:8001/metrics | \
  grep -E 'ai_request_duration_ms_bucket\{.*intent="FUEL_INVENTORY_SUMMARY".*le="30000"\}'
```

Nếu p95 > 30s, các tinh chỉnh phổ biến:

| Vấn đề | Cách fix |
|---|---|
| qwen3:14b chậm trên CPU | Buộc GPU: `OLLAMA_NUM_GPU=99` |
| Prompt quá dài | Giảm history forward về 5 msg (Phase 3 đã trim) |
| Cache miss nhiều | Chuyển `CACHE_BACKEND=redis` để share giữa worker |
| RAG search > 1s | Tạo index Qdrant với `quantization` (Phase 5) |

## 7. Switch giữa OpenAI ↔ Ollama runtime (không cần restart)

Phase 4+ thêm `/admin/llm-mode` cho ops hoặc demo nhanh giữa các mode.
Bảo vệ bằng `X-Internal-Key` (cùng `AiGateway:InternalKey`).

```bash
# Đọc mode hiện tại + provider availability.
curl -H "X-Internal-Key: $AI_GATEWAY_INTERNAL_KEY" \
  http://localhost:8001/admin/llm-mode
# {
#   "currentMode": "CLOUD_API",
#   "bootMode": "CLOUD_API",
#   "overridden": false,
#   "openaiKeyConfigured": true,
#   "ollamaBaseUrl": "http://localhost:11434",
#   "availableModes": ["CLOUD_API", "LOCAL_ONLY", "HYBRID_SAFE"]
# }

# Chuyển sang LOCAL_ONLY (qwen3) cho demo dữ liệu nhạy cảm.
curl -X POST -H "X-Internal-Key: $AI_GATEWAY_INTERNAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"mode":"LOCAL_ONLY"}' \
  http://localhost:8001/admin/llm-mode
# {"currentMode":"LOCAL_ONLY","message":"Đã chuyển sang LOCAL_ONLY."}

# Chuyển ngược về CLOUD_API.
curl -X POST -H "X-Internal-Key: $AI_GATEWAY_INTERNAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"mode":"CLOUD_API"}' \
  http://localhost:8001/admin/llm-mode

# Hoặc HYBRID_SAFE (Section 10.1 — task chính local, report cloud).
curl -X POST -H "X-Internal-Key: $AI_GATEWAY_INTERNAL_KEY" \
  -d '{"mode":"HYBRID_SAFE"}' http://localhost:8001/admin/llm-mode
```

**Lưu ý:**
- Override **chỉ in-memory** — restart service sẽ reset về `LLM_MODE` trong `.env`. Đây là design có chủ ý: prod env không bị "kẹt" mode sai.
- Để persist qua restart, sửa `.env` rồi restart service.
- Mode đang dùng cũng hiện trong `/health` + `/ai/leader/health` (`llm_mode` + `boot_mode` + `overridden` flag) — Flutter/Quản trị có thể đọc để hiển thị badge.

## 8. Verify không có outbound OpenAI

Trên máy chạy AI Gateway, monitor:

```bash
# Linux/macOS
sudo tcpdump -i any 'host api.openai.com' -nn

# Windows PowerShell (cần admin)
Get-NetTCPConnection | Where-Object RemoteAddress -like "*openai*"
```

Bắn 5 câu mẫu Section 18 vào `/ai/leader/chat` rồi confirm zero packets gửi
tới `api.openai.com`. Đây là kiểm chứng cuối cùng cho LOCAL_ONLY.

## 9. Limitations & known issues

- **Ollama không support batch embedding** — `index_documents.py` chạy tuần tự.
  Index 100 PDF có thể mất 5-10 phút trên RTX 3090.
- **qwen3 JSON mode** đôi khi rò rỉ markdown code fence — `OllamaProvider.chat_json`
  raise `OllamaProviderError("non-JSON")` và LangGraph fallback xuống template.
  Theo dõi `ai_error_rate` metric.
- **Prometheus multi-process**: hiện tại chạy 1 worker uvicorn. Khi scale
  multi-worker phải set `prometheus_multiproc_dir` và dùng `MultiProcessCollector`.
