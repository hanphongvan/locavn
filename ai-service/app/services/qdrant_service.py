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
        """Upsert batch — `(text, vector, metadata)`. Trả số point inserted/updated.

        Auto-gen uuid4 cho mỗi point — phù hợp khi caller không cần idempotency
        (vd index documents Phase 4 — re-run là re-index toàn bộ).
        """
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

    async def upsert_with_ids(
        self,
        chunks: list[tuple[str, str, list[float], dict[str, Any]]],
    ) -> int:
        """Upsert batch với deterministic `point_id` do caller cung cấp.

        Phase 5D dùng để re-index `ai_schema_catalog` không duplicate
        (point_id = uuid5 từ entity_code|chunk_type|chunk_index → cùng input
        ra cùng id → upsert overwrite). Phase 5G worker reuse cùng cơ chế.

        Args:
            chunks: list of `(point_id, text, vector, metadata)`.

        Returns:
            Số points đã upsert (= len(chunks) khi không lỗi).

        Raises:
            QdrantError: khi Qdrant client fail.
        """
        if not chunks:
            return 0
        try:
            points = [
                models.PointStruct(
                    id=point_id,
                    vector=vector,
                    payload={"text": text, **metadata},
                )
                for point_id, text, vector, metadata in chunks
            ]
            await self._client.upsert(collection_name=self._collection, points=points, wait=True)
            return len(points)
        except Exception as ex:
            raise QdrantError(
                f"Qdrant upsert_with_ids {len(chunks)} chunks lỗi: {ex}"
            ) from ex

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

    async def scroll_payloads(
        self,
        *,
        with_vectors: bool = False,
        page_size: int = 1000,
        max_pages: int = 10,
    ) -> list[tuple[str, dict[str, Any]]]:
        """Scroll toàn bộ collection, trả `(point_id, payload)` cho mỗi point.

        Auto-paginate qua `next_offset` cho đến hết hoặc đạt `max_pages`
        (an toàn — collection lỡ phồng to bất thường vẫn không vòng vô hạn).

        Phase 5D: collection `ai_schema_catalog` ~50 points, 1 page là đủ.
        Phase 5G admin UI: nếu collection lớn hơn → tăng `max_pages` hoặc
        chuyển sang streaming (mở rộng method này về sau).

        Args:
            with_vectors: True khi caller cần vector (vd debug); False mặc định
                vì payload-only nhanh hơn.
            page_size: Qdrant scroll limit per request.
            max_pages: ngưỡng an toàn — raise nếu vượt mà chưa hết.

        Returns:
            List `(point_id_str, payload_dict)` — payload luôn là dict
            (rỗng `{}` nếu point không có payload).

        Raises:
            QdrantError: khi Qdrant client fail.
        """
        results: list[tuple[str, dict[str, Any]]] = []
        next_offset: Any = None
        for page_idx in range(max_pages):
            try:
                page, next_offset = await self._client.scroll(
                    collection_name=self._collection,
                    limit=page_size,
                    offset=next_offset,
                    with_payload=True,
                    with_vectors=with_vectors,
                )
            except Exception as ex:
                raise QdrantError(
                    f"Qdrant scroll_payloads page={page_idx} lỗi: {ex}"
                ) from ex
            for point in page:
                results.append((str(point.id), dict(point.payload or {})))
            if next_offset is None:
                break
        else:
            # max_pages reached without finishing — log nhưng không raise
            # (trả về kết quả đã có, caller decide).
            _logger.warning(
                "qdrant.scroll_max_pages_reached",
                collection=self._collection,
                max_pages=max_pages,
                page_size=page_size,
            )
        return results

    async def delete_by_ids(self, point_ids: list[str]) -> None:
        """Xoá points theo list `point_id` (no-op nếu list rỗng).

        Phase 5D dùng để cleanup orphan sample chunks (chunk_index ≥ số sample
        mới sau update). Phase 5G admin UI dùng để remove specific points.

        Raises:
            QdrantError: khi Qdrant client fail.
        """
        if not point_ids:
            return
        try:
            await self._client.delete(
                collection_name=self._collection,
                points_selector=models.PointIdsList(points=list(point_ids)),
                wait=True,
            )
        except Exception as ex:
            raise QdrantError(
                f"Qdrant delete_by_ids {len(point_ids)} points lỗi: {ex}"
            ) from ex

    async def delete_by_filter(
        self,
        *,
        payload_key: str,
        payload_value: str | None = None,
        payload_in: list[str] | None = None,
        payload_must_match: dict[str, Any] | None = None,
    ) -> None:
        """Phase 5D — xoá points theo filter trên payload. Idempotent.

        Caller chỉ được set CHÍNH XÁC 1 trong 3 nguồn match:
        - `payload_value`: match exact 1 string trên `payload_key`
          (vd `payload_key="entity_code"`, `payload_value="head_office_inventory"`).
        - `payload_in`: match in list (`payload_key` trong `payload_in`).
        - `payload_must_match`: dict các key=value khác combine bằng AND
          (vd `{"entity_code": "X", "chunk_type": "sample_question"}`).
          Khi dùng option này, `payload_key` bị bỏ qua — truyền `""` cũng được.

        Trả `None` (không count chính xác) — Qdrant `delete` API không expose
        số points đã xoá. Phase 5G admin UI nếu cần count thì sẽ thêm scroll
        round-trip riêng.
        """
        sources_set = sum(x is not None for x in (payload_value, payload_in, payload_must_match))
        if sources_set != 1:
            raise QdrantError(
                "delete_by_filter cần CHÍNH XÁC 1 trong 3 nguồn match: "
                "payload_value | payload_in | payload_must_match."
            )

        if payload_must_match is not None:
            conditions = [
                models.FieldCondition(key=k, match=models.MatchValue(value=v))
                for k, v in payload_must_match.items()
            ]
        elif payload_in is not None:
            conditions = [
                models.FieldCondition(key=payload_key, match=models.MatchAny(any=payload_in))
            ]
        else:  # payload_value
            conditions = [
                models.FieldCondition(key=payload_key, match=models.MatchValue(value=payload_value))
            ]

        try:
            await self._client.delete(
                collection_name=self._collection,
                points_selector=models.FilterSelector(filter=models.Filter(must=conditions)),
                wait=True,
            )
        except Exception as ex:
            raise QdrantError(f"Qdrant delete_by_filter lỗi: {ex}") from ex

    async def close(self) -> None:
        await self._client.close()
