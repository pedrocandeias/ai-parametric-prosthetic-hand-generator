#!/bin/bash

# OpenSCAD Parameter Editor - Start Script

echo "========================================"
echo "OpenSCAD Parameter Editor"
echo "========================================"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to that directory
cd "$SCRIPT_DIR" || exit 1

echo "Working directory: $SCRIPT_DIR"
echo ""

# Check for required files
echo "Checking for required files..."

if [ ! -f "public/openscad.wasm" ]; then
    echo "❌ Error: openscad.wasm not found in public/"
    echo "   Please copy it from openscad-playground/dist/"
    exit 1
fi

if [ ! -f "public/openscad-worker.js" ]; then
    echo "❌ Error: openscad-worker.js not found in public/"
    echo "   Please copy it from openscad-playground/dist/"
    exit 1
fi

if [ ! -f "public/model-viewer.min.js" ]; then
    echo "❌ Error: model-viewer.min.js not found in public/"
    echo "   Please copy it from openscad-playground/public/"
    exit 1
fi

if [ ! -f "public/browserfs.min.js" ]; then
    echo "❌ Error: browserfs.min.js not found in public/"
    echo "   Please copy it from openscad-playground/public/"
    exit 1
fi

echo "✅ All required files found"
echo ""

# Find available port
PORT=8000
while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; do
    echo "⚠️  Port $PORT is in use, trying $((PORT+1))..."
    PORT=$((PORT+1))
done

echo "Starting server on port $PORT..."
echo ""
echo "🌐 Open your browser and navigate to:"
echo "   http://localhost:$PORT/public/"
echo ""
echo "Press Ctrl+C to stop the server"
echo "========================================"
echo ""

# Start the server
if command -v python3 &> /dev/null; then
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    python -m http.server $PORT
else
    echo "❌ Error: Python is not installed"
    echo "   Please install Python 3 or use another web server"
    exit 1
fi
