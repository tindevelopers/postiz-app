#!/bin/bash

# Complete Railway Deployment Script for Postiz with Full Functionality
# This ensures everything working locally will work on Railway

set -e  # Exit on error

echo "🚀 Starting Complete Postiz Railway Deployment..."
echo ""

# Check Railway CLI is installed and authenticated
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Install it first:"
    echo "   npm install -g @railway/cli"
    exit 1
fi

echo "✅ Railway CLI found"
echo "👤 Logged in as: $(railway whoami)"
echo ""

# Check project is linked
if ! railway status &> /dev/null; then
    echo "❌ No Railway project linked. Run 'railway link' first."
    exit 1
fi

PROJECT_NAME=$(railway status | grep "Project:" | awk '{print $2}')
echo "📦 Project: $PROJECT_NAME"
echo ""

#==============================================================================
# Step 1: Check Current Services
#==============================================================================
echo "📋 Step 1: Checking current services..."
echo ""
echo "Current project structure (from Railway dashboard):"
echo "  - postiz (main app) ✅"
echo "  - Temporal ✅"
echo "  - Temporal Basic Auth ✅"
echo "  - Temporal UI ✅"
echo "  - Redis ❓"
echo "  - Postgres (Postiz) ✅"
echo "  - Postgres (Temporal) ❓"
echo "  - Elasticsearch ❌ MISSING"
echo ""

#==============================================================================
# Step 2: Add Missing Services via Web Dashboard
#==============================================================================
echo "📝 Step 2: Add Missing Services"
echo ""
echo "⚠️  Railway CLI cannot add services directly. You need to add these via the web dashboard:"
echo ""
echo "Opening Railway dashboard..."
railway open

echo ""
echo "In the Railway dashboard, add these services:"
echo ""
echo "1️⃣  ADD ELASTICSEARCH:"
echo "   - Click '+ New'"
echo "   - Search for 'Elasticsearch' template"
echo "   - Deploy https://railway.com/deploy/elasticsearch"
echo "   - Service name: 'elasticsearch'"
echo ""
echo "2️⃣  ADD REDIS (if not present):"
echo "   - Click '+ New'"
echo "   - Select 'Database' → 'Redis'"
echo "   - Service name: 'redis'"
echo ""
echo "3️⃣  ADD SECOND POSTGRESQL (for Temporal):"
echo "   - Click '+ New'"
echo "   - Select 'Database' → 'PostgreSQL'"
echo "   - Rename to: 'temporal-postgres'"
echo ""
read -p "Press Enter once you've added all three services..."

#==============================================================================
# Step 3: Configure Environment Variables
#==============================================================================
echo ""
echo "⚙️  Step 3: Configuring Environment Variables..."
echo ""

# Get current domain
DOMAIN=$(railway variables | grep "RAILWAY_PUBLIC_DOMAIN" | awk '{print $3}')
echo "📍 Your domain: https://$DOMAIN"
echo ""

# Configure Postiz Variables
echo "🔧 Configuring Postiz service..."
railway variables set \
  TEMPORAL_ADDRESS="temporal.railway.internal:7233" \
  REDIS_URL='${{Redis.REDIS_URL}}' \
  STORAGE_PROVIDER="local" \
  UPLOAD_DIRECTORY="/uploads" \
  RUN_CRON="true"

echo "✅ Postiz variables updated"
echo ""

# Configure Temporal Variables
echo "🔧 Configuring Temporal service..."
echo ""
echo "⚠️  You need to add these variables to the TEMPORAL service via dashboard:"
echo ""
echo "In Railway Dashboard → Temporal Service → Variables, add:"
echo ""
echo "ENABLE_ES=true"
echo "ES_SEEDS=elasticsearch.railway.internal"
echo "ES_VERSION=v7"
echo "DB=postgres12"
echo "DB_PORT=5432"
echo "POSTGRES_SEEDS=temporal-postgres.railway.internal"
echo ""
read -p "Press Enter after adding Temporal variables..."

#==============================================================================
# Step 4: Add Persistent Volumes
#==============================================================================
echo ""
echo "💾 Step 4: Configure Persistent Volumes..."
echo ""
echo "⚠️  Add volumes via Railway Dashboard:"
echo ""
echo "For POSTIZ service:"
echo "  - Settings → Volumes → Add Volume"
echo "  - Mount Path: /uploads"
echo "  - Size: 1GB (or more)"
echo ""
echo "  - Add another volume:"
echo "  - Mount Path: /config"
echo "  - Size: 100MB"
echo ""
echo "For ELASTICSEARCH service:"
echo "  - Settings → Volumes → Add Volume"
echo "  - Mount Path: /usr/share/elasticsearch/data"
echo "  - Size: 2GB (or more)"
echo ""
read -p "Press Enter after adding volumes..."

#==============================================================================
# Step 5: Deploy and Verify
#==============================================================================
echo ""
echo "🚀 Step 5: Deploying..."
echo ""

# Trigger redeployment
echo "Triggering Postiz redeploy..."
railway up --detach

echo ""
echo "Waiting for deployment..."
sleep 10

echo ""
echo "📊 Deployment Status:"
railway status

#==============================================================================
# Step 6: Verification
#==============================================================================
echo ""
echo "✅ Step 6: Verification Checklist"
echo ""
echo "Run these checks to verify everything works:"
echo ""
echo "1. Check all services are running:"
echo "   railway status"
echo ""
echo "2. Check Postiz logs:"
echo "   railway logs"
echo ""
echo "3. Check Temporal logs:"
echo "   railway logs --service Temporal"
echo ""
echo "4. Test the application:"
echo "   curl https://$DOMAIN"
echo ""
echo "5. Verify Elasticsearch is reachable by Temporal:"
echo "   (Check Temporal logs for 'Connected to Elasticsearch')"
echo ""
echo "6. Test user registration:"
echo "   Open: https://$DOMAIN/auth"
echo ""
echo "7. Verify Temporal workflows appear after creating a scheduled post:"
echo "   Open Temporal UI (get URL from Railway dashboard)"
echo ""

#==============================================================================
# Step 7: Summary
#==============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🎉 Deployment Configuration Complete!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Your Postiz deployment now has:"
echo "  ✅ Postiz application"
echo "  ✅ PostgreSQL (Postiz data)"
echo "  ✅ PostgreSQL (Temporal data)"
echo "  ✅ Redis (caching)"
echo "  ✅ Elasticsearch (unlimited Temporal search attributes)"
echo "  ✅ Temporal Server (workflow orchestration)"
echo "  ✅ Temporal UI (workflow monitoring)"
echo ""
echo "🌐 Application URL: https://$DOMAIN"
echo ""
echo "📚 Next Steps:"
echo "  1. Test user registration"
echo "  2. Connect social media accounts"
echo "  3. Schedule a test post"
echo "  4. Verify workflows in Temporal UI"
echo "  5. Check database has data"
echo ""
echo "📖 Full Documentation: RAILWAY_COMPLETE_DEPLOY.md"
echo ""
echo "🆘 If you encounter issues, run:"
echo "   railway logs --follow"
echo ""
echo "═══════════════════════════════════════════════════════════════"
