#!/bin/bash
# Pre-deploy validation script for Postiz Railway deployment
# Run this before deploying to a new Railway project to ensure success.
# Usage: ./validate-railway-deploy.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo "═══════════════════════════════════════════════════════════════"
echo "  Postiz Railway Deployment Validation"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 1. Check Railway CLI
echo "1. Checking Railway CLI..."
if ! command -v railway &> /dev/null; then
    echo -e "${RED}   ✗ Railway CLI not found${NC}"
    echo "   Install: npm install -g @railway/cli"
    ((ERRORS++))
else
    echo -e "${GREEN}   ✓ Railway CLI installed${NC}"
fi

# 2. Check authenticated
echo ""
echo "2. Checking Railway authentication..."
if ! railway whoami &> /dev/null; then
    echo -e "${RED}   ✗ Not logged in to Railway${NC}"
    echo "   Run: railway login"
    ((ERRORS++))
else
    echo -e "${GREEN}   ✓ Logged in as: $(railway whoami)${NC}"
fi

# 3. Check project linked
echo ""
echo "3. Checking project link..."
if ! railway status &> /dev/null; then
    echo -e "${RED}   ✗ No Railway project linked${NC}"
    echo "   Run: railway link (or railway init for new project)"
    ((ERRORS++))
else
    PROJECT=$(railway status 2>/dev/null | grep "Project:" | awk '{print $2}')
    ENV=$(railway status 2>/dev/null | grep "Environment:" | awk '{print $2}')
    echo -e "${GREEN}   ✓ Project: $PROJECT (${ENV})${NC}"
fi

# 4. Check required variables resolve
echo ""
echo "4. Checking required services (via variable resolution)..."

VARS_OUTPUT=$(railway variables 2>/dev/null || true)

check_var() {
    local name=$1
    local pattern=$2
    local msg=$3
    if echo "$VARS_OUTPUT" | grep -q "^${name}="; then
        local val=$(echo "$VARS_OUTPUT" | grep "^${name}=" | cut -d= -f2- | head -1)
        if echo "$val" | grep -qE "$pattern"; then
            echo -e "${GREEN}   ✓ $name resolves${NC}"
            return 0
        elif echo "$val" | grep -q '\${{'; then
            echo -e "${RED}   ✗ $name unresolved: $val${NC}"
            echo "     $msg"
            ((ERRORS++))
            return 1
        else
            echo -e "${GREEN}   ✓ $name set${NC}"
            return 0
        fi
    else
        echo -e "${RED}   ✗ $name not found${NC}"
        echo "     $msg"
        ((ERRORS++))
        return 1
    fi
}

# DATABASE_URL - railway.toml uses Postgis or Postgres
if echo "$VARS_OUTPUT" | grep -qE "DATABASE_URL|postgresql://" && echo "$VARS_OUTPUT" | grep -q "railway\.internal"; then
    echo -e "${GREEN}   ✓ DATABASE_URL resolves (Postgres/Postgis connected)${NC}"
elif echo "$VARS_OUTPUT" | grep -q '\${{.*Postgres'; then
    echo -e "${RED}   ✗ DATABASE_URL unresolved - PostgreSQL service missing or wrong name${NC}"
    echo "     Add: Database → PostgreSQL/Postgis, or override DATABASE_URL in dashboard"
    ((ERRORS++))
elif ! echo "$VARS_OUTPUT" | grep -q "DATABASE_URL"; then
    echo -e "${RED}   ✗ DATABASE_URL not found${NC}"
    ((ERRORS++))
else
    echo -e "${YELLOW}   ⚠ DATABASE_URL: check manually${NC}"
    ((WARNINGS++))
fi

# REDIS_URL
if echo "$VARS_OUTPUT" | grep -q "REDIS_URL" && echo "$VARS_OUTPUT" | grep -q "redis"; then
    echo -e "${GREEN}   ✓ REDIS_URL resolves (Redis connected)${NC}"
elif ! echo "$VARS_OUTPUT" | grep -q "REDIS_URL"; then
    echo -e "${RED}   ✗ REDIS_URL not found - add Redis service${NC}"
    ((ERRORS++))
else
    echo -e "${YELLOW}   ⚠ REDIS_URL: check manually${NC}"
    ((WARNINGS++))
fi

# TEMPORAL_ADDRESS
if echo "$VARS_OUTPUT" | grep -q "TEMPORAL_ADDRESS" && echo "$VARS_OUTPUT" | grep -q "7233"; then
    echo -e "${GREEN}   ✓ TEMPORAL_ADDRESS set (Temporal service)${NC}"
elif ! echo "$VARS_OUTPUT" | grep -q "TEMPORAL_ADDRESS"; then
    echo -e "${YELLOW}   ⚠ TEMPORAL_ADDRESS not set - deploy Temporal Light template first${NC}"
    echo "     Without Temporal: signup/auth may work, scheduling will fail"
    ((WARNINGS++))
else
    echo -e "${GREEN}   ✓ TEMPORAL_ADDRESS set${NC}"
fi

# PORT
if echo "$VARS_OUTPUT" | grep -q "PORT" && echo "$VARS_OUTPUT" | grep -q "5000"; then
    echo -e "${GREEN}   ✓ PORT=5000 (nginx routing)${NC}"
elif echo "$VARS_OUTPUT" | grep "PORT" | grep -q "3000"; then
    echo -e "${RED}   ✗ PORT=3000 will fail healthcheck - set PORT=5000 in Railway${NC}"
    ((ERRORS++))
fi

# JWT_SECRET (Railway table format: JWT_SECRET | value)
if echo "$VARS_OUTPUT" | grep -q "JWT_SECRET"; then
    echo -e "${GREEN}   ✓ JWT_SECRET set${NC}"
else
    echo -e "${RED}   ✗ JWT_SECRET missing (need 16+ chars)${NC}"
    echo "     Set in Railway Dashboard → Variables"
    ((ERRORS++))
fi

# 5. Check railway.toml exists
echo ""
echo "5. Checking repo config..."
if [ -f "railway.toml" ]; then
    echo -e "${GREEN}   ✓ railway.toml present${NC}"
else
    echo -e "${RED}   ✗ railway.toml missing${NC}"
    ((ERRORS++))
fi

if [ -f "Dockerfile" ]; then
    echo -e "${GREEN}   ✓ Dockerfile present${NC}"
else
    echo -e "${RED}   ✗ Dockerfile missing${NC}"
    ((ERRORS++))
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════════"
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}  ✗ Validation FAILED ($ERRORS errors)${NC}"
    echo "  Fix the errors above before deploying."
    echo "  See RAILWAY_NEW_PROJECT_DEPLOY.md for setup guide."
    exit 1
else
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}  ✓ Validation passed with $WARNINGS warning(s)${NC}"
        echo "  Review warnings - deploy may work but some features may be limited."
    else
        echo -e "${GREEN}  ✓ Validation PASSED${NC}"
    fi
    echo "  Ready to deploy: railway up"
    exit 0
fi
