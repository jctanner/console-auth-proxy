# Console Auth Proxy Makefile

# Variables
REGISTRY ?= registry.tannerjc.net
IMAGE_NAME ?= console-auth-proxy
TAG ?= latest
PLATFORM ?= linux/amd64

# Build variables
VERSION ?= $(shell git describe --tags --always --dirty)
GIT_COMMIT ?= $(shell git rev-parse HEAD)
BUILD_DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Full image reference
IMAGE_REF = $(REGISTRY)/$(IMAGE_NAME):$(TAG)

.PHONY: help build push run clean test dev

help: ## Show this help message
	@echo "Console Auth Proxy - Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the container image
	@echo "Building $(IMAGE_REF) for $(PLATFORM)..."
	docker build \
		--platform $(PLATFORM) \
		--build-arg VERSION="$(VERSION)" \
		--build-arg GIT_COMMIT="$(GIT_COMMIT)" \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--tag $(IMAGE_REF) \
		.
	@echo "✅ Built $(IMAGE_REF)"

push: build ## Build and push the container image
	@echo "Pushing $(IMAGE_REF)..."
	docker push $(IMAGE_REF)
	@echo "✅ Pushed $(IMAGE_REF)"

run: ## Run the container locally
	@echo "Running $(IMAGE_REF)..."
	docker run --rm -it \
		-p 8080:8080 \
		-e CAP_AUTH_AUTH_SOURCE=oidc \
		-e CAP_AUTH_ISSUER_URL=https://keycloak.tannerjc.net/realms/console-proxy \
		-e CAP_AUTH_CLIENT_ID=console-auth-proxy \
		-e CAP_AUTH_CLIENT_SECRET=console-secret-key \
		-e CAP_AUTH_REDIRECT_URL=http://localhost:8080/auth/callback \
		-e CAP_PROXY_BACKEND_URL=http://httpbin.org \
		-e CAP_AUTH_SECURE_COOKIES=false \
		-e CAP_AUTH_TLS_INSECURE_SKIP_VERIFY=true \
		$(IMAGE_REF)

dev: ## Start development environment with docker-compose
	@echo "Starting development environment..."
	docker-compose up -d

dev-logs: ## Show development environment logs
	docker-compose logs -f console-auth-proxy

dev-stop: ## Stop development environment
	docker-compose down

clean: ## Clean up local images and containers
	@echo "Cleaning up..."
	-docker rmi $(IMAGE_REF) 2>/dev/null || true
	-docker system prune -f
	@echo "✅ Cleaned up"

test: ## Run tests
	@echo "Running tests..."
	go test ./...

build-binary: ## Build the Go binary locally
	@echo "Building console-auth-proxy binary..."
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
		-ldflags="-w -s \
			-X github.com/jctanner/console-auth-proxy/internal/version.Version=$(VERSION) \
			-X github.com/jctanner/console-auth-proxy/internal/version.GitCommit=$(GIT_COMMIT) \
			-X github.com/jctanner/console-auth-proxy/internal/version.BuildDate=$(BUILD_DATE)" \
		-o console-auth-proxy \
		./cmd/console-auth-proxy
	@echo "✅ Built console-auth-proxy binary"

install: build-binary ## Install the binary to /usr/local/bin
	@echo "Installing console-auth-proxy to /usr/local/bin..."
	sudo cp console-auth-proxy /usr/local/bin/
	sudo chmod +x /usr/local/bin/console-auth-proxy
	@echo "✅ Installed console-auth-proxy"

version: ## Show version information
	@echo "Version: $(VERSION)"
	@echo "Git Commit: $(GIT_COMMIT)"
	@echo "Build Date: $(BUILD_DATE)"
	@echo "Image: $(IMAGE_REF)"

# Development helpers
fmt: ## Format Go code
	go fmt ./...

lint: ## Run linter
	golangci-lint run

mod-tidy: ## Tidy Go modules
	go mod tidy

# Quick targets
quick-build: ## Quick build without cache
	docker build --no-cache --platform $(PLATFORM) -t $(IMAGE_REF) .

quick-push: quick-build push ## Quick build and push without cache