#!/bin/bash
# Quick start script for OpenSCAD Parameter Editor

echo "Starting OpenSCAD Parameter Editor..."
echo "Server will run on http://localhost:8000"
echo ""
echo "Open your browser and navigate to:"
echo "  http://localhost:8000/public/"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Try to find an available Python installation
if command -v python3 &> /dev/null; then
    cd "$(dirname "$0")"
    python3 -m http.server 8000
elif command -v python &> /dev/null; then
    cd "$(dirname "$0")"
    python -m http.server 8000
else
    echo "Error: Python is not installed or not in PATH"
    echo "Please install Python 3 or use another web server"
    exit 1
fi
