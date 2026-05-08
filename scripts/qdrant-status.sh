#!/usr/bin/env bash
set -euo pipefail
echo "=== Container ==="
docker ps -a --filter "name=locavn-qdrant" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "=== Health ==="
if curl -sf http://localhost:6333/collections > /dev/null 2>&1; then
  echo "API responding"
  echo ""
  echo "=== Collections ==="
  curl -s http://localhost:6333/collections | python3 -m json.tool 2>/dev/null \
    || curl -s http://localhost:6333/collections
else
  echo "API not responding at http://localhost:6333"
fi
echo ""
echo "=== Volume ==="
docker volume inspect locavn-qdrant-storage \
  --format "Mountpoint: {{.Mountpoint}}" 2>/dev/null \
  || echo "Volume not created yet (chưa chạy up lần nào)"
