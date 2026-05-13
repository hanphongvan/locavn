# Loca AI — Runbook lệnh vận hành

Cheat sheet các lệnh thường dùng cho **Whisper API**, **Qdrant**, **AI Service** trên môi trường dev Windows. Mọi đường dẫn theo máy `D:\projects\httm-xangdau\`.

Convention:
- Whisper API listen `:7000`
- AI Service listen `:8001`
- Qdrant listen `:6333` (HTTP) + `:6334` (gRPC)
- Backend .NET listen `:5111` (local) hoặc `https://xdapi.dms.gov.vn` (prod)

---

## 1. Whisper API (speech-to-text)

### 1.1 Chạy thủ công (foreground)

```powershell
cd D:\AI\whisper-test
.venv\Scripts\activate
uvicorn app:app --host 0.0.0.0 --port 7000
```

Test endpoint:
```powershell
curl -X POST "http://localhost:7000/speech-to-text" `
  -H "Content-Type: multipart/form-data" `
  -F "file=@audio.mp3"
```

### 1.2 Tạo Windows service qua Task Scheduler (chạy ẩn)

```cmd
schtasks /Create /TN "WhisperAPI" ^
  /TR "wscript.exe D:\AI\whisper-test\run-hidden.vbs" ^
  /SC ONSTART /RL HIGHEST /F
```
- `/SC ONSTART` — auto start khi Windows boot
- `/RL HIGHEST` — chạy với quyền cao nhất
- `/F` — force overwrite nếu task đã tồn tại

### 1.3 Start / Restart / Delete

```cmd
schtasks /Run /TN "WhisperAPI"      :: start
schtasks /End /TN "WhisperAPI"      :: stop (restart = End rồi Run)
schtasks /Run /TN "WhisperAPI"
schtasks /Delete /TN "WhisperAPI" /F  :: xóa hoàn toàn
```

---

## 2. Qdrant (vector DB)

