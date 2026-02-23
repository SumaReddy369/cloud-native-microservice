.PHONY: help build run test docker-build docker-run k8s-deploy k8s-delete helm-install helm-uninstall clean

# Variables
APP_NAME=cloud-native-api
DOCKER_IMAGE=sumareddy369/$(APP_NAME)
NAMESPACE=cloud-native

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the Go application
	@echo "Building application..."
	go build -o bin/api ./cmd/api

run: ## Run the application locally
	@echo "Running application..."
	go run ./cmd/api

test: ## Run tests (CI uses -race on Linux; omit locally if CGO is disabled)
	@echo "Running tests..."
	go test -v -coverprofile=coverage.txt -covermode=atomic ./...

lint: ## Run linter
	@echo "Running linter..."
	golangci-lint run

fmt: ## Format code
	@echo "Formatting code..."
	go fmt ./...
	gofmt -s -w .

vet: ## Run go vet
	@echo "Running go vet..."
	go vet ./...

docker-build: ## Build Docker image
	@echo "Building Docker image..."
	docker build -t $(DOCKER_IMAGE):latest .

docker-run: ## Run Docker container
	@echo "Running Docker container..."
	docker run -p 8080:8080 $(DOCKER_IMAGE):latest

docker-push: ## Push Docker image to registry
	@echo "Pushing Docker image..."
	docker push $(DOCKER_IMAGE):latest

k8s-deploy: ## Deploy to Kubernetes
	@echo "Deploying to Kubernetes..."
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/configmap.yaml
	kubectl apply -f k8s/deployment.yaml
	kubectl apply -f k8s/service.yaml

k8s-delete: ## Delete Kubernetes resources
	@echo "Deleting Kubernetes resources..."
	kubectl delete -f k8s/ --ignore-not-found=true

helm-install: ## Install Helm chart
	@echo "Installing Helm chart..."
	helm install $(APP_NAME) ./helm/$(APP_NAME) --namespace $(NAMESPACE) --create-namespace

helm-upgrade: ## Upgrade Helm release
	@echo "Upgrading Helm release..."
	helm upgrade $(APP_NAME) ./helm/$(APP_NAME) --namespace $(NAMESPACE)

helm-uninstall: ## Uninstall Helm release
	@echo "Uninstalling Helm release..."
	helm uninstall $(APP_NAME) --namespace $(NAMESPACE)

clean: ## Clean build artifacts
	@echo "Cleaning..."
	rm -rf bin/
	rm -f coverage.txt
	go clean

all: fmt vet lint test build ## Run all checks and build