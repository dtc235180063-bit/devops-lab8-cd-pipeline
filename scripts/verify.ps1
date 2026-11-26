# ============================================================
# verify.ps1 — Script kiểm tra kết quả Lab 8 (Windows)
# ============================================================
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  VERIFY — Lab 8 CD Pipeline" -ForegroundColor Cyan
Write-Host "  Sinh viên: Nguyễn Văn Hải - MSSV: DTC235180063" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

$Pass = 0
$Fail = 0
$Total = 0

function Check-Result($title, $ok, $errMsg = "") {
    $script:Total++
    Write-Host -NoNewline "[$script:Total] $title ... "
    if ($ok) {
        Write-Host "✅ PASS" -ForegroundColor Green
        $script:Pass++
    } else {
        Write-Host "❌ FAIL: $errMsg" -ForegroundColor Red
        $script:Fail++
    }
}

$baseDir = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path "$baseDir\Dockerfile")) {
    $baseDir = $PSScriptRoot
}

# 1. Docker engine & compose
docker info 2>&1 | Out-Null
Check-Result "Docker daemon running" ($LASTEXITCODE -eq 0) "Start Docker Desktop"

docker compose version 2>&1 | Out-Null
Check-Result "Docker Compose v2 available" ($LASTEXITCODE -eq 0) "Not found"

# 2. Required project files
Check-Result "Dockerfile exists" (Test-Path "$baseDir\Dockerfile") "Not found"
Check-Result "docker-compose.yml exists" (Test-Path "$baseDir\docker-compose.yml") "Not found"
Check-Result "nginx.conf exists" (Test-Path "$baseDir\nginx.conf") "Not found"
Check-Result "Jenkinsfile exists" (Test-Path "$baseDir\Jenkinsfile") "Not found"
Check-Result "app/server.js exists" (Test-Path "$baseDir\app\server.js") "Not found"
Check-Result "app/package.json exists" (Test-Path "$baseDir\app\package.json") "Not found"
Check-Result "ho_ten_mssv.txt exists" (Test-Path "$baseDir\ho_ten_mssv.txt") "Not found"

# 3. Docker images
$images = docker images --format "{{.Repository}}:{{.Tag}}" 2>$null
Check-Result "Multi-stage image devops-lab8-app:1.0 built" ($images -match "devops-lab8-app:1\.0") "Run: docker build -t devops-lab8-app:1.0 ."
Check-Result "Fat image devops-lab8-app:fat built (comparison)" ($images -match "devops-lab8-app:fat") "Run: docker build -f Dockerfile.fat -t devops-lab8-app:fat ."

# 4. Evidence screenshots
$screens = @(
    "01-docker-build.png",
    "02-docker-images-size.png",
    "03-compose-ps.png",
    "04-docker-hub.png",
    "05-jenkins-cd-pipeline.png",
    "06-verify-deploy.png",
    "07-ci-vs-cd-table.png"
)
$missingScreens = $screens | Where-Object { -not (Test-Path "$baseDir\screenshots\$_") }
Check-Result "All 7 rubric screenshots exist" ($missingScreens.Count -eq 0) ("Missing: " + ($missingScreens -join ", "))

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  RESULTS: $Pass/$Total PASS, $Fail FAIL" -ForegroundColor $(if ($Fail -eq 0) { "Green" } else { "Yellow" })
Write-Host "===============================================" -ForegroundColor Cyan
