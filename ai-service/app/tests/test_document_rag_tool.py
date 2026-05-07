"""Test DocumentRAGTool — mock embedding + qdrant để không cần Ollama/Qdrant runtime."""
from __future__ import annotations

import pytest

from app.config import get_settings
from app.services.embedding_service import EmbeddingError
from app.services.qdrant_service import QdrantError, RagChunk
from app.tools.document_rag_tool import DocumentRAGTool


class _FakeEmbedding:
    def __init__(self, vector=None, raise_error=None):
        self._vector = vector or [0.1] * 1024
        self._error = raise_error
        self.calls: list[str] = []

    async def embed(self, text: str):
        self.calls.append(text)
        if self._error:
            raise self._error
        return self._vector


class _FakeQdrant:
    def __init__(self, chunks=None, raise_error=None):
        self._chunks = chunks or []
        self._error = raise_error
        self.search_calls: list[tuple[list[float], int]] = []

    async def search(self, query_vector, *, limit=5, score_threshold=0.4):
        self.search_calls.append((query_vector, limit))
        if self._error:
            raise self._error
        return self._chunks


@pytest.fixture
def tool_factory(tmp_path):
    settings = get_settings()

    def _make(embedding=None, qdrant=None, top_k=5):
        return DocumentRAGTool(
            embedding=embedding or _FakeEmbedding(),
            qdrant=qdrant or _FakeQdrant(),
            top_k=top_k,
            mock_data_path=tmp_path / "mock.json",
            use_mock=True,
        )

    return _make


async def test_returns_top_k_chunks_with_context_block(tool_factory):
    chunks = [
        RagChunk(id="1", score=0.91, text="Hướng dẫn mở dashboard tồn kho.",
                 source="huong-dan.pdf", metadata={"page": 1}),
        RagChunk(id="2", score=0.87, text="Mức tồn an toàn theo Nghị định 95.",
                 source="nghi-dinh-95.pdf", metadata={"page": 5}),
    ]
    qdrant = _FakeQdrant(chunks=chunks)
    tool = tool_factory(qdrant=qdrant)

    result = await tool.run({"query": "Tồn an toàn xăng dầu là gì?"})

    assert result.success
    assert len(result.rows) == 2
    assert result.rows[0]["score"] == 0.91
    assert result.rows[0]["source"] == "huong-dan.pdf"

    summary = result.summary
    assert summary is not None
    assert summary["matchCount"] == 2
    assert summary["topScore"] == 0.91
    # Context block ghép 2 chunk với separator để LLM dễ parse.
    assert "Hướng dẫn mở dashboard" in summary["context"]
    assert "Nghị định 95" in summary["context"]
    assert "---" in summary["context"]


async def test_empty_query_returns_failed_result(tool_factory):
    tool = tool_factory()
    result = await tool.run({"query": "   "})
    assert not result.success
    assert "rỗng" in (result.error or "")


async def test_no_chunks_found_returns_success_with_notes(tool_factory):
    tool = tool_factory(qdrant=_FakeQdrant(chunks=[]))
    result = await tool.run({"query": "Câu hỏi không liên quan tài liệu"})

    assert result.success
    assert result.rows == []
    assert "Không tìm thấy" in (result.notes or "")


async def test_embedding_failure_returns_failed_result_no_qdrant_call(tool_factory):
    embedding = _FakeEmbedding(raise_error=EmbeddingError("Ollama down"))
    qdrant = _FakeQdrant()
    tool = tool_factory(embedding=embedding, qdrant=qdrant)

    result = await tool.run({"query": "x"})
    assert not result.success
    assert "Ollama down" in (result.error or "")
    assert qdrant.search_calls == []  # không gọi Qdrant nếu embed fail.


async def test_qdrant_failure_returns_failed_result(tool_factory):
    qdrant = _FakeQdrant(raise_error=QdrantError("connection refused"))
    tool = tool_factory(qdrant=qdrant)

    result = await tool.run({"query": "Tồn an toàn"})
    assert not result.success
    assert "connection refused" in (result.error or "")


async def test_top_k_passed_to_qdrant_search(tool_factory):
    qdrant = _FakeQdrant()
    tool = tool_factory(qdrant=qdrant, top_k=3)

    await tool.run({"query": "x"})
    assert qdrant.search_calls[0][1] == 3
