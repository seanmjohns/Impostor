.PHONY: build run test clean

ARCH ?= arm64
S3_BUCKET ?= cypress-studios

# Build the server binary
build:
	go build -o bin/impostor ./cmd/server

# Build for Linux AMD64 (for x86_64 EC2 instances like t3.micro)
build-linux-amd64:
	GOOS=linux GOARCH=amd64 go build -o bin/impostor ./cmd/server

# Build for Linux ARM64 (for ARM EC2 instances like t4g.nano)
build-linux-arm64:
	GOOS=linux GOARCH=arm64 go build -o bin/impostor ./cmd/server

# Run the server (port 8080)
run: build
	@echo "🎭 Starting Impostor on http://localhost:8080"
	@echo "Press Ctrl+C to stop"
	@./bin/impostor

# Run with custom port
run-port: build
	@echo "🎭 Starting Impostor on http://localhost:$(PORT)"
	@echo "Press Ctrl+C to stop"
	@PORT=$(PORT) ./bin/impostor

# Run tests
test:
	go test ./...

# Run tests with verbose output
test-verbose:
	go test -v ./...

# Clean build artifacts
clean:
	rm -rf bin/

# Run the server with custom settings
run-dev:
	PORT=3000 ./bin/impostor

# Format code
fmt:
	go fmt ./...

# Run linter
lint:
	golangci-lint run

# Install dependencies
deps:
	go mod download
	go mod tidy

# Deployment targets
upload-to-s3:
	@echo "☁️  Building for Linux $(ARCH)..."
	@if [ "$(ARCH)" = "amd64" ]; then \
		$(MAKE) build-linux-amd64; \
	elif [ "$(ARCH)" = "arm64" ]; then \
		$(MAKE) build-linux-arm64; \
	else \
		echo "ℹ️  No ARCH specified, defaulting to arm64 (for t4g instances)"; \
		$(MAKE) build-linux-arm64; \
	fi
	@echo "☁️  Uploading artifacts to S3 bucket: $(S3_BUCKET)"
	@aws s3 cp ./bin/impostor s3://$(S3_BUCKET)/impostor
	@aws s3 cp ./index.html s3://$(S3_BUCKET)/index.html
	@aws s3 cp ./wordlist.txt s3://$(S3_BUCKET)/wordlist.txt
	@echo "✅ Upload complete!"

terraform-init:
	@cd terraform && terraform init

terraform-plan:
	@cd terraform && terraform plan

terraform-apply:
	@cd terraform && terraform apply

deploy:
	@echo "🎭 Deploying Impostor Game..."
	@echo ""
	@echo "📦 Step 1/3: Building application..."
	@if [ "$(ARCH)" = "amd64" ]; then \
		$(MAKE) build-linux-amd64; \
	elif [ "$(ARCH)" = "arm64" ]; then \
		$(MAKE) build-linux-arm64; \
	else \
		echo "ℹ️  No ARCH specified, defaulting to arm64 (for t4g instances)"; \
		$(MAKE) build-linux-arm64; \
	fi
	@echo ""
	@echo "☁️  Step 2/3: Uploading to S3..."
	@aws s3 cp ./bin/impostor s3://$(S3_BUCKET)/impostor
	@aws s3 cp ./index.html s3://$(S3_BUCKET)/index.html
	@aws s3 cp ./wordlist.txt s3://$(S3_BUCKET)/wordlist.txt
	@echo "✅ Upload complete!"
	@echo ""
	@echo "🔧 Initializing Terraform..."
	@cd terraform && terraform init && terraform plan
	@echo ""
	@echo "🚀 Step 3/3: Deploying infrastructure..."
	@echo ""
	@cd terraform && terraform apply -replace=aws_instance.impostor_server
	@echo ""
	@echo "✅ Deployment complete!"
	@echo ""
	@cd terraform && terraform output game_url