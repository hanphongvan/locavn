"""Phase 5D — Schema Retriever cho intent UNKNOWN.

Index `AiSchemaCatalog` (8 entity) vào Qdrant collection `ai_schema_catalog`,
search top entity liên quan cho câu hỏi UNKNOWN để Phase 5E Plan Generator
sinh dynamic SQL.

Section 4 + 14.4 của `docs/loca-ai-phase5.md`. Phụ thuộc:
- `.NET` endpoint `GET /internal/ai/schema-catalog` (đã có Phase 5D step 1).
- Qdrant + Ollama bge-m3 (Phase 4).

Idempotency: deterministic point_id từ `uuid5(NAMESPACE, "code|type|index")`
→ re-index không duplicate. Sau upsert clean orphan chunks (entity disabled
hoặc số sample question giảm).
"""
from __future__ import annotations

import uuid
from dataclasses import dataclass, replace
from datetime import datetime, timezone
from typing import Any

from .dotnet_api_client import DotnetApiClient, DotnetApiError
from .embedding_service import EmbeddingError, EmbeddingService
from .logging_service import get_logger
from .qdrant_service import QdrantError, QdrantService, RagChunk

_logger = get_logger(__name__)


# Section 14.4 — collection riêng cho schema metadata, KHÔNG dùng chung
# `loca_documents` của Phase 4 (RAG tài liệu nghiệp vụ).
SCHEMA_COLLECTION_NAME = "ai_schema_catalog"
SCHEMA_VECTOR_SIZE = 1024  # bge-m3, đồng bộ DEFAULT_VECTOR_SIZE Phase 4.

# UUID namespace cố định — generate 1 lần (uuid4), hardcode để cùng input
# luôn ra cùng point_id qua các lần re-index.
SCHEMA_NAMESPACE_UUID = uuid.UUID("a8c3e6d2-5f1b-4a9c-8e2d-7b3f5c1a9d4e")

DEFAULT_TOP_K_RAW = 15        # số chunk lấy từ Qdrant trước khi group
DEFAULT_TOP_K_UNIQUE = 3      # số entity unique trả về
DEFAULT_SCORE_THRESHOLD = 0.30   # lowered from 0.45 — colloquial queries score 0.30-0.36 with bge-m3


class SchemaRetrieverError(Exception):
    """Indexing/retrieval failed nghiêm trọng — caller phải handle."""


@dataclass(frozen=True, slots=True)
class CandidateEntity:
    """1 entity match từ schema retrieval.

    `score` là max score trong các chunk thuộc entity này.
    `matched_chunk_type` debug-only — biết entity match qua description hay
    sample question để tune chunk strategy.

    Phase 5H — `is_snapshot` flag từ AiSchemaCatalog: True = entity balance
    (vd tồn quỹ) → SUM qua kỳ vô nghĩa → Plan Generator filter latest period.
    `latest_period` populate ở `find_relevant_entities` cho snapshot entity.
    """

    entity_code: str
    display_name: str
    description: str
    data_layer: str                                # head_office | retail_station
    base_view: str
    primary_key: str
    allowed_columns: list[str]
    allowed_filters: list[str]
    allowed_aggregates: list[str]
    allowed_joins: list[dict[str, str]] | None     # None ≠ [] — xem doc 5D
    sample_questions: list[str]
    default_limit: int
    max_limit: int
    score: float
    matched_chunk_type: str
    is_snapshot: bool = False
    latest_period: dict[str, int] | None = None    # {"nam": 2026, "thang": 5} hoặc None

    def to_dict(self) -> dict[str, Any]:
        """Serialize cho `AgentState.candidate_entities` (TypedDict cần dict thuần)."""
        return {
            "entity_code": self.entity_code,
            "display_name": self.display_name,
            "description": self.description,
            "data_layer": self.data_layer,
            "base_view": self.base_view,
            "primary_key": self.primary_key,
            "allowed_columns": list(self.allowed_columns),
            "allowed_filters": list(self.allowed_filters),
            "allowed_aggregates": list(self.allowed_aggregates),
            "allowed_joins": (
                None if self.allowed_joins is None else [dict(j) for j in self.allowed_joins]
            ),
            "sample_questions": list(self.sample_questions),
            "default_limit": self.default_limit,
            "max_limit": self.max_limit,
            "score": self.score,
            "matched_chunk_type": self.matched_chunk_type,
            "is_snapshot": self.is_snapshot,
            "latest_period": (
                None if self.latest_period is None else dict(self.latest_period)
            ),
        }


