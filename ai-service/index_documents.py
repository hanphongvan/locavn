"""Phase 4 — script index tài liệu nghiệp vụ vào Qdrant.

Usage:
    cd ai-service
    .venv/Scripts/python.exe index_documents.py docs/                # index folder
    .venv/Scripts/python.exe index_documents.py docs/ngh-quyet.pdf   # index 1 file

Yêu cầu môi trường:
- Ollama đang chạy + đã `ollama pull bge-m3`.
- Qdrant đang chạy (Docker: `docker run -p 6333:6333 qdrant/qdrant`).
- File `.env` có `OLLAMA_BASE_URL`, `QDRANT_URL`.

Chunk strategy: split theo paragraph rồi ghép tối đa ~500 token (~2000 ký tự
tiếng Việt) — cân bằng giữa context Qdrant trả về và độ chính xác semantic.
"""
from __future__ import annotations

import asyncio
import re
import sys
from pathlib import Path

# Cho phép chạy script trực tiếp (không qua module).
ROOT = Path(__file__).parent
sys.path.insert(0, str(ROOT))

from app.config import get_settings  # noqa: E402
from app.services.embedding_service import EmbeddingService  # noqa: E402
from app.services.logging_service import configure_logging, get_logger  # noqa: E402
from app.services.qdrant_service import QdrantService  # noqa: E402

_logger = get_logger(__name__)


CHUNK_CHAR_LIMIT = 2000  # ~500 token tiếng Việt.
CHUNK_OVERLAP = 200      # giữ overlap để chunk biên không mất ngữ cảnh.


def chunk_text(text: str) -> list[str]:
    """Chunk theo paragraph, ghép cho đến gần `CHUNK_CHAR_LIMIT`. Phase 4
    đơn giản — không dùng tiktoken vì model qwen3 ≠ tiktoken token.
    """
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
    chunks: list[str] = []
    buf: list[str] = []
    buf_len = 0

    for para in paragraphs:
        if buf_len + len(para) <= CHUNK_CHAR_LIMIT:
            buf.append(para)
            buf_len += len(para) + 2
            continue
        if buf:
            chunks.append("\n\n".join(buf))
        # Paragraph dài quá → hard split (rare).
        if len(para) > CHUNK_CHAR_LIMIT:
            for i in range(0, len(para), CHUNK_CHAR_LIMIT - CHUNK_OVERLAP):
                chunks.append(para[i:i + CHUNK_CHAR_LIMIT])
            buf = []
            buf_len = 0
        else:
            buf = [para]
            buf_len = len(para)
    if buf:
        chunks.append("\n\n".join(buf))
    return chunks


def read_pdf(path: Path) -> str:
    """Trả text của PDF — concat từng page với marker '\\n\\n[Page N]\\n\\n'."""
    from pypdf import PdfReader  # lazy import — chỉ dev/index cần.

    reader = PdfReader(str(path))
    parts: list[str] = []
    for page_idx, page in enumerate(reader.pages, start=1):
        text = page.extract_text() or ""
        if text.strip():
            parts.append(f"[Page {page_idx}]\n{text.strip()}")
    return "\n\n".join(parts)


def read_text_file(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def collect_files(target: Path) -> list[Path]:
    if target.is_file():
        return [target]
    if not target.is_dir():
        raise FileNotFoundError(f"Không thấy {target}")
    files: list[Path] = []
    for ext in ("*.pdf", "*.txt", "*.md"):
        files.extend(sorted(target.rglob(ext)))
    return files


async def index_one_file(
    path: Path,
    embedding: EmbeddingService,
    qdrant: QdrantService,
) -> int:
    if path.suffix.lower() == ".pdf":
        full_text = read_pdf(path)
    else:
        full_text = read_text_file(path)

    if not full_text.strip():
        _logger.warning("index.empty_file", path=str(path))
        return 0

    chunks = chunk_text(full_text)
    if not chunks:
        return 0

    _logger.info("index.embedding", path=str(path), chunks=len(chunks))
    vectors = await embedding.embed_batch(chunks)

    rel_source = str(path.name)
    upserts = [
        (
            chunk,
            vector,
            {
                "source": rel_source,
                "path": str(path),
                "chunk_index": idx,
                "ext": path.suffix.lower().lstrip("."),
            },
        )
        for idx, (chunk, vector) in enumerate(zip(chunks, vectors, strict=True))
    ]
    inserted = await qdrant.upsert(upserts)
    _logger.info("index.upserted", path=str(path), count=inserted)
    return inserted


async def main(target_arg: str) -> None:
    configure_logging(level="INFO", json_format=False)
    settings = get_settings()
    target = Path(target_arg).resolve()
    files = collect_files(target)
    if not files:
        _logger.warning("index.no_files", target=str(target))
        return

    embedding = EmbeddingService(base_url=settings.ollama_base_url)
    qdrant = QdrantService(url=settings.qdrant_url)
    await qdrant.ensure_collection()

    total = 0
    for f in files:
        try:
            total += await index_one_file(f, embedding, qdrant)
        except Exception as ex:
            _logger.error("index.file_failed", path=str(f), error=str(ex))
    _logger.info("index.done", total_chunks=total, total_files=len(files))
    await qdrant.close()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python index_documents.py <folder|file>")
        sys.exit(1)
    asyncio.run(main(sys.argv[1]))
