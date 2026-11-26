# ============================================================
# setup.ps1 — Script kiểm tra & cài đặt môi trường Lab 8 (Windows)
# ============================================================
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Lab 8 — Setup Docker + Jenkins CD Environment" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

Write-Host "[1/4] Checking Docker Engine..." -ForegroundColor Yellow
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker Engine is not running! Please start Docker Desktop." -ForegroundColor Red
    exit 1
}
Write-Host "Docker: $(docker --version)" -ForegroundColor Green

Write-Host "[2/4] Checking Docker Compose..." -ForegroundColor Yellow
Write-Host "Compose: $(docker compose version)" -ForegroundColor Green

Write-Host "[3/4] Checking Node.js..." -ForegroundColor Yellow
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "Node.js: $(node -v) | npm: $(npm -v)" -ForegroundColor Green
} else {
    Write-Host "Node.js not found locally (Docker will build inside node:18-alpine)" -ForegroundColor Yellow
}

Write-Host "[4/4] Checking Jenkins container from Lab 7..." -ForegroundColor Yellow
$jenkinsContainer = docker ps -a --format "{{.Names}}" | Where-Object { $_ -match "jenkins" }
if ($jenkinsContainer) {
    Write-Host "Found Jenkins container(s): $($jenkinsContainer -join ', ')" -ForegroundColor Green
} else {
    Write-Host "No existing Jenkins container found. Run:" -ForegroundColor Yellow
    Write-Host "  docker run -d -p 8080:8080 -p 50000:50000 -v /var/run/docker.sock:/var/run/docker.sock --name jenkins_jdk21 jenkins/jenkins:lts-jdk21" -ForegroundColor White
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "  SETUP CHECK COMPLETE!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
