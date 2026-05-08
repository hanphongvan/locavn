#!/usr/bin/env bash
set -euo pipefail
echo ">>> Stopping Qdrant (data preserved in volume)..."
docker-compose stop qdrant
echo ">>> Qdrant stopped. Run qdrant-up.sh to restart."
