# Verification script for cloud-native-microservice
# Run this before pushing to GitHub to ensure all checks pass

$ErrorActionPreference = "Stop"

Write-Host "=== Cloud-Native Microservice Verification ===" -ForegroundColor Cyan
Write-Host ""

# 1. Run tests (skip -race when CGO is disabled, e.g. Windows without C compiler)
Write-Host "1. Running tests..." -ForegroundColor Yellow
$testArgs = @('-v', '-coverprofile=coverage.txt', '-covermode=atomic', './...')
$cgo = (go env CGO_ENABLED).ToString().Trim()
if ($cgo -eq "1") { $testArgs = @('-v', '-race', '-coverprofile=coverage.txt', '-covermode=atomic', './...') }
& go test @testArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "Tests failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Tests passed!" -ForegroundColor Green
Write-Host ""

# 2. Build
Write-Host "2. Building application..." -ForegroundColor Yellow
go build -o bin/api.exe ./cmd/api
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Build succeeded!" -ForegroundColor Green
Write-Host ""

# 3. Run go vet
Write-Host "3. Running go vet..." -ForegroundColor Yellow
go vet './...'
if ($LASTEXITCODE -ne 0) {
    Write-Host "go vet failed!" -ForegroundColor Red
    exit 1
}
Write-Host "go vet passed!" -ForegroundColor Green
Write-Host ""

# 4. Format and check code
Write-Host "4. Formatting and checking code..." -ForegroundColor Yellow
& go fmt './...' | Out-Null
gofmt -s -w . | Out-Null
$unformatted = gofmt -s -l .
if ($unformatted) {
    Write-Host "Code still has formatting issues:" -ForegroundColor Red
    Write-Host $unformatted
    exit 1
}
Write-Host "Code is properly formatted!" -ForegroundColor Green
Write-Host ""

# 5. Docker build (optional - requires Docker)
Write-Host "5. Building Docker image..." -ForegroundColor Yellow
docker build -t cloud-native-api:test .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed (Docker may not be running)" -ForegroundColor Yellow
} else {
    Write-Host "Docker build succeeded!" -ForegroundColor Green
}
Write-Host ""

Write-Host "=== All verifications complete! Ready for GitHub push. ===" -ForegroundColor Cyan
