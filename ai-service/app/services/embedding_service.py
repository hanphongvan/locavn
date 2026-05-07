"""Embedding service — Phase 4 dùng Ollama `POST /api/embeddings` với model bge-m3.

Lý do chọn bge-m3:
- Multilingual (đặc biệt tốt với tiếng Việt).
- Chiều embedding 1024 (cân bằng giữa chất lượng và kích thước index).
- Đã được Ollama hỗ trợ chính thức (`ollama pull bge-m3`).

Không phụ thuộc sentence-transformers/torch để runtime nhẹ. Khi LLM_MODE=LOCAL_ONLY
mọi outbound trên máy GPU server, không gọi cloud.
"""
from __future__ import annotations

from dataclasses import dataclass

import httpx

from .logging_service import get_logger

_logger = get_logger(__name__)


class EmbeddingError(Exception):
    pass


@dataclass(frozen=True, slots=True)
class EmbeddingService:
    base_url: str
    model: str = "bge-m3"
    timeout: float = 30.0

    async def embed(self, text: str) -> list[float]:
        """Embed 1 chuỗi → vector. Raise `EmbeddingError` nếu Ollama down/timeout."""
        if not text.strip():
            raise EmbeddingError("Không thể embed chuỗi rỗng.")
        endpoint = self.base_url.rstrip("/") + "/api/embeddings"
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    endpoint,
                    json={"model": self.model, "prompt": text},
                )
        except httpx.TimeoutException as ex:
            raise EmbeddingError(f"Ollama embed timeout sau {self.timeout}s") from ex
        except httpx.HTTPError as ex:
            raise EmbeddingError(f"Ollama embed HTTP error: {ex}") from ex

        if response.status_code >= 400:
            raise EmbeddingError(f"Ollama embed {response.status_code}: {response.text[:200]}")

        body = response.json()
        embedding = body.get("embedding")
        if not isinstance(embedding, list) or not embedding:
            raise EmbeddingError(f"Ollama embed trả thiếu field 'embedding': {body}")
        return [float(v) for v in embedding]

    async def embed_batch(self, texts: list[str]) -> list[list[float]]:
        """Phase 4: Ollama /api/embeddings không batch sẵn — gọi tuần tự.
        Dùng trong index_documents.py (1-time job, không cần tối ưu cao)."""
        results: list[list[float]] = []
        for idx, text in enumerate(texts):
            if idx > 0 and idx % 25 == 0:
                _logger.info("embedding.progress", indexed=idx, total=len(texts))
            results.append(await self.embed(text))
        return results