def _normalize_entity(raw: dict[str, Any]) -> dict[str, Any]:
    """Chuyển camelCase từ `.NET` JSON → snake_case Pythonic.

    `allowedJoins`: phân biệt `null` ↔ `[]` (Phase 5E SqlBuilder cần).
    Field thiếu → default an toàn (empty list, None).
    """
    return {
        "entity_code": raw.get("entityCode") or "",
        "display_name": raw.get("displayName") or "",
        "description": raw.get("description") or "",
        "data_layer": raw.get("dataLayer") or "",
        "base_view": raw.get("baseView") or "",
        "primary_key": raw.get("primaryKey") or "",
        "allowed_columns": list(raw.get("allowedColumns") or []),
        "allowed_filters": list(raw.get("allowedFilters") or []),
        "allowed_aggregates": list(raw.get("allowedAggregates") or []),
        # KHÔNG dùng `or []` ở đây — phải giữ phân biệt None vs [].
        "allowed_joins": (
            None if raw.get("allowedJoins") is None
            else [dict(j) for j in raw["allowedJoins"]]
        ),
        "sample_questions": list(raw.get("sampleQuestions") or []),
        "default_limit": int(raw.get("defaultLimit") or 100),
        "max_limit": int(raw.get("maxLimit") or 1000),
        # Phase 5H — flag snapshot vs flow. Default False để entity cũ (chưa migrate
        # cột IsSnapshot) không bị mặc định ép latest period filter.
        "is_snapshot": bool(raw.get("isSnapshot") or False),
        "modified_at": raw.get("modified"),  # ISO string hoặc None
    }


