#!/bin/bash
# Start the Prosthetic Hand AI Parameter Generator backend

set -e

cd "$(dirname "$0")"

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed or not in PATH"
    echo "Install Node.js 18+ from https://nodejs.org/"
    exit 1
fi

# Install dependencies if node_modules is missing
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Check for .env file
if [ ! -f ".env" ]; then
    echo "Warning: .env file not found."
    echo "Copy .env.example to .env and set JWT_SECRET and API keys."
    echo ""
    echo "Generating a temporary JWT_SECRET for this session..."
    export JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
    echo "WARNING: Using a temporary secret — sessions will not persist across restarts."
    echo ""
fi

PORT=${PORT:-3000}

echo "Starting server on http://localhost:${PORT}"
echo "Press Ctrl+C to stop"
echo ""

node server/index.js