Chi tiết đầy đủ: [ai-service/PHASE4_SETUP.md section 2](../ai-service/PHASE4_SETUP.md#L28).

### 2.1 Start container (đã tạo từ trước)

```powershell
docker start locavn-qdrant
docker ps --filter "name=locavn-qdrant"   # verify Up + healthy
```

### 2.2 Lần đầu — tạo mới (chỉ chạy 1 lần)

```powershell
New-Item -ItemType Directory -Path D:\qdrant_storage -Force | Out-Null
docker run -d --name locavn-qdrant `
  -p 6333:6333 -p 6334:6334 `
  -v D:\qdrant_storage:/qdrant/storage `
  qdrant/qdrant
```

### 2.3 Verify

```powershell
curl http://localhost:6333/collections
# Expect: {"result":{"collections":[{"name":"ai_schema_catalog"}]},"status":"ok",...}
```

Dashboard UI: <http://localhost:6333/dashboard>

### 2.4 Re-seed schema catalog (sau khi reset Qdrant)

```powershell
cd D:\projects\httm-xangdau\ai-service
.venv\Scripts\python.exe scripts\index_schema_catalog.py --verbose
```

---

## 3. AI Service (FastAPI gateway)

### 3.1 Chạy thủ công (foreground — log ra terminal)

```powershell
cd D:\projects\httm-xangdau\ai-service
.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8001
```

### 3.2 Chạy ẩn (production-style — log ra file)

VBS wrapper đã có sẵn:
```cmd
wscript D:\projects\httm-xangdau\ai-service\run-ai-service-hidden.vbs
```

Log file: `D:\projects\httm-xangdau\ai-service\logs\ai-service.log`

### 3.3 Tạo Windows service qua Task Scheduler

```cmd
schtasks /Create /TN "HTTM_AI_Service" ^
  /TR "wscript.exe D:\projects\httm-xangdau\ai-service\run-ai-service-hidden.vbs" ^
  /SC ONSTART /RL HIGHEST /F
```

### 3.4 Start / Restart / Delete

```cmd
schtasks /Run /TN "HTTM_AI_Service"     :: start
schtasks /End /TN "HTTM_AI_Service"     :: stop
schtasks /Run /TN "HTTM_AI_Service"     :: start lại
schtasks /Delete /TN "HTTM_AI_Service" /F   :: xóa
```

### 3.5 Toggle log level DEBUG/INFO (runtime, không restart)

Lấy key internal từ `.env`:
```powershell
$KEY = (Select-String -Path D:\projects\httm-xangdau\ai-service\.env `
        -Pattern 'AI_GATEWAY_INTERNAL_KEY=(.+)').Matches.Groups[1].Value
```

**Bật DEBUG** (khi cần điều tra "không cung cấp được thông tin"):
```powershell
Invoke-RestMethod -Method Post -Uri http://localhost:8001/admin/log-level `
  -Headers @{'X-Internal-Key'=$KEY} -ContentType 'application/json' `
  -Body '{"level":"DEBUG"}'
```

**Tắt DEBUG** (sau khi xong — DEBUG log câu hỏi + answer text, không nên để mãi):
```powershell
Invoke-RestMethod -Method Post -Uri http://localhost:8001/admin/log-level `
  -Headers @{'X-Internal-Key'=$KEY} -ContentType 'application/json' `
  -Body '{"level":"INFO"}'
```

**Xem level hiện tại**:
```powershell
Invoke-RestMethod -Uri http://localhost:8001/admin/log-level -Headers @{'X-Internal-Key'=$KEY}
```

### 3.6 Tail log realtime

```powershell
# Tail 100 dòng cuối + theo dõi tiếp
Get-Content -Tail 100 -Wait D:\projects\httm-xangdau\ai-service\logs\ai-service.log

# Filter chỉ pipeline events (bỏ noise httpx/uvicorn)
Get-Content -Tail 0 -Wait D:\projects\httm-xangdau\ai-service\logs\ai-service.log |
  Where-Object { $_ -match 'security_guard|intent_classifier|schema_retriever|plan_generator|dynamic_query|answer_composer\.branch|sp_request_payload|latest_period' }
```

---

## 4. Utilities

### 4.1 Check process đang nghe port

```powershell
# Theo port
netstat -ano | Select-String ":8001"
netstat -ano | Select-String ":7000"
netstat -ano | Select-String ":6333"

# Theo PID — chi tiết process
Get-Process -Id <PID>
```

### 4.2 Kill process theo PID

```cmd
taskkill /PID 32772 /F
```

Hoặc PowerShell:
```powershell
Stop-Process -Id 32772 -Force
```

### 4.3 Find + kill process đang nghe port

```powershell
Get-NetTCPConnection -LocalPort 8001 -State Listen |
  ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
```

---

## 5. Test endpoints (sanity check)

Có 2 đường gọi LocaAI:
- **Qua backend** `https://xdapi.dms.gov.vn/api/leader-ai/chat` — chuẩn (như app gọi), cần JWT của user `Loai=6`.
- **Trực tiếp AI Gateway** `http://localhost:8001/ai/leader/chat` — bypass backend, cần header `X-Internal-Key`. Dùng để cô lập bug AI service vs backend.

### 5.1 Lấy JWT (OAuth password grant)

```powershell
$tokenBody = @{
    grant_type = "password"
    username   = "leader"
    password   = "123456"
}
$resp = Invoke-RestMethod -Method Post `
    -Uri https://xdapi.dms.gov.vn/api/oauth/token `
    -Body $tokenBody `
    -ContentType "application/x-www-form-urlencoded"

$JWT = $resp.access_token
echo $JWT   # token dài ~500 ký tự, base64-encoded
```

### 5.2 Test chat đơn giản qua backend (1 turn)

```powershell
$body = '{"message":"Quỹ bình ổn còn bao nhiêu tiền?"}'
$body | Out-File body.json -Encoding utf8 -NoNewline

curl.exe -X POST https://xdapi.dms.gov.vn/api/leader-ai/chat `
    -H "Authorization: Bearer $JWT" `
    -H "Content-Type: application/json; charset=utf-8" `
    --data-binary "@body.json" `
    -o response.json
notepad response.json
```

Dùng `curl.exe` + `--data-binary "@file"` thay vì `Invoke-RestMethod -Body` để **giữ đúng UTF-8** cho tiếng Việt (Invoke-RestMethod có thể auto-encode sai dấu).

### 5.3 Test conversation context (multi-turn — verify context_resolver)

```powershell
# Turn 1 — câu đầy đủ
$body = '{"message":"Tồn kho xăng dầu hôm nay thế nào?"}'
$body | Out-File body.json -Encoding utf8 -NoNewline

curl.exe -X POST https://xdapi.dms.gov.vn/api/leader-ai/chat `
    -H "Authorization: Bearer $JWT" `
    -H "Content-Type: application/json; charset=utf-8" `
    --data-binary "@body.json" `
    -o response.json

# Lấy conversationId từ response
$convId = (Get-Content response.json | ConvertFrom-Json).conversationId
echo "ConvId: $convId"

# Turn 2 — câu rút gọn (server phải resolve thành "Tồn kho dầu DO...")
$body2 = @{ message = "Còn dầu thì sao?"; conversationId = $convId } | ConvertTo-Json
$body2 | Out-File body2.json -Encoding utf8 -NoNewline

curl.exe -X POST https://xdapi.dms.gov.vn/api/leader-ai/chat `
    -H "Authorization: Bearer $JWT" `
    -H "Content-Type: application/json; charset=utf-8" `
    --data-binary "@body2.json" `
    -o response2.json

# Verify resolvedQuestion đã expand đầy đủ
(Get-Content response2.json | ConvertFrom-Json).resolvedQuestion
# Mong đợi: "Tồn kho dầu DO ..." (LLM đã hiểu context từ turn 1)
```

### 5.4 Test trực tiếp AI Gateway (bypass backend)

Dùng khi muốn cô lập: bug ở backend hay ở AI service?

```powershell
$KEY = (Select-String -Path D:\projects\httm-xangdau\ai-service\.env `
        -Pattern 'AI_GATEWAY_INTERNAL_KEY=(.+)').Matches.Groups[1].Value

curl.exe -X POST http://localhost:8001/ai/leader/chat `
    -H "Content-Type: application/json" `
    -H "X-Internal-Key: $KEY" `
    -d '{"message":"Quỹ bình ổn còn bao nhiêu tiền?","userId":1,"userLoai":6}'
```

Sau đó tail log AI service (section 3.6) để xem các event pipeline.

### 5.5 Verify pipeline events sau khi test

```powershell
# Find log warning intent_classifier fallback
Select-String -Path D:\projects\httm-xangdau\ai-service\logs\ai-service.log `
              -Pattern 'intent_classifier\.fallback_unknown' | Select-Object -Last 5

# Find security block
Select-String -Path D:\projects\httm-xangdau\ai-service\logs\ai-service.log `
              -Pattern 'security_guard\.blocked' | Select-Object -Last 5

# Find tool errors (timeout/network)
Select-String -Path D:\projects\httm-xangdau\ai-service\logs\ai-service.log `
              -Pattern 'tool\.sp_call_failed|dotnet_api\.sp_timeout' | Select-Object -Last 5
```

---

## 6. Workflow điển hình — debug "LocaAI trả lời sai"

Theo memory `triage_loca_ai_wrong_answer.md`:

1. **Verify dependencies chạy đủ**:
   ```powershell
   docker ps --filter "name=locavn-qdrant"   # Qdrant Up?
   netstat -ano | Select-String ":8001"      # AI service Up?
   netstat -ano | Select-String ":5111"      # Backend Up? (hoặc check xdapi.dms.gov.vn)
   ```

2. **Bật DEBUG**:
   ```powershell
   $KEY = (Select-String -Path D:\projects\httm-xangdau\ai-service\.env -Pattern 'AI_GATEWAY_INTERNAL_KEY=(.+)').Matches.Groups[1].Value
   Invoke-RestMethod -Method Post -Uri http://localhost:8001/admin/log-level -Headers @{'X-Internal-Key'=$KEY} -ContentType 'application/json' -Body '{"level":"DEBUG"}'
   ```

3. **Tail log filtered** (terminal khác):
   ```powershell
   Get-Content -Tail 0 -Wait D:\projects\httm-xangdau\ai-service\logs\ai-service.log |
     Where-Object { $_ -match 'security_guard|intent_classifier|schema_retriever|plan_generator|dynamic_query|answer_composer\.branch' }
   ```

4. **Reproduce câu hỏi trên app** — đọc các event xuất hiện theo thứ tự để biết bước nào fail.

5. **Tắt DEBUG sau khi xong**:
   ```powershell
   Invoke-RestMethod -Method Post -Uri http://localhost:8001/admin/log-level -Headers @{'X-Internal-Key'=$KEY} -ContentType 'application/json' -Body '{"level":"INFO"}'
   ```

---

## 7. Liên kết

- [PHASE4_SETUP.md](../ai-service/PHASE4_SETUP.md) — setup Ollama + Qdrant chi tiết
- [loca-ai-leader-v2.md](loca-ai-leader-v2.md) — thiết kế tổng thể Loca AI
- [loca-ai-phase5.md](loca-ai-phase5.md) — schema catalog + dynamic query
- [loca-ai-usage.md](loca-ai-usage.md) — hướng dẫn dùng trên app
