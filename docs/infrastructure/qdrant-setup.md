# Qdrant — Setup & Operations

## Mục đích

Qdrant là vector database dùng cho Retrieval-Augmented Generation (RAG)
trong AI Gateway:

- **Phase 4 (đã code):** collection `loca_documents` — index PDF/markdown
  hướng dẫn nghiệp vụ. Embeddings sinh từ Ollama `bge-m3`.
- **Phase 5D (chưa làm):** collection `ai_schema_catalog` — index metadata
  bảng/cột để LLM lookup khi sinh SQL.

Code reference:
- [ai-service/app/services/qdrant_service.py](../../ai-service/app/services/qdrant_service.py)
- [ai-service/app/tools/document_rag_tool.py](../../ai-service/app/tools/document_rag_tool.py)
- [ai-service/scripts/index_documents.py](../../ai-service/scripts/index_documents.py)

## Topology

- Qdrant chạy trong Docker, được orchestrate bởi
  [docker-compose.yml](../../docker-compose.yml) ở root project.
- AI Gateway (`ai-service/`) hiện chạy uvicorn LOCAL trên host, không
  trong cùng compose stack → connect qua `http://localhost:6333` (đã set
  trong `ai-service/.env: QDRANT_URL`).
- Network `locavn-ai-network` được khai báo sẵn để sau này nếu
  compose-hoá AI Gateway thì join chung mà không cần sửa Qdrant.

| Mục | Giá trị |
|---|---|
| Container name | `locavn-qdrant` |
| Image | `qdrant/qdrant:v1.12.1` (PIN — match `qdrant-client` 1.12.1) |
| HTTP port | `6333` |
| gRPC port | `6334` |
| Volume | `locavn-qdrant-storage` (named volume) |
| Restart policy | `unless-stopped` |

## Lệnh thường dùng

```bash
# Khởi động (start container + chờ tới khi API trả lời)
bash scripts/qdrant-up.sh

# Dừng (giữ nguyên dữ liệu trong volume)
bash scripts/qdrant-down.sh

# Kiểm tra trạng thái container + API + collections + volume mountpoint
bash scripts/qdrant-status.sh

# CẨN THẬN: Xóa toàn bộ embedding (xóa container + volume)
bash scripts/qdrant-reset.sh
```

## Volume & dữ liệu

`locavn-qdrant-storage` là **named volume** của Docker:

- Persist khi container bị xóa (`docker-compose rm`).
- KHÔNG persist khi volume bị xóa (`docker volume rm` hoặc `qdrant-reset.sh`).
- Mountpoint thật sự nằm trong Docker storage (xem `qdrant-status.sh`).

### Backup

```bash
docker run --rm \
  -v locavn-qdrant-storage:/data \
  -v "$(pwd)":/backup \
  alpine \
  tar czf /backup/qdrant-backup-$(date +%F).tar.gz /data
```

### Restore (vào volume mới)

```bash
# Tạo volume nếu chưa có
docker volume create locavn-qdrant-storage

# Giải nén backup vào volume
docker run --rm \
  -v locavn-qdrant-storage:/data \
  -v "$(pwd)":/backup \
  alpine \
  sh -c "cd /data && tar xzf /backup/qdrant-backup-YYYY-MM-DD.tar.gz --strip-components=1"
```

## Version pinning

Image Docker và `qdrant-client` Python phải MATCH version để tránh
incompatibility (REST/gRPC schema có thể đổi giữa minor releases).

| Vị trí | Version hiện tại |
|---|---|
| `docker-compose.yml` → `services.qdrant.image` | `qdrant/qdrant:v1.12.1` |
| `ai-service/requirements.txt` | `qdrant-client==1.12.1` |

**Khi nâng cấp:**
1. Nâng cả hai cùng lúc (image + client).
2. Test re-index `loca_documents` đảm bảo embedding/payload còn đúng schema.
3. Backup volume trước khi nâng (xem mục Backup).

## Healthcheck

Image `qdrant/qdrant` minimal không có sẵn `curl`/`wget` → healthcheck dùng
bash TCP probe vào port 6333:

```yaml
test: ["CMD-SHELL", "bash -c ':> /dev/tcp/127.0.0.1/6333' || exit 1"]
```

Probe thành công khi server đang lắng nghe TCP. Không kiểm tra HTTP body,
nhưng đủ tốt cho mục đích "container đã sẵn sàng nhận request".

## Troubleshooting

- **`qdrant-up.sh` báo "did not become ready within 30s"**
  → Xem log: `docker-compose logs --tail=100 qdrant`. Thường do port
    6333 đã bị process khác chiếm trên host.
- **AI Gateway không kết nối được**
  → Check `ai-service/.env: QDRANT_URL=http://localhost:6333` (KHÔNG đổi
    thành `http://qdrant:6333` trừ khi đã compose-hoá AI Gateway).
- **Mất dữ liệu sau khi restart máy**
  → Đã dùng named volume `locavn-qdrant-storage`, dữ liệu KHÔNG mất khi
    chỉ stop/start. Chỉ mất khi chạy `qdrant-reset.sh` hoặc `docker
    volume rm`.

## Roadmap

- [x] Phase 4 — collection `loca_documents` (đã code, sẽ index ở session sau).
- [ ] Phase 5D — collection `ai_schema_catalog` cho schema lookup khi sinh SQL.
