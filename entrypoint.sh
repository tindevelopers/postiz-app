#!/bin/bash
# Wrapper entrypoint for Railway deployment
# 
# Problem: Railway sets PORT env var for healthcheck routing
# But Postiz backend reads PORT and uses it instead of its default 3000
# This causes a conflict since nginx is hardcoded to listen on 5000
#
# Solution: Explicitly set PORT=3000 for backend before starting processes
# nginx ignores PORT and uses its hardcoded config (port 5000)
# Railway will connect to the EXPOSE'd port 5000

# Save Railway's PORT for logging
export RAILWAY_ORIGINAL_PORT="${PORT:-}"

# CRITICAL: Backend reads PORT env var to determine which port to listen on
# Railway sets PORT=5000 for healthcheck routing to nginx
# We need backend on 3000 and nginx on 5000
# Unset PORT first to force backend to use its default, then set it explicitly
unset PORT
export PORT=3000
export BACKEND_PORT=3000

echo "=== Railway Entrypoint Wrapper ==="
echo "Original Railway PORT: ${RAILWAY_ORIGINAL_PORT}"
echo "Setting PORT=3000 and BACKEND_PORT=3000 for backend"
echo "nginx will listen on 5000 (hardcoded in config)"
echo "=================================="

# Verify PORT is set correctly
echo "Verification - PORT=$PORT, BACKEND_PORT=$BACKEND_PORT"

# #region agent log
# DEBUG MODE: Comprehensive logging for auth middleware failure
DEBUG_LOG="/app/.cursor/debug.log"
mkdir -p /app/.cursor
LOG_SERVER="http://127.0.0.1:7242/ingest/e9867de5-4628-4dfc-9005-75f91c38e768"

log_debug() {
    local hypothesis="$1"
    local message="$2"
    local data="$3"
    local timestamp=$(date +%s%3N)
    echo "{\"timestamp\":$timestamp,\"location\":\"entrypoint.sh\",\"hypothesisId\":\"$hypothesis\",\"message\":\"$message\",\"data\":$data,\"sessionId\":\"debug-session\"}" >> "$DEBUG_LOG"
}

echo "=== DEBUG: Testing Hypotheses ==="

# H1: Test Redis connectivity
echo "[H1] Testing Redis connection..."
if command -v redis-cli >/dev/null 2>&1; then
    REDIS_TEST=$(redis-cli -u "${REDIS_URL}" ping 2>&1 || echo "FAILED")
    log_debug "H1" "Redis connectivity test" "{\"redis_url\":\"${REDIS_URL:0:30}...\",\"test_result\":\"$REDIS_TEST\"}"
    echo "  Redis test: $REDIS_TEST"
else
    log_debug "H1" "Redis CLI not available" "{\"status\":\"redis-cli_missing\"}"
    echo "  redis-cli not available, skipping connectivity test"
fi

# H2: Check all auth-related environment variables
echo "[H2] Checking auth environment variables..."
log_debug "H2" "Auth env vars" "{\"JWT_SECRET_SET\":\"$([ -n \"$JWT_SECRET\" ] && echo true || echo false)\",\"DATABASE_URL_SET\":\"$([ -n \"$DATABASE_URL\" ] && echo true || echo false)\",\"REDIS_URL_SET\":\"$([ -n \"$REDIS_URL\" ] && echo true || echo false)\",\"FRONTEND_URL\":\"$FRONTEND_URL\",\"MAIN_URL\":\"$MAIN_URL\",\"NEXT_PUBLIC_BACKEND_URL\":\"$NEXT_PUBLIC_BACKEND_URL\",\"BACKEND_INTERNAL_URL\":\"$BACKEND_INTERNAL_URL\",\"IS_GENERAL\":\"$IS_GENERAL\"}"
echo "  JWT_SECRET: $([ -n \"$JWT_SECRET\" ] && echo 'SET' || echo 'MISSING')"
echo "  DATABASE_URL: $([ -n \"$DATABASE_URL\" ] && echo 'SET' || echo 'MISSING')"
echo "  REDIS_URL: $([ -n \"$REDIS_URL\" ] && echo 'SET' || echo 'MISSING')"
echo "  FRONTEND_URL: $FRONTEND_URL"
echo "  MAIN_URL: $MAIN_URL"
echo "  BACKEND_INTERNAL_URL: $BACKEND_INTERNAL_URL"

