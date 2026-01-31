# Railway deployment Dockerfile for Postiz
FROM ghcr.io/gitroomhq/postiz-app:latest

# Create upload directory with proper permissions
RUN mkdir -p /uploads /config && chmod 755 /uploads /config

# The image already contains everything needed
# Railway will set environment variables automatically

# Expose the application port
EXPOSE 5000

# Use the default entrypoint from the base image
# Do NOT override CMD or ENTRYPOINT - let the base image handle startup
