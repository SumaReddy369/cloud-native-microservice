#!/bin/bash
# Verification script for cloud-native-microservice
# Run this before pushing to GitHub to ensure all checks pass

set -e

echo "=== Cloud-Native Microservice Verification ==="
echo ""

# 1. Run tests (skip -race when CGO is disabled, e.g. Windows)
echo "1. Running tests..."
RACE_FLAG=""
if [ "$(go env CGO_ENABLED)" = "1" ]; then
    RACE_FLAG="-race"
fi
go test -v $RACE_FLAG -coverprofile=coverage.txt -covermode=atomic ./...
echo "Tests passed!"
echo ""

# 2. Build
echo "2. Building application..."
go build -o bin/api ./cmd/api
echo "Build succeeded!"
echo ""

# 3. Run go vet
echo "3. Running go vet..."
go vet ./...
echo "go vet passed!"
echo ""

# 4. Check formatting
echo "4. Checking code format..."
if [ -n "$(gofmt -s -l .)" ]; then
    echo "Code is not formatted. Run: go fmt ./..."
    gofmt -s -l .
    exit 1
fi
echo "Code is properly formatted!"
echo ""

# 5. Docker build (optional)
echo "5. Building Docker image..."
if docker build -t cloud-native-api:test . 2>/dev/null; then
    echo "Docker build succeeded!"
else
    echo "Docker build skipped (Docker may not be running)"
fi
echo ""

echo "=== All verifications complete! Ready for GitHub push. ==="
