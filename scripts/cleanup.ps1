# ============================================================
# cleanup.ps1 — Script dọn dẹp containers & stacks Lab 8 (Windows)
# ============================================================
param (
    [switch]$RemoveImages
)

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  CLEANUP — Lab 8 CD Pipeline Environment" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

$baseDir = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path "$baseDir\docker-compose.yml")) {
    $baseDir = $PSScriptRoot
}

Write-Host "Stopping Docker Compose stack..." -ForegroundColor Yellow
docker compose -f "$baseDir\docker-compose.yml" down 2>$null

$containers = @("lab8-app", "lab8-cd-production", "lab8-nginx", "lab8-redis", "lab8-test-pull")
foreach ($c in $containers) {
    docker stop $c 2>$null | Out-Null
    docker rm $c 2>$null | Out-Null
}

if ($RemoveImages) {
    Write-Host "Removing local Lab 8 images..." -ForegroundColor Yellow
    docker rmi devops-lab8-app:1.0 devops-lab8-app:fat devops-lab8-app:latest 2>$null | Out-Null
}

Write-Host ""
Write-Host "Remaining Lab 8 containers:" -ForegroundColor Cyan
docker ps -a --filter "name=lab8"
Write-Host "✅ Lab 8 cleaned up." -ForegroundColor Green
