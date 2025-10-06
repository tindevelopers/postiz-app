#!/bin/bash

# Railway Deployment Script
# This script deploys the application to Railway

echo "🚀 Starting Railway deployment..."

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Installing..."
    npm install -g @railway/cli
fi

# Check if we're logged in
if ! railway whoami &> /dev/null; then
    echo "❌ Not logged in to Railway. Please run 'railway login' first."
    exit 1
fi

# Check current project status
echo "📋 Current project status:"
railway status

# Deploy to Railway
echo "📦 Deploying to Railway..."
railway up --detach

echo "✅ Deployment initiated! Check Railway dashboard for status."
echo "🌐 Your app will be available at: https://postiz-app-clean.railway.app"
echo ""
echo "📝 Note: Add databases through Railway UI to avoid creating duplicates:"
echo "   1. Go to Railway dashboard"
echo "   2. Click '+' to add PostgreSQL database"
echo "   3. Click '+' to add Redis database"
echo "   4. Railway will automatically provide DATABASE_URL and REDIS_URL"
