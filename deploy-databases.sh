#!/bin/bash
# Railway Database Setup Script
# Run this script to add PostgreSQL and Redis databases to your Railway project

set -e

echo "🚀 Setting up databases for Postiz on Railway..."
echo ""

# Ensure we're in the right directory
cd "$(dirname "$0")"

# Link to postiz service
echo "📦 Linking to postiz service..."
railway service postiz

# Add PostgreSQL database
echo ""
echo "🐘 Adding PostgreSQL database..."
railway add --database postgres --service postgres-db

# Add Redis database  
echo ""
echo "🔴 Adding Redis database..."
railway add --database redis --service redis-db

# Wait a moment for services to be created
echo ""
echo "⏳ Waiting for services to be provisioned..."
sleep 5

# Link back to postiz service to set variables
echo ""
echo "🔗 Linking back to postiz service..."
railway service postiz

# Set database connection URLs
echo ""
echo "⚙️  Configuring database connection URLs..."
railway variables --set "DATABASE_URL=\${{Postgres.DATABASE_URL}}"
railway variables --set "REDIS_URL=\${{Redis.REDIS_URL}}"

echo ""
echo "✅ Database setup complete!"
echo ""
echo "📊 Current variables:"
railway variables

echo ""
echo "🚀 Redeploying application..."
railway up --detach

echo ""
echo "✨ Deployment complete! Check status with: railway status"
echo "📝 View logs with: railway logs"
