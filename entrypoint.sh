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
# Set it to 3000 so backend doesn't conflict with nginx (which uses 5000)
export PORT=3000

echo "=== Railway Entrypoint Wrapper ==="
echo "Original Railway PORT: ${RAILWAY_ORIGINAL_PORT}"
echo "Setting PORT=3000 for backend"
echo "nginx will listen on 5000 (hardcoded in config)"
echo "TEMPORAL_ADDRESS: ${TEMPORAL_ADDRESS}"
echo "DATABASE_URL: ${DATABASE_URL:0:50}..."
echo "REDIS_URL: ${REDIS_URL:0:30}..."
echo "=================================="

# Create volume subdirectories if they don't exist
# Railway allows only one volume per service, so we use /data with subdirectories
if [ -d "/data" ]; then
    echo "Creating volume subdirectories..."
    mkdir -p /data/uploads /data/config
    echo "Volume structure ready: /data/{uploads,config}"
fi

# Execute the original entrypoint from the base image
# Base image uses: ENTRYPOINT ["docker-entrypoint.sh"] CMD ["sh","-c","nginx && pnpm run pm2"]
exec docker-entrypoint.sh "$@"
