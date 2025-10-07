#!/bin/bash

# Database URL Setup Script
# This script helps you set up the correct database URLs for Railway

echo "🔧 Setting up database URLs for Railway..."

# Get the current project info
echo "📋 Current project:"
railway status

echo ""
echo "📝 To set up your database URLs, you need to add these environment variables:"
echo ""
echo "For PostgreSQL:"
echo "DATABASE_URL=postgresql://username:password@switchback.proxy.rlwy.net:PORT/database_name"
echo ""
echo "For Redis:"
echo "REDIS_URL=redis://username:password@switchback.proxy.rlwy.net:PORT"
echo ""
echo "🔍 To get the complete URLs:"
echo "1. Go to Railway dashboard: https://railway.com/project/0d9ff122-efd4-490e-82d0-de1300be7ca2"
echo "2. Click on your PostgreSQL service"
echo "3. Go to 'Variables' tab"
echo "4. Copy the DATABASE_URL"
echo "5. Click on your Redis service"
echo "6. Go to 'Variables' tab"
echo "7. Copy the REDIS_URL"
echo ""
echo "Then set them in your Railway project:"
echo "railway variables --set 'DATABASE_URL=your_postgres_url'"
echo "railway variables --set 'REDIS_URL=your_redis_url'"
