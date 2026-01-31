# Railway deployment Dockerfile for Postiz (pinned version; update when upgrading)
FROM ghcr.io/gitroomhq/postiz-app:v2.12.1

# Create upload directory with proper permissions
RUN mkdir -p /uploads /config && chmod 755 /uploads /config

# Create a wrapper entrypoint that fixes the PORT conflict
# Railway sets PORT for healthcheck, but Postiz backend also reads PORT
# We need nginx on 5000 (default) and backend on 3000 (default)
COPY entrypoint.sh /entrypoint-wrapper.sh
RUN chmod +x /entrypoint-wrapper.sh

# Expose nginx port (5000)
EXPOSE 5000

# Use our wrapper entrypoint with the original CMD
ENTRYPOINT ["/entrypoint-wrapper.sh"]
CMD ["sh", "-c", "nginx && pnpm run pm2"]