# H3: Test PostgreSQL connectivity
echo "[H3] Testing PostgreSQL connection..."
if command -v psql >/dev/null 2>&1; then
    PG_TEST=$(psql "${DATABASE_URL}" -c "SELECT 1;" 2>&1 || echo "FAILED")
    log_debug "H3" "PostgreSQL connectivity test" "{\"database_url\":\"${DATABASE_URL:0:50}...\",\"test_result\":\"${PG_TEST:0:100}\"}"
    echo "  PostgreSQL test: ${PG_TEST:0:100}"
else
    log_debug "H3" "PostgreSQL client not available" "{\"status\":\"psql_missing\"}"
    echo "  psql not available, skipping connectivity test"
fi

# H4: Check cookie patch was applied
echo "[H4] Verifying cookie domain patch..."
PATCH_FILE=$(find /app -name "subdomain.management.js" -type f 2>/dev/null | head -1)
if [ -n "$PATCH_FILE" ]; then
    PATCH_CHECK=$(grep -c "url\.hostname!" "$PATCH_FILE" 2>/dev/null || echo "0")
    log_debug "H4" "Cookie patch verification" "{\"file\":\"$PATCH_FILE\",\"hostname_count\":$PATCH_CHECK}"
    echo "  Patch file: $PATCH_FILE"
    echo "  Hostname references: $PATCH_CHECK"
else
    log_debug "H4" "Cookie patch file not found" "{\"status\":\"file_missing\"}"
    echo "  subdomain.management.js not found"
fi

# H5: Check if required tables exist in database
echo "[H5] Checking database schema..."
if command -v psql >/dev/null 2>&1; then
    TABLES_CHECK=$(psql "${DATABASE_URL}" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>&1 || echo "0")
    log_debug "H5" "Database schema check" "{\"table_count\":\"$TABLES_CHECK\"}"
    echo "  Public tables count: $TABLES_CHECK"
else
    echo "  Skipping schema check (psql unavailable)"
fi

echo "=== DEBUG: Hypothesis testing complete ==="
echo "Debug log: $DEBUG_LOG"
# #endregion

# Create volume subdirectories if they don't exist
# Railway allows only one volume per service, so we use /data with subdirectories
if [ -d "/data" ]; then
    echo "Creating volume subdirectories..."
    mkdir -p /data/uploads /data/config
    echo "Volume structure ready: /data/{uploads,config}"
fi

# #region agent log
# Start background monitor for backend errors
(
    echo "[DEBUG] Starting backend error monitor..."
    # Wait for PM2 to start
    sleep 15
    
    # Monitor backend error log
    if [ -f "/root/.pm2/logs/backend-error.log" ]; then
        tail -f /root/.pm2/logs/backend-error.log 2>/dev/null | while read line; do
            if echo "$line" | grep -iE "error|getUser|Cannot read|undefined"; then
                timestamp=$(date +%s%3N)
                escaped_line=$(echo "$line" | sed 's/"/\\"/g' | tr -d '\n' | head -c 500)
                echo "{\"timestamp\":$timestamp,\"location\":\"backend-error.log\",\"hypothesisId\":\"RUNTIME\",\"message\":\"Backend error detected\",\"data\":{\"error\":\"$escaped_line\"},\"sessionId\":\"debug-session\"}" >> "$DEBUG_LOG"
            fi
        done &
    fi
) &
# #endregion

# Execute the original entrypoint from the base image
# Base image uses: ENTRYPOINT ["docker-entrypoint.sh"] CMD ["sh","-c","nginx && pnpm run pm2"]
# Use env to explicitly pass PORT=3000 to override Railway's PORT=5000
exec env PORT=3000 BACKEND_PORT=3000 docker-entrypoint.sh "$@"
