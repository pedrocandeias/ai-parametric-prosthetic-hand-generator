#!/bin/bash

# Deployment script for Prosthetic Hand AI Parameter Generator
# Usage: ./deploy.sh [server_user@server_host:/path/to/deployment]

set -e  # Exit on error

echo "=========================================="
echo "Prosthetic Hand AI Parameter Generator"
echo "Deployment Script"
echo "=========================================="
echo ""

# Check if destination is provided
if [ -z "$1" ]; then
    echo "Usage: $0 server_user@server_host:/path/to/deployment"
    echo ""
    echo "Example:"
    echo "  $0 user@example.com:/var/www/html/prosthetic-hand"
    echo ""
    exit 1
fi

DESTINATION="$1"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEPLOY_DIR="${SCRIPT_DIR}/deploy"

echo "Source directory: ${SCRIPT_DIR}"
echo "Deploy directory: ${DEPLOY_DIR}"
echo "Destination: ${DESTINATION}"
echo ""

# Check if config.json exists
if [ ! -f "${SCRIPT_DIR}/config.json" ]; then
    echo "❌ Error: config.json not found!"
    echo "   Please create config.json from config.example.json and add your API keys"
    echo ""
    echo "   Run: cp config.example.json config.json"
    echo "   Then edit config.json and add your API keys"
    exit 1
fi

# Check if config.json has real API keys (basic check)
if grep -q "YOUR_ANTHROPIC_API_KEY_HERE" "${SCRIPT_DIR}/config.json" || \
   grep -q "YOUR_OPENAI_API_KEY_HERE" "${SCRIPT_DIR}/config.json"; then
    echo "⚠️  Warning: config.json still contains placeholder API keys"
    echo "   Please edit config.json and add your real API keys"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create deploy directory
echo "Creating deployment package..."
rm -rf "${DEPLOY_DIR}"
mkdir -p "${DEPLOY_DIR}"

# Copy files excluding development artifacts
rsync -av --progress \
    --exclude='deploy' \
    --exclude='deploy.sh' \
    --exclude='public' \
    --exclude='.git' \
    --exclude='.gitignore' \
    --exclude='node_modules' \
    --exclude='.vscode' \
    --exclude='.idea' \
    --exclude='*.log' \
    --exclude='*.swp' \
    --exclude='*.swo' \
    --exclude='.DS_Store' \
    --exclude='Thumbs.db' \
    "${SCRIPT_DIR}/" "${DEPLOY_DIR}/"

echo ""
echo "✅ Deployment package created in: ${DEPLOY_DIR}"
echo ""

# Ask for confirmation
echo "Ready to deploy to: ${DESTINATION}"
read -p "Continue with deployment? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Deploy using rsync
echo ""
echo "Deploying to server..."
echo ""

rsync -avz --progress \
    --delete \
    "${DEPLOY_DIR}/" "${DESTINATION}/"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Deployment successful!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. SSH into your server"
    echo "2. Set correct permissions:"
    echo "   cd ${DESTINATION##*:}"
    echo "   chmod 755 ."
    echo "   find . -type d -exec chmod 755 {} \;"
    echo "   find . -type f -exec chmod 644 {} \;"
    echo "   chmod 640 config.json"
    echo ""
    echo "3. Configure your web server (Apache/Nginx)"
    echo "   See DEPLOYMENT.md for details"
    echo ""
    echo "4. Test the application in your browser"
    echo ""
else
    echo ""
    echo "❌ Deployment failed!"
    echo "Please check the error messages above"
    exit 1
fi
