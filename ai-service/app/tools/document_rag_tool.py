"""DocumentRAGTool — Phase 4 truy vấn tài liệu nghiệp vụ.

Workflow:
1. Embed `query` qua `EmbeddingService` (Ollama bge-m3).
2. Search `QdrantService` top-K chunks gần nhất.
3. Trả `ToolResult` với `summary.context` = ghép text top chunks (dùng cho
   `data_analyzer` ép vào LLM prompt) + `rows` = chi tiết từng chunk
   (cho UI Flutter render references).

Phase 4 không cache vì:
- Câu hỏi dài đa dạng → cache hit thấp.
- Embedding cost thấp khi local (chỉ vài trăm ms).
"""
from __future__ import annotations

from typing import Any

from ..schemas.tool import ToolResult
from ..services.embedding_service import EmbeddingError, EmbeddingService
from ..services.logging_service import get_logger
from ..services.qdrant_service import QdrantError, QdrantService
from .base_tool import BaseTool

_logger = get_logger(__name__)


class DocumentRAGTool(BaseTool):
    name = "document_rag"
    stored_procedure = ""  # RAG không gọi SP whitelist.
    mock_key = ""
    cache_ttl_seconds = 0  # khác câu hỏi → khác query → cache không có ý nghĩa.

    def __init__(
        self,
        *,
        embedding: EmbeddingService,
        qdrant: QdrantService,
        top_k: int = 5,
        score_threshold: float | None = 0.4,
        **kwargs: Any,
    ):
        super().__init__(**kwargs)
        self._embedding = embedding
        self._qdrant = qdrant
        self._top_k = top_k
        self._score_threshold = score_threshold

    async def run(self, params: dict[str, Any]) -> ToolResult:
        query = (params.get("query") or "").strip()
        if not query:
            return ToolResult(
                tool_name=self.name,
                success=False,
                rows=[],
                error="query rỗng",
            )

        try:
            vector = await self._embedding.embed(query)
        except EmbeddingError as ex:
            _logger.warning("rag.embed_failed", error=str(ex))
            return ToolResult(tool_name=self.name, success=False, rows=[], error=str(ex))

        try:
            chunks = await self._qdrant.search(
                vector,
                limit=self._top_k,
                score_threshold=self._score_threshold,
            )
        except QdrantError as ex:
            _logger.warning("rag.search_failed", error=str(ex))
            return ToolResult(tool_name=self.name, success=False, rows=[], error=str(ex))

        rows = [
            {
                "id": c.id,
                "score": round(c.score, 4),
                "text": c.text,
                "source": c.source,
                "metadata": c.metadata,
            }
            for c in chunks
        ]
        # Ghép top chunks thành context block ngắn cho data_analyzer.
        context_block = "\n\n---\n\n".join(
            f"[#{idx+1} score={c.score:.2f} src={c.source or '?'}]\n{c.text}"
            for idx, c in enumerate(chunks)
        )

        return ToolResult(
            tool_name=self.name,
            success=True,
            rows=rows,
            summary={
                "matchCount": len(chunks),
                "context": context_block,
                "topScore": chunks[0].score if chunks else None,
            },
            notes=None if chunks else "Không tìm thấy chunk liên quan trong tài liệu nghiệp vụ.",
        )
