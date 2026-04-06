.PHONY: build run test clean

# Build the server binary
build:
	go build -o bin/impostor ./cmd/server

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
