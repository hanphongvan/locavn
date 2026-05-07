"""Qdrant vector DB wrapper — Phase 4.

Phase 4 chỉ cần 3 thao tác:
- `ensure_collection`: idempotent tạo collection (1024-dim cho bge-m3).
- `upsert`: index 1 batch chunk văn bản với metadata (source, page, ...).
- `search`: top-K nearest theo vector embedding.

Sử dụng `qdrant-client` async (`AsyncQdrantClient`) để fit FastAPI event loop.
"""
from __future__ import annotations

import uuid
from dataclasses import dataclass
from typing import Any

from qdrant_client import AsyncQdrantClient, models

from .logging_service import get_logger

_logger = get_logger(__name__)


# Section 7.1 — Collection cho RAG tài liệu nghiệp vụ.
DEFAULT_COLLECTION = "loca_documents"
DEFAULT_VECTOR_SIZE = 1024  # bge-m3 chiều 1024.


class QdrantError(Exception):
    pass


@dataclass(frozen=True, slots=True)
class RagChunk:
    id: str
    score: float
    text: str
    source: str | None
    metadata: dict[str, Any]


class QdrantService:
    def __init__(
        self,
        url: str,
        *,
        collection: str = DEFAULT_COLLECTION,
        vector_size: int = DEFAULT_VECTOR_SIZE,
        api_key: str | None = None,
    ):
        self._url = url
        self._collection = collection
        self._vector_size = vector_size
        self._client = AsyncQdrantClient(url=url, api_key=api_key, timeout=10)

    @property
    def collection(self) -> str:
        return self._collection

    async def ensure_collection(self) -> None:
        """Tạo collection nếu chưa có. Idempotent — gọi nhiều lần không lỗi."""
        try:
            existed = await self._client.collection_exists(self._collection)
            if existed:
                return
            await self._client.create_collection(
                collection_name=self._collection,
                vectors_config=models.VectorParams(
                    size=self._vector_size,
                    distance=models.Distance.COSINE,
                ),
            )
            _logger.info("qdrant.collection_created", name=self._collection, size=self._vector_size)
        except Exception as ex:
            raise QdrantError(f"Qdrant ensure_collection lỗi: {ex}") from ex

    async def upsert(
        self,
        chunks: list[tuple[str, list[float], dict[str, Any]]],
    ) -> int:
        """Upsert batch — `(text, vector, metadata)`. Trả số point inserted/updated."""
        if not chunks:
            return 0
        try:
            points = [
                models.PointStruct(
                    id=str(uuid.uuid4()),
                    vector=vector,
                    payload={"text": text, **metadata},
                )
                for text, vector, metadata in chunks
            ]
            await self._client.upsert(collection_name=self._collection, points=points, wait=True)
            return len(points)
        except Exception as ex:
            raise QdrantError(f"Qdrant upsert {len(chunks)} chunks lỗi: {ex}") from ex

    async def search(
        self,
        query_vector: list[float],
        *,
        limit: int = 5,
        score_threshold: float | None = 0.4,
    ) -> list[RagChunk]:
        """Top-K nearest. `score_threshold` lọc chunk độ tương đồng quá thấp
        (≤ 0.4 cosine = gần như không liên quan)."""
        try:
            response = await self._client.query_points(
                collection_name=self._collection,
                query=query_vector,
                limit=limit,
                score_threshold=score_threshold,
            )
        except Exception as ex:
            raise QdrantError(f"Qdrant search lỗi: {ex}") from ex

        chunks: list[RagChunk] = []
        for point in response.points:
            payload = point.payload or {}
            chunks.append(RagChunk(
                id=str(point.id),
                score=float(point.score),
                text=str(payload.get("text") or ""),
                source=payload.get("source"),
                metadata={k: v for k, v in payload.items() if k != "text"},
            ))
        return chunks

    async def close(self) -> None:
        await self._client.close()
