#!/bin/bash
# ============================================================
# cleanup.sh — Script dọn dẹp Lab 8
# ============================================================
echo "Cleaning up Lab 8..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Stop Docker Compose
docker compose -f "$BASE_DIR/docker-compose.yml" down 2>/dev/null || true

# Stop individual containers
for c in lab8-app lab8-cd-production lab8-nginx lab8-redis lab8-test-pull lab8-registry; do
    docker stop "$c" 2>/dev/null && docker rm "$c" 2>/dev/null || true
done

echo "✅ Lab 8 cleaned up."
