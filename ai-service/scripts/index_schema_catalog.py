"""Phase 5D — script index `AiSchemaCatalog` vào Qdrant collection `ai_schema_catalog`.

Usage:
    cd ai-service
    .venv/Scripts/python.exe scripts/index_schema_catalog.py
    .venv/Scripts/python.exe scripts/index_schema_catalog.py --verbose

Yêu cầu môi trường:
- Ollama đang chạy + đã `ollama pull bge-m3` (Phase 4).
- Qdrant đang chạy (Docker `locavn-qdrant` healthy).
- .NET API đang chạy + endpoint `GET /internal/ai/schema-catalog` reachable.
- File `.env` set: `OLLAMA_BASE_URL`, `QDRANT_URL`, `DOTNET_API_BASE_URL`,
  `AI_GATEWAY_INTERNAL_KEY`.

Idempotent: re-run không tạo duplicate (deterministic point_id qua uuid5).
Sample question giảm sau update → orphan chunks tự động cleanup.

Phase 5D scope: index tất cả 8 entity. Per-entity (`--entity`) + dry-run sẽ
được thêm ở Phase 5G admin worker khi extend SchemaRetriever public API.

Phase 5G note: trigger `TR_AiSchemaCatalog_AfterUpsert` enqueue vào
`AiReindexQueue` mỗi khi seed/update. Phase 5D KHÔNG đụng queue — Phase 5G
worker sẽ poll và mark done.
"""
from __future__ import annotations

import argparse
import asyncio
import sys
from pathlib import Path

# Cho phép chạy script trực tiếp (không qua module).
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

# Windows default stdout codec là cp1252 — không in được tiếng Việt + emoji.
# Reconfigure UTF-8 để help text + summary output không bị UnicodeEncodeError.
if sys.platform == "win32":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")

from app.config import get_settings  # noqa: E402
from app.services.dotnet_api_client import DotnetApiClient, DotnetApiError  # noqa: E402
from app.services.embedding_service import EmbeddingService  # noqa: E402
from app.services.logging_service import configure_logging, get_logger  # noqa: E402
from app.services.qdrant_service import QdrantError, QdrantService  # noqa: E402
from app.services.schema_retriever import (  # noqa: E402
    SCHEMA_COLLECTION_NAME,
    SCHEMA_VECTOR_SIZE,
    SchemaRetriever,
    SchemaRetrieverError,
)

_logger = get_logger(__name__)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="index_schema_catalog",
        description=(
            "Phase 5D — index AiSchemaCatalog (8 entity) vào Qdrant collection "
            f"'{SCHEMA_COLLECTION_NAME}' để Schema Retriever search khi intent=UNKNOWN."
        ),
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Bật structlog INFO level (mặc định WARNING).",
    )
    return parser.parse_args(argv)


async def run(verbose: bool) -> int:
    """Build deps standalone → index_all_entities → print summary.

    Returns: exit code (0 success, 1 lỗi config, 2 lỗi runtime).
    """
    configure_logging(level="INFO" if verbose else "WARNING", json_format=False)

    settings = get_settings()

    # Sanity check trước khi kết nối — báo lỗi user-friendly.
    if not settings.ai_gateway_internal_key:
        print(
            "❌ AI_GATEWAY_INTERNAL_KEY chưa được set trong .env — không thể "
            "fetch /internal/ai/schema-catalog. Set env var rồi chạy lại.",
            file=sys.stderr,
        )
        return 1

    embedding = EmbeddingService(base_url=settings.ollama_base_url)
    qdrant = QdrantService(
        url=settings.qdrant_url,
        collection=SCHEMA_COLLECTION_NAME,
        vector_size=SCHEMA_VECTOR_SIZE,
    )
    dotnet = DotnetApiClient(settings)
    retriever = SchemaRetriever(embedding=embedding, qdrant=qdrant, dotnet=dotnet)

    print(
        f"→ Indexing AiSchemaCatalog vào Qdrant collection '{SCHEMA_COLLECTION_NAME}' "
        f"(qdrant={settings.qdrant_url}, ollama={settings.ollama_base_url}, "
        f"dotnet={settings.dotnet_api_base_url})..."
    )

    try:
        try:
            summary = await retriever.index_all_entities()
        except SchemaRetrieverError as ex:
            print(f"❌ Index fail: {ex}", file=sys.stderr)
            return 2
        except DotnetApiError as ex:
            print(f"❌ .NET API không phản hồi: {ex}", file=sys.stderr)
            return 2
        except QdrantError as ex:
            print(f"❌ Qdrant lỗi: {ex}", file=sys.stderr)
            return 2

        print()
        print("✅ Index complete:")
        print(f"   entities_fetched : {summary['entities_fetched']}")
        print(f"   entities_indexed : {summary['entities_indexed']}")
        print(f"   entities_failed  : {summary['entities_failed']}")
        print(f"   chunks_upserted  : {summary['chunks_upserted']}")
        print(f"   orphans_cleaned  : {summary['orphans_cleaned']}")
        print()
        print(
            "ℹ Phase 5G worker sẽ poll AiReindexQueue và mark pending entries "
            "thành done. Phase 5D không đụng queue (theo design)."
        )

        if summary["entities_failed"] > 0:
            print(
                f"⚠ {summary['entities_failed']} entity fail khi index — xem log "
                "WARNING (chạy lại với --verbose).",
                file=sys.stderr,
            )
            return 2

        return 0
    finally:
        await qdrant.close()


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    return asyncio.run(run(verbose=args.verbose))


if __name__ == "__main__":
    sys.exit(main())
