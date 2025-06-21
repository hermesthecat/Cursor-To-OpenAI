#!/bin/bash

# Cursor To OpenAI - Start Script
echo "==================================="
echo "  Cursor To OpenAI Server Startup  "
echo "==================================="

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found!"
    echo "📝 Please run 'npm run login' first to get your Cursor token"
    echo "   or manually create .env file with CURSOR_TOKEN=your_token"
    exit 1
fi

# Check if CURSOR_TOKEN is set in .env
if ! grep -q "CURSOR_TOKEN=" .env; then
    echo "⚠️  CURSOR_TOKEN not found in .env file!"
    echo "📝 Please run 'npm run login' to get your Cursor token"
    exit 1
fi

# Check if CURSOR_TOKEN has a value
TOKEN_VALUE=$(grep "CURSOR_TOKEN=" .env | cut -d '=' -f2-)
if [ -z "$TOKEN_VALUE" ] || [ "$TOKEN_VALUE" = "" ]; then
    echo "⚠️  CURSOR_TOKEN is empty in .env file!"
    echo "📝 Please run 'npm run login' to get your Cursor token"
    exit 1
fi

echo "✅ .env file found with CURSOR_TOKEN"
echo "🚀 Starting Cursor To OpenAI server..."
echo ""

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo ""
fi

# Start the server
echo "🌟 Server starting on http://localhost:3010"
echo ""
echo "Press Ctrl+C to stop the server"
echo "==================================="

npm start 