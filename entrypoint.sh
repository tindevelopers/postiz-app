#!/bin/bash
# Wrapper entrypoint for Railway deployment
# 
# Problem: Railway sets PORT env var for healthcheck routing
# But Postiz backend reads PORT and uses it instead of its default 3000
# This causes a conflict since nginx is hardcoded to listen on 5000
#
# Solution: Unset PORT so backend uses default 3000, nginx stays on 5000
# Railway will connect to the EXPOSE'd port 5000

# Save PORT for logging/debugging if needed
export RAILWAY_ORIGINAL_PORT="${PORT:-}"

# Unset PORT so the backend uses its default (3000)
unset PORT

echo "=== Railway Entrypoint Wrapper ==="
echo "Original PORT: ${RAILWAY_ORIGINAL_PORT}"
echo "PORT unset - backend will use default 3000"
echo "nginx listening on 5000"
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
