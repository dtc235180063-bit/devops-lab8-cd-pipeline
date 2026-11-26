#!/bin/bash
# ============================================================
# verify.sh — Script kiểm tra kết quả Lab 8
# ============================================================
PASS=0; FAIL=0; TOTAL=0
check() {
    TOTAL=$((TOTAL + 1))
    echo -n "[$TOTAL] $1 ... "
    if [ "$2" = "OK" ]; then echo "✅ PASS"; PASS=$((PASS + 1))
    else echo "❌ $2"; FAIL=$((FAIL + 1)); fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

echo "==============================================="
echo "  VERIFY — Lab 8 CD Pipeline"
echo "==============================================="
echo ""

docker info &>/dev/null && check "Docker running" "OK" || check "Docker running" "Start Docker Desktop"
docker compose version &>/dev/null && check "Docker Compose" "OK" || check "Docker Compose" "Not found"

[ -f "$BASE_DIR/Dockerfile" ] && check "Dockerfile exists" "OK" || check "Dockerfile" "Not found"
[ -f "$BASE_DIR/docker-compose.yml" ] && check "docker-compose.yml exists" "OK" || check "docker-compose.yml" "Not found"
[ -f "$BASE_DIR/nginx.conf" ] && check "nginx.conf exists" "OK" || check "nginx.conf" "Not found"
[ -f "$BASE_DIR/Jenkinsfile" ] && check "Jenkinsfile exists" "OK" || check "Jenkinsfile" "Not found"
[ -f "$BASE_DIR/app/server.js" ] && check "app/server.js exists" "OK" || check "app/server.js" "Not found"

docker images --format '{{.Repository}}' 2>/dev/null | grep -q "devops-lab8-app" && check "Docker image built" "OK" || check "Docker image built" "Run: docker build -t devops-lab8-app:1.0 ."

curl -sf http://localhost:3000/health &>/dev/null && check "App running on :3000" "OK" || check "App running on :3000" "Not running"

echo ""
echo "==============================================="
echo "  RESULTS: $PASS/$TOTAL PASS, $FAIL FAIL"
echo "==============================================="
