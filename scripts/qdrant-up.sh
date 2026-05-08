#!/usr/bin/env bash
set -euo pipefail

echo ">>> Starting Qdrant..."
docker-compose up -d qdrant

echo ">>> Waiting for Qdrant to be healthy..."
for i in {1..30}; do
  if curl -sf http://localhost:6333/collections > /dev/null 2>&1; then
    echo ">>> Qdrant is ready at http://localhost:6333"
    echo ">>> Collections: $(curl -s http://localhost:6333/collections)"
    exit 0
  fi
  sleep 1
done

echo "!!! Qdrant did not become ready within 30s"
docker-compose logs --tail=30 qdrant
exit 1
