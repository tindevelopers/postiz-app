FROM node:20-alpine3.19

# Set environment variables
ARG NEXT_PUBLIC_VERSION
ENV NEXT_PUBLIC_VERSION=$NEXT_PUBLIC_VERSION
ENV NODE_ENV=production

# Install system dependencies
RUN apk add --no-cache g++ make py3-pip bash nginx postgresql-client

# Create www user
RUN adduser -D -g 'www' www
RUN mkdir /www
RUN chown -R www:www /var/lib/nginx
RUN chown -R www:www /www

# Install pnpm and pm2 globally
RUN npm --no-update-notifier --no-fund --global install pnpm@10.6.1 pm2

WORKDIR /app

# Copy package files first for better caching
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/*/package.json ./apps/*/
COPY libraries/*/package.json ./libraries/*/

# Install dependencies (including dev dependencies for build)
# Skip postinstall scripts to avoid Prisma generation before source code is copied
RUN pnpm install --no-frozen-lockfile --ignore-scripts

# Copy source code
COPY . .

# Copy nginx configuration
COPY var/docker/nginx.conf /etc/nginx/nginx.conf

# Generate Prisma client first
RUN pnpm run prisma-generate

# Build the application
RUN NODE_OPTIONS="--max-old-space-size=4096" pnpm run build

# Prune dev dependencies to reduce image size
RUN pnpm prune --prod

# Create uploads and logs directories
RUN mkdir -p /uploads /app/logs && chown -R www:www /uploads /app/logs

# Make startup script executable
RUN chmod +x /app/railway-start.sh

# Expose port 5000 (Railway will map this)
EXPOSE 5000

# Start the application
CMD ["/app/railway-start.sh"]
