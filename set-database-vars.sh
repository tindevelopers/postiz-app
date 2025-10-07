#!/bin/bash

# Database Variables Setup Script
# Usage: ./set-database-vars.sh "postgresql://user:pass@host:port/db" "redis://user:pass@host:port"

if [ $# -ne 2 ]; then
    echo "❌ Usage: $0 \"DATABASE_URL\" \"REDIS_URL\""
    echo ""
    echo "Example:"
    echo "$0 \"postgresql://user:pass@switchback.proxy.rlwy.net:5432/mydb\" \"redis://user:pass@switchback.proxy.rlwy.net:6379\""
    exit 1
fi

DATABASE_URL="$1"
REDIS_URL="$2"

echo "🔧 Setting up database environment variables..."

# Set the database URLs
railway variables --set "DATABASE_URL=$DATABASE_URL"
railway variables --set "REDIS_URL=$REDIS_URL"

# Set other required environment variables
railway variables --set "NODE_ENV=production"
railway variables --set "PORT=5000"
railway variables --set "MAIN_URL=https://postiz-app-clean.railway.app"
railway variables --set "NEXT_PUBLIC_API_URL=https://postiz-app-clean.railway.app/api"
railway variables --set "NEXT_PUBLIC_VERSION=1.0.0"

echo "✅ Environment variables set successfully!"
echo ""
echo "📋 Current variables:"
railway variables

echo ""
echo "🚀 Now you can deploy your application:"
echo "./deploy.sh"
