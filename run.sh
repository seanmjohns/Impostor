#!/bin/bash

# Impostor Game Server Launcher
# Usage: ./run.sh [port]

PORT=${1:-8081}

echo "🎭 Starting Impostor Game Server..."
echo "📍 Server will be available at: http://localhost:$PORT"
echo ""

# Check if binary exists
if [ ! -f "./bin/impostor" ]; then
    echo "⚠️  Server binary not found. Building..."
    make build
    if [ $? -ne 0 ]; then
        echo "❌ Build failed!"
        exit 1
    fi
    echo "✅ Build complete!"
    echo ""
fi

# Start server
echo "🚀 Starting server on port $PORT..."
echo "📖 Open http://localhost:$PORT in your browser to play!"
echo ""
echo "Press Ctrl+C to stop the server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

./bin/impostor -port $PORT