class SchemaRetriever:
    """Phase 5D — index/search schema catalog cho intent UNKNOWN.

    Khởi tạo qua DI (`main.py` factory) với Qdrant đã point sẵn vào collection
    `ai_schema_catalog` (KHÔNG dùng chung instance Qdrant của RAG documents).
    """

    def __init__(
        self,
        *,
        embedding: EmbeddingService,
        qdrant: QdrantService,
        dotnet: DotnetApiClient,
        top_k_raw: int = DEFAULT_TOP_K_RAW,
        top_k_unique: int = DEFAULT_TOP_K_UNIQUE,
        score_threshold: float = DEFAULT_SCORE_THRESHOLD,
    ) -> None:
        if qdrant.collection != SCHEMA_COLLECTION_NAME:
            raise SchemaRetrieverError(
                f"QdrantService phải point vào collection '{SCHEMA_COLLECTION_NAME}', "
                f"nhận được '{qdrant.collection}'."
            )
        self._embedding = embedding
        self._qdrant = qdrant
        self._dotnet = dotnet
        self._top_k_raw = top_k_raw
        self._top_k_unique = top_k_unique
        self._score_threshold = score_threshold

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def index_all_entities(self) -> dict[str, int]:
        """Fetch entity từ `.NET` → embed → upsert vào Qdrant → cleanup orphan.

        Idempotent: cùng entity → cùng point_id (uuid5) → upsert overwrite.
        Sau khi upsert, xoá:
        1. Points có entity_code KHÔNG còn trong fresh list (admin disable entity).
        2. Sample chunks có index ≥ số sample mới (sample đã giảm sau update).

        Returns:
            `{"entities_fetched", "entities_indexed", "entities_failed",
              "chunks_upserted", "orphans_cleaned"}`.

        Raises:
            SchemaRetrieverError: `.NET` API down hoặc Qdrant ensure_collection fail.
        """
        await self._qdrant.ensure_collection()

        try:
            raw_entities = await self._dotnet.fetch_schema_catalog()
        except DotnetApiError as ex:
            raise SchemaRetrieverError(f"Fetch schema catalog từ .NET fail: {ex}") from ex

        entities = [_normalize_entity(r) for r in raw_entities]
        if not entities:
            _logger.warning("schema_retriever.no_entities_fetched")
            return {
                "entities_fetched": 0,
                "entities_indexed": 0,
                "entities_failed": 0,
                "chunks_upserted": 0,
                "orphans_cleaned": 0,
            }

        chunks_upserted = 0
        entities_indexed = 0
        entities_failed = 0
        # Map entity_code -> số sample question (= max chunk_index của sample chunk + 1)
        # dùng cho cleanup orphan.
        fresh_sample_counts: dict[str, int] = {}

        for entity in entities:
            try:
                upserted = await self._index_one_entity(entity)
                chunks_upserted += upserted
                entities_indexed += 1
                fresh_sample_counts[entity["entity_code"]] = len(entity["sample_questions"])
            except (EmbeddingError, QdrantError) as ex:
                entities_failed += 1
                _logger.warning(
                    "schema_retriever.entity_index_failed",
                    entity_code=entity.get("entity_code"),
                    error=str(ex),
                )

        orphans_cleaned = await self._delete_stale_points(
            fresh_entity_codes=set(fresh_sample_counts.keys()),
            fresh_sample_counts=fresh_sample_counts,
        )

        _logger.info(
            "schema_retriever.index_done",
            entities_fetched=len(entities),
            entities_indexed=entities_indexed,
            entities_failed=entities_failed,
            chunks_upserted=chunks_upserted,
            orphans_cleaned=orphans_cleaned,
        )

        return {
            "entities_fetched": len(entities),
            "entities_indexed": entities_indexed,
            "entities_failed": entities_failed,
            "chunks_upserted": chunks_upserted,
            "orphans_cleaned": orphans_cleaned,
        }

    async def find_relevant_entities(
        self,
        question: str,
        *,
        top_k: int | None = None,
    ) -> list[CandidateEntity]:
        """Search top entity liên quan cho câu hỏi UNKNOWN.

        Embed câu hỏi → search `top_k_raw` chunks → group by `entity_code`
        (giữ score cao nhất) → sort desc → take `top_k` (override hoặc default).

        Returns: list rỗng khi:
        - Câu hỏi rỗng/whitespace.
        - Không chunk nào vượt `score_threshold`.
        - Embedding/Qdrant fail (degrade gracefully — log warning, không raise).
        """
        if not question or not question.strip():
            return []

        limit_unique = top_k if top_k is not None else self._top_k_unique

        try:
            query_vector = await self._embedding.embed(question)
        except EmbeddingError as ex:
            _logger.warning("schema_retriever.embed_failed", error=str(ex))
            return []

        try:
            raw_hits = await self._qdrant.search(
                query_vector,
                limit=self._top_k_raw,
                score_threshold=self._score_threshold,
            )
        except QdrantError as ex:
            _logger.warning("schema_retriever.search_failed", error=str(ex))
            return []

        # Phase 5F+ diagnostic — nếu threshold lọc hết, làm 1 search nữa
        # KHÔNG threshold (limit=1) để log score top thật. Giúp Phase 5G
        # admin tune threshold hoặc bổ sung sample question khớp pattern.
        if not raw_hits:
            try:
                probe = await self._qdrant.search(
                    query_vector, limit=1, score_threshold=0.0,
                )
            except QdrantError:
                probe = []
            if probe:
                top = probe[0]
                _logger.info(
                    "schema_retriever.below_threshold",
                    question=question[:200],
                    top_score=round(top.score, 3),
                    top_entity=(top.metadata or {}).get("entity_code"),
                    threshold=self._score_threshold,
                )

        candidates = self._group_by_entity(raw_hits, limit_unique)
        return await self._enrich_latest_periods(candidates)

    async def _enrich_latest_periods(
        self, candidates: list[CandidateEntity],
    ) -> list[CandidateEntity]:
        """Phase 5H — gọi `.NET /internal/ai/latest-period` cho MỌI candidate
        → attach `latest_period={nam, thang}` nếu backend trả data.

        TRUST backend làm source of truth thay vì Qdrant payload `is_snapshot`:
        backend tự whitelist `WHERE IsSnapshot=1 AND IsEnabled=1` trong subquery,
        entity flow sẽ trả `(null, null)`. Lý do: Qdrant payload có thể stale
        (reindex worker chưa pickup queue sau khi admin set IsSnapshot=1) →
        nếu trust payload, Phase 5H sẽ silently không kick in.

        Backend cache 5 phút nên 3 round-trip (top-3 candidate) acceptable.
        Lỗi network/timeout → None → Plan Generator fallback prompt-only.
        """
        enriched: list[CandidateEntity] = []
        for c in candidates:
            try:
                nam, thang = await self._dotnet.get_latest_period(c.entity_code)
            except Exception as ex:   # noqa: BLE001 — graceful degrade
                _logger.warning(
                    "schema_retriever.latest_period_unexpected",
                    entity_code=c.entity_code, error=str(ex),
                )
                nam, thang = None, None

            if nam is not None and thang is not None:
                # Backend xác nhận entity là snapshot + có data → set cả 2 flag
                # đồng bộ (đề phòng Qdrant payload stale chưa có is_snapshot=true).
                _logger.info(
                    "schema_retriever.latest_period_attached",
                    entity_code=c.entity_code, nam=nam, thang=thang,
                    qdrant_is_snapshot=c.is_snapshot,
                )
                enriched.append(replace(
                    c,
                    is_snapshot=True,
                    latest_period={"nam": nam, "thang": thang},
                ))
            else:
                enriched.append(c)
        return enriched

    async def index_entity_by_code(self, entity_code: str) -> dict[str, Any]:
        """Phase 5G — re-index 1 entity theo `entity_code` (dùng cho reindex worker).

        Workflow:
        1. Fetch toàn bộ schema catalog từ `.NET` (chỉ entity `IsEnabled=1`).
        2. Tìm entity match `entity_code`:
           - Found → re-embed + upsert chunks vào Qdrant (overwrite via uuid5).
           - NOT found → entity đã disable hoặc xoá → DELETE points cho entity_code đó.

        Returns: dict `{"action", "chunks_upserted" | "points_deleted",
            "entity_code"}`. Caller (reindex worker) ghi log + post complete
            qua `/internal/ai/reindex-queue/{id}/complete`.

        Raises:
            SchemaRetrieverError: `.NET` API down hoặc Qdrant fail (caller post
            status='failed' với error message).
        """
        if not entity_code or not entity_code.strip():
            raise SchemaRetrieverError("entity_code rỗng")

        try:
            raw_entities = await self._dotnet.fetch_schema_catalog()
        except DotnetApiError as ex:
            raise SchemaRetrieverError(f"Fetch schema catalog fail: {ex}") from ex

        entities = [_normalize_entity(r) for r in raw_entities]
        target = next(
            (e for e in entities if e["entity_code"] == entity_code), None,
        )

        if target is None:
            # Entity disabled hoặc xoá → cleanup points trong Qdrant.
            try:
                await self._qdrant.delete_by_filter(
                    payload_key="entity_code", payload_value=entity_code,
                )
            except QdrantError as ex:
                raise SchemaRetrieverError(
                    f"Delete points cho disabled entity {entity_code!r}: {ex}",
                ) from ex
            _logger.info(
                "schema_retriever.entity_deleted_after_reindex",
                entity_code=entity_code,
            )
            return {
                "action": "deleted",
                "entity_code": entity_code,
                "points_deleted": "all",
            }

        # Found → re-embed + upsert.
        try:
            upserted = await self._index_one_entity(target)
        except (EmbeddingError, QdrantError) as ex:
            raise SchemaRetrieverError(
                f"Re-index entity {entity_code!r}: {ex}",
            ) from ex
        _logger.info(
            "schema_retriever.entity_reindexed",
            entity_code=entity_code, chunks=upserted,
        )
        return {
            "action": "upserted",
            "entity_code": entity_code,
            "chunks_upserted": upserted,
        }

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    async def _index_one_entity(self, entity: dict[str, Any]) -> int:
        """Build chunks cho 1 entity, embed, upsert. Trả số chunks upserted.

        Sample questions rỗng → vẫn tạo description chunk (entity không bị
        "vô hình" trong retrieval qua câu hỏi mô tả).
        """
        chunks = self._build_chunks(entity)
        if not chunks:
            return 0

        texts = [text for (_pid, text, _idx, _ctype, _payload) in chunks]
        vectors = await self._embedding.embed_batch(texts)

        upsert_chunks: list[tuple[str, str, list[float], dict[str, Any]]] = [
            (point_id, text, vector, payload)
            for (point_id, text, _idx, _ctype, payload), vector in zip(
                chunks, vectors, strict=True
            )
        ]
        return await self._qdrant.upsert_with_ids(upsert_chunks)

    def _build_chunks(
        self,
        entity: dict[str, Any],
    ) -> list[tuple[str, str, int, str, dict[str, Any]]]:
        """Sinh chunks cho 1 entity.

        Returns: list of (point_id, chunk_text, chunk_index, chunk_type, payload).

        Entity = 1 description chunk + N sample question chunks.
        Sample rỗng → vẫn có description chunk (entity không vô hình).
        """
        entity_code = entity["entity_code"]
        chunks: list[tuple[str, str, int, str, dict[str, Any]]] = []

        # Description chunk
        desc_text = self._compose_description_text(entity)
        if desc_text.strip():
            chunks.append((
                self._make_point_id(entity_code, "description", 0),
                desc_text,
                0,
                "description",
                self._build_payload(entity, desc_text, "description", 0),
            ))

        # Sample question chunks
        for idx, sample in enumerate(entity["sample_questions"]):
            text = (sample or "").strip()
            if not text:
                continue
            chunks.append((
                self._make_point_id(entity_code, "sample_question", idx),
                text,
                idx,
                "sample_question",
                self._build_payload(entity, text, "sample_question", idx),
            ))

        return chunks

    @staticmethod
    def _compose_description_text(entity: dict[str, Any]) -> str:
        """Description chunk text = displayName + description (newline separator)."""
        parts = []
        if entity.get("display_name"):
            parts.append(entity["display_name"])
        if entity.get("description"):
            parts.append(entity["description"])
        return "\n\n".join(parts)

    @staticmethod
    def _make_point_id(entity_code: str, chunk_type: str, chunk_index: int) -> str:
        """uuid5 deterministic — re-run index trả cùng id, upsert overwrite."""
        return str(uuid.uuid5(
            SCHEMA_NAMESPACE_UUID,
            f"{entity_code}|{chunk_type}|{chunk_index}",
        ))

    def _build_payload(
        self,
        entity: dict[str, Any],
        chunk_text: str,
        chunk_type: str,
        chunk_index: int,
    ) -> dict[str, Any]:
        """Payload Qdrant — chứa toàn bộ metadata cho Phase 5E khỏi re-fetch."""
        return {
            "entity_code": entity["entity_code"],
            "chunk_type": chunk_type,
            "chunk_index": chunk_index,
            "chunk_text": chunk_text,
            "display_name": entity["display_name"],
            "description": entity["description"],
            "data_layer": entity["data_layer"],
            "base_view": entity["base_view"],
            "primary_key": entity["primary_key"],
            "allowed_columns": entity["allowed_columns"],
            "allowed_filters": entity["allowed_filters"],
            "allowed_aggregates": entity["allowed_aggregates"],
            "allowed_joins": entity["allowed_joins"],   # giữ None vs [] phân biệt
            "sample_questions": entity["sample_questions"],
            "default_limit": entity["default_limit"],
            "max_limit": entity["max_limit"],
            "is_snapshot": entity.get("is_snapshot", False),
            "modified_at": entity.get("modified_at"),
            "indexed_at": datetime.now(timezone.utc).isoformat(),
        }

    def _group_by_entity(
        self,
        raw_hits: list[RagChunk],
        top_k_unique: int,
    ) -> list[CandidateEntity]:
        """Group raw_hits by `entity_code` → giữ score cao nhất → sort desc → take top_k.

        Mỗi entity_code chỉ xuất hiện 1 lần trong kết quả (entity có nhiều
        chunks match → chỉ giữ chunk score cao nhất, payload từ chunk đó).
        """
        # Group: entity_code → (best_score, best_payload, best_chunk_type)
        best_per_entity: dict[str, tuple[float, dict[str, Any], str]] = {}
        for hit in raw_hits:
            entity_code = hit.metadata.get("entity_code")
            if not entity_code:
                continue
            chunk_type = hit.metadata.get("chunk_type") or ""
            current = best_per_entity.get(entity_code)
            if current is None or hit.score > current[0]:
                best_per_entity[entity_code] = (hit.score, hit.metadata, chunk_type)

        ranked = sorted(
            best_per_entity.items(),
            key=lambda kv: kv[1][0],
            reverse=True,
        )[:top_k_unique]

        return [
            CandidateEntity(
                entity_code=entity_code,
                display_name=payload.get("display_name") or "",
                description=payload.get("description") or "",
                data_layer=payload.get("data_layer") or "",
                base_view=payload.get("base_view") or "",
                primary_key=payload.get("primary_key") or "",
                allowed_columns=list(payload.get("allowed_columns") or []),
                allowed_filters=list(payload.get("allowed_filters") or []),
                allowed_aggregates=list(payload.get("allowed_aggregates") or []),
                # Phân biệt None ≠ []
                allowed_joins=(
                    None if payload.get("allowed_joins") is None
                    else [dict(j) for j in payload["allowed_joins"]]
                ),
                sample_questions=list(payload.get("sample_questions") or []),
                default_limit=int(payload.get("default_limit") or 100),
                max_limit=int(payload.get("max_limit") or 1000),
                score=score,
                matched_chunk_type=chunk_type,
                is_snapshot=bool(payload.get("is_snapshot") or False),
                latest_period=None,   # populate sau ở find_relevant_entities
            )
            for entity_code, (score, payload, chunk_type) in ranked
        ]

    async def _delete_stale_points(
        self,
        *,
        fresh_entity_codes: set[str],
        fresh_sample_counts: dict[str, int],
    ) -> int:
        """Xoá orphan chunks sau khi index lại.

        Phase 5D logic:
        1. Entity đã bị disable (KHÔNG còn trong `fresh_entity_codes`):
           lấy danh sách entity_code distinct trong Qdrant — bất cứ entity_code
           nào không thuộc fresh set thì xoá hết points của nó.
        2. Sample question giảm: với mỗi entity còn enable, các sample chunks
           có `chunk_index >= fresh_sample_counts[entity_code]` đã orphan.

        Returns: ước lượng số deletes (mỗi gọi `delete_by_filter` đếm là 1).
        Phase 5G nếu cần count chính xác sẽ thêm scroll round-trip.

        Edge case: fresh_entity_codes rỗng → không xoá gì (tránh wipe collection
        nếu .NET trả 0 entity vì lý do tạm thời).
        """
        if not fresh_entity_codes:
            _logger.warning("schema_retriever.skip_cleanup_empty_fresh_set")
            return 0

        deletes = 0

        # Bước 1 — entity disabled. Em scroll để lấy distinct entity_code hiện có.
        existing_codes = await self._scroll_distinct_entity_codes()
        disabled_codes = existing_codes - fresh_entity_codes
        for code in disabled_codes:
            try:
                await self._qdrant.delete_by_filter(
                    payload_key="entity_code",
                    payload_value=code,
                )
                deletes += 1
                _logger.info("schema_retriever.deleted_disabled_entity", entity_code=code)
            except QdrantError as ex:
                _logger.warning(
                    "schema_retriever.delete_disabled_failed",
                    entity_code=code,
                    error=str(ex),
                )

        # Bước 2 — sample chunks orphan (entity còn enable nhưng số sample giảm).
        # Cần scroll → filter point_id theo chunk_type + chunk_index → delete by ids.
        # Một scroll dùng cho cả Bước 1 lẫn Bước 2 sẽ tối ưu hơn 2 scroll riêng,
        # nhưng để giữ logic rõ ràng (đã xoá entity ở Bước 1 → không phải re-scroll
        # những payload đó), em scroll lại sau Bước 1.
        sample_orphan_ids = await self._collect_sample_orphan_ids(fresh_sample_counts)
        if sample_orphan_ids:
            try:
                await self._qdrant.delete_by_ids(sample_orphan_ids)
                deletes += len(sample_orphan_ids)
                _logger.info(
                    "schema_retriever.deleted_sample_orphans",
                    count=len(sample_orphan_ids),
                )
            except QdrantError as ex:
                _logger.warning(
                    "schema_retriever.delete_sample_orphans_failed",
                    error=str(ex),
                )

        return deletes

    async def _scroll_distinct_entity_codes(self) -> set[str]:
        """Scroll collection lấy distinct entity_code hiện tồn tại.

        Collection nhỏ (~50 points) → 1 scroll page với default page_size=1000.
        """
        try:
            payloads = await self._qdrant.scroll_payloads()
        except QdrantError as ex:
            _logger.warning("schema_retriever.scroll_failed", error=str(ex))
            return set()

        codes: set[str] = set()
        for _point_id, payload in payloads:
            code = payload.get("entity_code")
            if code:
                codes.add(str(code))
        return codes

    async def _collect_sample_orphan_ids(
        self,
        fresh_sample_counts: dict[str, int],
    ) -> list[str]:
        """List `point_id` của sample chunks orphan (`chunk_index ≥ count mới`).

        Scroll toàn bộ rồi filter trong Python — collection nhỏ, đơn giản.
        Skip points của entity đã bị disable (Bước 1 đã xoá nhưng cleanup
        có thể chưa hoàn tất khi method này chạy — defensive).
        """
        try:
            payloads = await self._qdrant.scroll_payloads()
        except QdrantError as ex:
            _logger.warning("schema_retriever.scroll_orphans_failed", error=str(ex))
            return []

        orphan_ids: list[str] = []
        for point_id, payload in payloads:
            if payload.get("chunk_type") != "sample_question":
                continue
            entity_code = payload.get("entity_code")
            if not entity_code or entity_code not in fresh_sample_counts:
                continue
            chunk_index = payload.get("chunk_index")
            if not isinstance(chunk_index, int):
                continue
            if chunk_index >= fresh_sample_counts[entity_code]:
                orphan_ids.append(point_id)
        return orphan_ids
