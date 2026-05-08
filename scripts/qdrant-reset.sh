#!/usr/bin/env bash
set -euo pipefail
read -p "CẢNH BÁO: Lệnh này sẽ XÓA toàn bộ embedding của Qdrant. Tiếp tục? (yes/N) " answer
if [ "$answer" != "yes" ]; then
  echo "Hủy."
  exit 0
fi
docker-compose stop qdrant
docker-compose rm -f qdrant
docker volume rm locavn-qdrant-storage
echo ">>> Reset xong. Chạy qdrant-up.sh để khởi tạo lại."
